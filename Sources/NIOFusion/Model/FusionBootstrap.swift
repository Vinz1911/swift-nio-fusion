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
    private var registry = FusionRegistry()
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
    /// Invokes the individual channel listener
    public func bind() async throws -> Void {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: threads)
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .serverChannelOption(.backlog, value: Int32(parameters.backlog))
            .childChannelOption(.socketOption(.tcp_nodelay), value: ChannelOptions.Types.SocketOption.Value(parameters.nodelay ? 1 : 0))
            .childChannelOption(.maxMessagesPerRead, value: UInt(parameters.messages))
        
        try await binding(from: bootstrap)
    }
    
    /// Send data on the current channel
    ///
    /// - Parameters:
    ///   - id: the channel specific `UUID`
    ///   - message: the `FusionMessage` to send
    public func send(id: UUID, message: FusionMessage) async throws -> Void {
        guard let outbound = await registry.fetch(from: id), let message = message as? FusionFrame else { return }
        let frame = try FusionFramer.create(message: message, ceiling: parameters.ceiling); try await outbound.write(frame)
    }
    
    /// Receive `FusionResult` from stream
    ///
    /// - Returns: an continues `AsyncStream` containing `FusionResult`
    public func receive() -> AsyncStream<FusionResult> {
        return stream
    }
    
    /// Fetch current active channel `UUID`s
    ///
    /// - Returns: an array containing all `UUID`s
    public func fetch() async -> [UUID] {
        return await registry.fetch()
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
                channel.timeout(after: parameters.timeout)
                return try NIOAsyncChannel(wrappingChannelSynchronously: channel, configuration: .init(inboundType: ByteBuffer.self, outboundType: ByteBuffer.self))
            }
        }
        try await withThrowingDiscardingTaskGroup { group in try await channel.executeThenClose { for try await channel in $0 { group.addTask { try? await append(channel: channel) } } } }
    }
    
    /// Add handler for each individual channel
    ///
    /// - Parameters:
    ///   - channel: the `NIOAsyncChannel`
    private func append(channel: NIOAsyncChannel<ByteBuffer, ByteBuffer>) async throws -> Void {
        defer { Task { await registry.remove(id: id) } }
        let framer = FusionFramer(), id = UUID(), local = channel.channel.localAddress, remote = channel.channel.remoteAddress
        try await channel.executeThenClose { inbound, outbound in
            await registry.append(id: id, outbound: outbound)
            for try await buffer in inbound {
                guard channel.channel.isActive else { break }
                for message in try await framer.parse(slice: buffer, ceiling: parameters.ceiling) { continuation.yield(.init(id: id, message: message, local: local, remote: remote)) }
            }
        }
    }
}
