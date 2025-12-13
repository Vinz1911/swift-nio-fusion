//
//  FusionResultProtocol.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 13.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

// MARK: - Fusion Result Protocol -

protocol FusionResultProtocol: Sendable {
    var message: FusionMessage { get }
    var outbound: NIOAsyncChannelOutboundWriter<ByteBuffer> { get }
    
    /// The `FusionResult`
    ///
    /// - Parameters:
    ///   - message: the `FusionMessage`
    ///   - outbound: the `NIOAsyncChannelOutboundWriter`
    init(message: FusionMessage, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>)
}

// MARK: - Fusion Endpoint Protocol -

protocol FusionEndpointProtocol: Sendable {
    var host: String { get }
    var port: UInt16 { get }
    
    /// Create an Endpoint
    ///
    /// - Parameters:
    ///   - host: the host as `String`
    ///   - port: the port as `UInt16`
    init(host: String, port: UInt16)
}
