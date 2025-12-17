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

public struct FusionBootstrap: FusionBootstrapProtocol, Sendable {
    private let endpoint: FusionEndpoint
    private let tracker = FusionTracker()
    private let parameters: FusionParameters
    private let threads: Int
    private var (stream, continuation) = AsyncStream.makeStream(of: FusionResult.self)
    
    /// Create instance of `FusionBootstrap`
    ///
    /// - Parameters:
    ///   - endpoint: the `FusionEndpoint` to bind to
    ///   - threads: the thread count for the `MultiThreadedEventLoopGroup`
    ///   - parameters: the configurable `FusionParameters`
    public init(from endpoint: FusionEndpoint, threads: Int = System.coreCount, parameters: FusionParameters = .init()) {
        self.endpoint = endpoint
        self.threads = threads
        self.parameters = parameters
    }
    
    /// Starts the `FusionBootstrap` and binds the server to port and address
    ///
    /// Invokes the individual channel listner
    public func run() async throws -> Void {
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        let group = MultiThreadedEventLoopGroup(numberOfThreads: threads)
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .serverChannelOption(.backlog, value: Int32(parameters.backlog))
            .childChannelOption(.socketOption(.tcp_nodelay), value: ChannelOptions.Types.SocketOption.Value(parameters.nodelay ? 1 : 0))
            .childChannelOption(.maxMessagesPerRead, value: UInt(parameters.messages))
        
        let channel = try await binding(from: bootstrap)
        try await listening(from: channel)
    }
    
    /// Send data on specific channel
    ///
    /// - Parameters:
    ///   - message: the `FusionMessage` to send
    ///   - outbound: the outbound channel `NIOAsyncChannelOutboundWriter`
    public func send(_ message: FusionMessage, _ outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void {
        do {
            guard let message = message as? FusionFrame else { return }
            let frame = try FusionFramer.create(message: message)
            try await outbound.write(frame)
        } catch { Logger.shared.ioerror(from: error) }
    }
    
    /// Receive `FusionResult` from stream
    ///
    /// An continues `AsyncStream` returns `FusionResult`
    public func receive() -> AsyncStream<FusionResult> {
        return stream
    }
    
    /// Show info
    ///
    /// Print logo and usefull information
    public func info() -> Void {
        Logger.shared.notice(.init(stringLiteral: .logo))
        Logger.shared.info("Number of Threads: \(threads)")
        Logger.shared.info("Listening on \(endpoint.host):\(endpoint.port)")
    }
}

// MARK: - Private API Extension -

private extension FusionBootstrap {
    /// Create a binding and return the `NIOAsyncChannel`
    ///
    /// - Parameter bootstrap: the `ServerBootstrap`
    /// - Returns: the created `NIOAsyncChannel`
    private func binding(from bootstrap: ServerBootstrap) async throws -> NIOAsyncChannel<NIOAsyncChannel<ByteBuffer, ByteBuffer>, Never> {
        return try await bootstrap.bind(host: self.endpoint.host, port: Int(self.endpoint.port)) { channel in
            channel.eventLoop.makeCompletedFuture {
                if let timeout = parameters.timeout {
                    let timer = channel.eventLoop.scheduleTask(in: .seconds(Int64(timeout))) { channel.close(promise: nil) }
                    channel.closeFuture.whenComplete { _ in timer.cancel() }
                }
                return try NIOAsyncChannel(wrappingChannelSynchronously: channel, configuration: NIOAsyncChannel.Configuration(inboundType: ByteBuffer.self, outboundType: ByteBuffer.self))
            }
        }
    }
    
    /// Start listening for incoming `NIOAsyncChannel`s
    ///
    /// - Parameter channel: the `NIOAsyncChannel`
    private func listening(from channel: NIOAsyncChannel<NIOAsyncChannel<ByteBuffer, ByteBuffer>, Never>) async throws -> Void {
        try await withThrowingDiscardingTaskGroup { group in
            try await channel.executeThenClose { inbound in
                for try await channel in inbound {
                    if parameters.logging { await tracker.fetch(from: channel.channel) }
                    group.addTask { do { try await append(channel: channel) } catch { Logger.shared.ioerror(from: error) } }
                }
            }
        }
    }
    
    /// Add handler for each individual channel
    ///
    /// - Parameters:
    ///   - channel: the `NIOAsyncChannel`
    ///   - completion: the parsed `FusionMessage` and `NIOAsyncChannelOutboundWriter`
    private func append(channel: NIOAsyncChannel<ByteBuffer, ByteBuffer>) async throws -> Void {
        let framer = FusionFramer()
        try await channel.executeThenClose { inbound, outbound in
            for try await buffer in inbound {
                guard channel.channel.isActive else { break }
                let messages = try await framer.parse(slice: buffer, size: parameters.size)
                for message in messages { continuation.yield(.init(message: message, outbound: outbound)) }
            }
        }
        await framer.clear()
    }
}
