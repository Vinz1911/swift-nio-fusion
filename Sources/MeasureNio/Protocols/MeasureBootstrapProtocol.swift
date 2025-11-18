//
//  MeasureBootstrapProtocol.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 15.11.25.
//

import NIOCore
import NIOPosix

internal protocol MeasureBootstrapProtocol: Sendable {
    /// Create instance of `MeasureBootstrap`
    ///
    /// - Parameters:
    ///   - host: the host address as `String`
    ///   - port: the port number as `UInt16`
    ///   - group: the event group as `MultiThreadedEventLoopGroup`
    init(host: String, port: Int, group: MultiThreadedEventLoopGroup) throws
    
    /// Starts the `MeasureBootstrap` and binds the server to port and address
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
