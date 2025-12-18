//
//  FusionBootstrap.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 13.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import NIOPosix
import Foundation

public struct FusionBootstrap: FusionBootstrapProtocol, Sendable {
    private let endpoint: FusionEndpoint
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
        let group = MultiThreadedEventLoopGroup(numberOfThreads: threads)
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .serverChannelOption(.backlog, value: Int32(parameters.backlog))
            .childChannelOption(.socketOption(.tcp_nodelay), value: ChannelOptions.Types.SocketOption.Value(parameters.nodelay ? 1 : 0))
            .childChannelOption(.maxMessagesPerRead, value: UInt(parameters.messages))
        
        try await binding(from: bootstrap)
    }
    
    /// Receive `FusionResult` from stream
    ///
    /// An continues `AsyncStream` returns `FusionResult`
    public func receive() -> AsyncStream<FusionResult> {
        return stream
    }
}

// MARK: - Private API Extension -

private extension FusionBootstrap {
    /// Create a binding and start listening for any `Channel`
    ///
    /// - Parameter bootstrap: the `ServerBootstrap`
    private func binding(from bootstrap: ServerBootstrap) async throws -> Void {
        let channel = try await bootstrap.bind(host: self.endpoint.host, port: Int(self.endpoint.port)) { channel in
            channel.eventLoop.makeCompletedFuture {
                if let timeout = parameters.timeout {
                    let timer = channel.eventLoop.scheduleTask(in: .seconds(Int64(timeout))) { channel.close(promise: nil) }
                    channel.closeFuture.whenComplete { _ in timer.cancel() }
                }
                return try NIOAsyncChannel(wrappingChannelSynchronously: channel, configuration: .init(inboundType: ByteBuffer.self, outboundType: ByteBuffer.self))
            }
        }
        try await withThrowingDiscardingTaskGroup { group in
            try await channel.executeThenClose { inbound in for try await channel in inbound { group.addTask { try? await append(channel: channel) } } }
        }
    }
    
    /// Add handler for each individual channel
    ///
    /// - Parameters:
    ///   - channel: the `NIOAsyncChannel`
    ///   - completion: the parsed `FusionMessage` and `NIOAsyncChannelOutboundWriter`
    private func append(channel: NIOAsyncChannel<ByteBuffer, ByteBuffer>) async throws -> Void {
        let framer = FusionFramer(), id = UUID()
        let local = channel.channel.localAddress, remote = channel.channel.remoteAddress
        try await channel.executeThenClose { inbound, outbound in
            for try await buffer in inbound {
                guard channel.channel.isActive else { break }
                let messages = try await framer.parse(slice: buffer, ceiling: parameters.ceiling)
                for message in messages { continuation.yield(.init(id: id, message: message, local: local, remote: remote, outbound: outbound, ceiling: parameters.ceiling)) }
            }
        }
        await framer.clear()
    }
}
