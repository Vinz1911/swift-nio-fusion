//
//  NMBootstrap.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 13.04.25.
//

import NIOCore
import NIOPosix
import Foundation
import Logging

internal struct NMBootstrap: Sendable {
    private let host: String
    private let port: Int
    private let group: MultiThreadedEventLoopGroup
    private let tracker = NMTracker()
    
    /// Create instance of `NMBootstrap`
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
    internal func run(_ completion: @escaping @Sendable (NMMessage, NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void) async throws {
        let bootstrap = ServerBootstrap(group: self.group)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .serverChannelOption(.backlog, value: 256)
            .childChannelOption(.socketOption(.tcp_nodelay), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: 16)
            .childChannelOption(.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        let channel = try await bootstrap.bind(host: self.host, port: self.port) { channel in
            channel.eventLoop.makeCompletedFuture {
                let timer = channel.eventLoop.scheduleTask(in: .seconds(60)) { channel.close(promise: nil) }
                channel.closeFuture.whenComplete { _ in timer.cancel() }
                return try NIOAsyncChannel(
                    wrappingChannelSynchronously: channel,
                    configuration: NIOAsyncChannel.Configuration(inboundType: ByteBuffer.self, outboundType: ByteBuffer.self)
                )
            }
        }
        
        Logger.shared.info("Listening on \(self.host):\(self.port)")
        try await withThrowingDiscardingTaskGroup { group in
            try await channel.executeThenClose { inbound in
                for try await channel in inbound {
                    if let address = channel.channel.remoteAddress {
                        if await tracker.log(address.ipAddress ?? "0.0.0.0") {
                            Logger.shared.info("IP: \(address.ipAddress ?? "0.0.0.0"), Port: \(address.port ?? -1)")
                        }
                    }
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
    ///   - message: the `NMMessage` to send
    ///   - outbound: the specific `NIOAsyncChannelOutboundWriter`
    internal func send(_ message: NMMessage, _ outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async {
        do {
            let frame = try await NMFramer.create(message: message)
            try await outbound.write(.init(bytes: frame))
        } catch {
            Logger.shared.error("\(error)")
        }
    }
}

// MARK: - Private API -

private extension NMBootstrap {
    /// Connection handler for each individual connection.
    ///
    /// - Parameters:
    ///   - channel: the `NIOAsyncChannel`
    ///   - completion: the parsed `NMMessage` and `NIOAsyncChannelOutboundWriter`
    private func connection(channel: NIOAsyncChannel<ByteBuffer, ByteBuffer>, completion: @escaping @Sendable (NMMessage, NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void) async {
        do {
            let framer = NMFramer()
            defer { Task { await framer.reset() } }
            try await channel.executeThenClose { inbound, outbound in
                for try await buffer in inbound {
                    var data = buffer; guard let bytes = data.readDispatchData(length: data.readableBytes) else { return }
                    for message in try await framer.parse(data: bytes) { await completion(message, outbound) }
                }
            }
            channel.channel.flush()
        } catch {
            guard let error = error as? IOError else { return }
            if error.errnoCode != ECONNRESET, error.errnoCode != EPIPE, error.errnoCode != EBADF {
                Logger.shared.error("\(error)")
            }
        }
    }
}
