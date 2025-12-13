//
//  FusionResult.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 12.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

// MARK: - Fusion Result -

struct FusionResult: FusionResultProtocol, Sendable {
    var message: FusionMessage
    var outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>
    
    /// The `FusionResult`
    ///
    /// - Parameters:
    ///   - message: the `FusionMessage`
    ///   - outbound: the `NIOAsyncChannelOutboundWriter`
    init(message: FusionMessage, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) {
        self.message = message
        self.outbound = outbound
    }
}

// MARK: - Fusion Endpoint -

struct FusionEndpoint: FusionEndpointProtocol, Sendable {
    let host: String
    let port: UInt16
    
    /// Create an Endpoint
    ///
    /// - Parameters:
    ///   - host: the host as `String`
    ///   - port: the port as `UInt16`
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
}
