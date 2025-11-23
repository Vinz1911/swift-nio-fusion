//
//  MeasureBootstrap.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 13.04.25.
//

import NIOCore
import NIOPosix
import Logging

internal struct MeasureBootstrap: MeasureBootstrapProtocol, Sendable {
    private let host: String
    private let port: Int
    private let group: MultiThreadedEventLoopGroup
    private let tracker = MeasureTracker()
    
    /// Create instance of `MeasureBootstrap`
    ///
    /// - Parameters:
    ///   - host: the host address as `String`
    ///   - port: the port number as `UInt16`
    ///   - group: the event group as `MultiThreadedEventLoopGroup`
    internal init(host: String, port: Int, group: MultiThreadedEventLoopGroup) throws {
        if host.isEmpty { throw(MeasureBootstrapError.invalidHostName) }; if port == .zero { throw(MeasureBootstrapError.invalidPortNumber) }
        self.host = host; self.port = port; self.group = group
    }
    
    /// Starts the `MeasureBootstrap` and binds the server to port and address
    ///
    /// - Parameter completion: completion block with parsed `FusionMessage` and the outbound writer
    internal func run(_ completion: @escaping @Sendable (FusionMessage, NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void) async throws {
        let bootstrap = ServerBootstrap(group: self.group)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: .one)
            .serverChannelOption(.backlog, value: .backlogMax)
            .childChannelOption(.socketOption(.tcp_nodelay), value: .one)
            .childChannelOption(.maxMessagesPerRead, value: .messageMax)
        
        let channel = try await bootstrap.bind(host: self.host, port: self.port) { channel in
            channel.eventLoop.makeCompletedFuture {
                let timer = channel.eventLoop.scheduleTask(in: .seconds(.timeout)) { channel.close(promise: nil) }
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
                        await addChannel(channel: channel) { await completion($0, $1) }
                    }
                }
            }
        }
    }
    
    /// Send data on specific channel
    ///
    /// - Parameters:
    ///   - message: the `FusionMessage` to send
    ///   - outbound: the outbound channel `NIOAsyncChannelOutboundWriter`
    internal func send(_ message: FusionMessage, _ outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async {
        do {
            let frame = try await FusionFramer.create(message: message)
            try await outbound.write(frame)
        } catch {
            guard let error = error as? IOError else { return }
            guard error.errnoCode != ECONNRESET, error.errnoCode != EPIPE, error.errnoCode != EBADF else { return }
            Logger.shared.error("\(error)")
        }
    }
}

// MARK: - Private API -

private extension MeasureBootstrap {
    /// Add handler for each individual channel
    ///
    /// - Parameters:
    ///   - channel: the `NIOAsyncChannel`
    ///   - completion: the parsed `FusionMessage` and `NIOAsyncChannelOutboundWriter`
    private func addChannel(channel: NIOAsyncChannel<ByteBuffer, ByteBuffer>, completion: @escaping @Sendable (FusionMessage, NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void) async {
        do {
            let framer = FusionFramer()
            defer { Task { await framer.reset() } }
            try await channel.executeThenClose { inbound, outbound in
                for try await buffer in inbound {
                    var mutable = buffer; let messages = try await framer.parse(data: &mutable)
                    for message in messages { await completion(message, outbound) }
                }
            }
            channel.channel.flush()
        } catch {
            guard let error = error as? IOError else { return }
            guard error.errnoCode != ECONNRESET, error.errnoCode != EPIPE, error.errnoCode != EBADF else { return }
            Logger.shared.error("\(error)")
        }
    }
}
