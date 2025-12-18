//
//  FusionEndpointProtocol.swift
//  swift-nio-fusion
//
//  Created by Vinzenz Weist on 18.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

public protocol FusionEndpointProtocol: Sendable {
    /// The host name
    var host: String { get }
    
    /// The port address
    var port: UInt16 { get }
}
