//
//  NFKBootstrap.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 13.04.25.
//

import NIOCore
import NIOPosix
import Foundation

internal struct NFKBootstrap: Sendable {
    private let host: String
    private let port: Int
    private let group: MultiThreadedEventLoopGroup
    
    /// Create instance of `NFKBootstrap`
    ///
    /// - Parameters:
    ///   - host: the host address as `String`
    ///   - port: the port number as `UInt16`
    ///   - group: the event group as `MultiThreadedEventLoopGroup`
    internal init(host: String, port: Int, group: MultiThreadedEventLoopGroup) {
        self.host = host
        self.port = port
        self.group = group
    }
    
    /// Starts the bootstrap and binds the server to port and address.
    ///
    /// - Parameter completion: contains callback with parsed data and outbound writer.
    internal func run(_ completion: @escaping @Sendable (NFKMessage, NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void) async throws {
        let bootstrap = try await ServerBootstrap(group: self.group)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .bind(host: self.host, port: self.port) { channel in
                channel.eventLoop.makeCompletedFuture {
                    return try NIOAsyncChannel(
                        wrappingChannelSynchronously: channel,
                        configuration: NIOAsyncChannel.Configuration(inboundType: ByteBuffer.self, outboundType: ByteBuffer.self)
                    )
                }
            }
        
        print("[Server]: Started, listening on \(self.host):\(self.port)")
        try await withThrowingDiscardingTaskGroup { group in
            try await bootstrap.executeThenClose { inbound in
                for try await channel in inbound {
                    group.addTask {
                        await connection(channel: channel) { await completion($0, $1) }
                    }
                }
            }
        }
    }
    
    /// Send data on specific connection.
    ///
    /// - Parameters:
    ///   - message: the `NFKMessage` to send
    ///   - outbound: the specific `NIOAsyncChannelOutboundWriter`
    internal func send(_ message: NFKMessage, _ outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async {
        do {
            let frame = try await NFKFramer.create(message: message)
            try await outbound.write(.init(bytes: frame))
        } catch {
            print("Send error: \(error)")
        }
    }
}

// MARK: - Private API -

private extension NFKBootstrap {
    /// Connection handler for each individual connection.
    ///
    /// - Parameters:
    ///   - channel: the `NIOAsyncChannel`
    ///   - completion: the parsed `NFKMessage` and `NIOAsyncChannelOutboundWriter`
    private func connection(channel: NIOAsyncChannel<ByteBuffer, ByteBuffer>, completion: @escaping @Sendable (NFKMessage, NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void) async {
        do {
            let framer = NFKFramer()
            try await channel.executeThenClose { inbound, outbound in
                for try await buffer in inbound {
                    var data = buffer; guard let bytes = data.readDispatchData(length: data.readableBytes) else { return }
                    for message in try await framer.parse(data: bytes) { await completion(message, outbound) }
                }
            }
        } catch {
            print("Connection error: \(error)")
        }
    }
}
