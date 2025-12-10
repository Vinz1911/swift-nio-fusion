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
    ///   - host: the host address as `String`
    ///   - port: the port number as `UInt16`
    ///   - group: the event group as `MultiThreadedEventLoopGroup`
    init(host: String, port: UInt16, group: MultiThreadedEventLoopGroup) throws
    
    /// Starts the `FusionBootstrap` and binds the server to port and address
    ///
    /// - Parameter completion: completion block with parsed `FusionMessage` and the outbound writer
    func run(_ completion: @escaping @Sendable (FusionMessage, NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void) async throws
    
    /// Send data on specific channel
    ///
    /// - Parameters:
    ///   - message: the `FusionMessage` to send
    ///   - outbound: the outbound channel `NIOAsyncChannelOutboundWriter`
    func send(_ message: FusionMessage, _ outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async
}
