//
//  FusionBootstrap.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 13.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import NIOPosix
import Logging

struct FusionBootstrap: FusionBootstrapProtocol, Sendable {
    private let group: MultiThreadedEventLoopGroup
    private let endpoint: FusionEndpoint
    private let tracker = FusionTracker()
    private var (stream, continuation) = AsyncStream.makeStream(of: FusionResult.self)
    
    /// Create instance of `FusionBootstrap`
    ///
    /// - Parameters:
    ///   - endpoint: the `FusionEndpoint` to bind to
    ///   - group: the event group as `MultiThreadedEventLoopGroup`
    init(from endpoint: FusionEndpoint, group: MultiThreadedEventLoopGroup) {
        self.endpoint = endpoint
        self.group = group
    }
    
    /// Starts the `FusionBootstrap` and binds the server to port and address
    ///
    /// Invokes the individual channel listner
    func run() async throws -> Void {
        let bootstrap = ServerBootstrap(group: self.group)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .serverChannelOption(.backlog, value: .backlogMax)
            .childChannelOption(.socketOption(.tcp_nodelay), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: .messageMax)
        
        let channel = try await bootstrap.bind(host: self.endpoint.host, port: Int(self.endpoint.port)) { channel in
            channel.eventLoop.makeCompletedFuture {
                let timer = channel.eventLoop.scheduleTask(in: .seconds(.timeout)) { channel.close(promise: nil) }
                channel.closeFuture.whenComplete { _ in timer.cancel() }
                return try NIOAsyncChannel(wrappingChannelSynchronously: channel, configuration: NIOAsyncChannel.Configuration(inboundType: ByteBuffer.self, outboundType: ByteBuffer.self))
            }
        }
        
        try await listening(from: channel)
    }
    
    /// Receive `FusionResult` from stream
    ///
    /// An continues `AsyncStream` returns `FusionResult`
    func receive() -> AsyncStream<FusionResult> {
        return stream
    }
    
    /// Send data on specific channel
    ///
    /// - Parameters:
    ///   - message: the `FusionMessage` to send
    ///   - outbound: the outbound channel `NIOAsyncChannelOutboundWriter`
    func send(_ message: FusionMessage, _ outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void {
        do {
            guard let message = message as? FusionFrame else { return }
            let frame = try FusionFramer.create(message: message)
            try await outbound.write(frame)
        } catch { Logger.shared.outin(from: error) }
    }
}

// MARK: - Private API Extension -

private extension FusionBootstrap {
    /// Start listening for incoming `NIOAsyncChannel`s
    ///
    /// - Parameter channel: the `NIOAsyncChannel`
    private func listening(from channel: NIOAsyncChannel<NIOAsyncChannel<ByteBuffer, ByteBuffer>, Never>) async throws -> Void {
        try await withThrowingDiscardingTaskGroup { group in
            try await channel.executeThenClose { inbound in
                for try await channel in inbound {
                    await tracker(from: channel.channel)
                    group.addTask { do { try await addChannel(channel: channel) } catch { Logger.shared.outin(from: error) } }
                }
            }
        }
    }
    
    /// Add handler for each individual channel
    ///
    /// - Parameters:
    ///   - channel: the `NIOAsyncChannel`
    ///   - completion: the parsed `FusionMessage` and `NIOAsyncChannelOutboundWriter`
    private func addChannel(channel: NIOAsyncChannel<ByteBuffer, ByteBuffer>) async throws -> Void {
        let framer = FusionFramer()
        try await channel.executeThenClose { inbound, outbound in
            for try await buffer in inbound {
                guard channel.channel.isActive else { break }
                let messages = try await framer.parse(data: buffer)
                for message in messages { continuation.yield(.init(message: message, outbound: outbound)) }
            }
        }
        await framer.clear()
    }
    
    /// Track incoming IP Addresses
    ///
    /// - Parameter channel: from `any Channel`
    private func tracker(from channel: any Channel) async -> Void {
        guard let address = channel.remoteAddress, let ip = address.ipAddress else { return }
        if await tracker.log(ip) { Logger.shared.info("IP: \(ip), Port: \(address.port ?? -1)") }
    }
}
