//
//  FusionBootstrapProtocol.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 15.11.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import NIOPosix

protocol FusionBootstrapProtocol: Sendable {
    /// Create instance of `FusionBootstrap`
    ///
    /// - Parameters:
    ///   - endpoint: the `FusionEndpoint` to bind to
    ///   - group: the event group as `MultiThreadedEventLoopGroup`
    init(from endpoint: FusionEndpoint, group: MultiThreadedEventLoopGroup)

    /// Starts the `FusionBootstrap` and binds the server to port and address
    ///
    /// Invokes the individual channel listner
    func run() async throws -> Void

    /// Receive `FusionResult` from stream
    ///
    /// An continues `AsyncStream` returns `FusionResult`
    func receive() -> AsyncStream<FusionResult>
    /// Send data on specific channel
    ///
    /// - Parameters:
    ///   - message: the `FusionMessage` to send
    ///   - outbound: the outbound channel `NIOAsyncChannelOutboundWriter`
    func send(_ message: FusionMessage, _ outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void
}
