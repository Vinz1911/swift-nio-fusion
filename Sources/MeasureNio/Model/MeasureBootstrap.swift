//
//  MeasureBootstrap.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 13.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import NIOPosix
import Logging

struct MeasureBootstrap: MeasureBootstrapProtocol {
    private let host: String
    private let port: UInt16
    private let group: MultiThreadedEventLoopGroup
    private let tracker = MeasureTracker()
    
    /// Create instance of `MeasureBootstrap`
    ///
    /// - Parameters:
    ///   - host: the host address as `String`
    ///   - port: the port number as `UInt16`
    ///   - group: the event group as `MultiThreadedEventLoopGroup`
    init(host: String, port: UInt16, group: MultiThreadedEventLoopGroup) throws {
        if host.isEmpty { throw(MeasureBootstrapError.invalidHostName) }; if port == .zero { throw(MeasureBootstrapError.invalidPortNumber) }
        self.host = host; self.port = port; self.group = group
    }
    
    /// Starts the `MeasureBootstrap` and binds the server to port and address
    ///
    /// - Parameter completion: completion block with parsed `FusionMessage` and the outbound writer
    func run(_ completion: @escaping @Sendable (FusionMessage, NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void) async throws {
        let bootstrap = ServerBootstrap(group: self.group)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .serverChannelOption(.backlog, value: .backlogMax)
            .childChannelOption(.socketOption(.tcp_nodelay), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: .messageMax)
        
        let channel = try await bootstrap.bind(host: self.host, port: Int(self.port)) { channel in
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
    func send(_ message: FusionMessage, _ outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async {
        do {
            guard let message = message as? FusionFrame else { return }
            let frame = try FusionFramer.create(message: message)
            try await outbound.write(frame)
        } catch { log(from: error) }
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
        let framer = FusionFramer()
        defer { Task { await framer.clear() } }
        do {
            try await channel.executeThenClose { inbound, outbound in
                for try await buffer in inbound {
                    let messages = try await framer.parse(data: buffer)
                    for message in messages { await completion(message, outbound) }
                }
            }
        } catch { log(from: error) }
    }
    
    /// Log channel `IOError`
    ///
    /// - Parameter error: the `Error`
    private func log(from error: Error) {
        guard let error = error as? IOError else { return }
        guard error.errnoCode != ECONNRESET, error.errnoCode != EPIPE, error.errnoCode != EBADF else { return }
        Logger.shared.error("\(error)")
    }
}
