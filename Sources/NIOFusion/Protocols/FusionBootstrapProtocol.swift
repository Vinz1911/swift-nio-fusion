//
//  FusionBootstrapProtocol.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 15.11.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Foundation
import NIOCore
import NIOPosix

public protocol FusionBootstrapProtocol: Sendable {
    /// Create instance of `FusionBootstrap`
    ///
    /// - Parameters:
    ///   - endpoint: the `FusionEndpoint` to bind to
    ///   - threads: the thread count for the `MultiThreadedEventLoopGroup`
    ///   - parameters: the configurable `FusionParameters`
    init(from endpoint: FusionEndpoint, threads: Int, parameters: FusionParameters)
    
    /// Starts the `FusionBootstrap` and binds the server to port and address
    ///
    /// Invokes the individual channel listener
    func bind() async throws -> Void
    
    /// Send data on the current channel
    ///
    /// - Parameters:
    ///   - id: the channel specific `UUID`
    ///   - message: the `FusionMessage` to send
    func send(id: UUID, message: FusionMessage) async throws -> Void
    
    /// Receive `FusionResult` from stream
    ///
    /// An continues `AsyncStream` returns `FusionResult`
    func receive() -> AsyncStream<FusionResult>
}
