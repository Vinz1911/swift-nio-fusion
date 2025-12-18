//
//  FusionParametersProtocol.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 15.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

public protocol FusionParametersProtocol: Sendable {
    /// Timeout after a connection will be kicked
    var timeout: UInt16? { get }
    
    /// The maximum allowed connections
    var backlog: UInt16 { get }
    
    /// Enable tcp nagle's algorithmus
    var nodelay: Bool { get }
    
    /// The maximum messages per read
    var messages: UInt16 { get }
    
    /// The `FusionCeiling` to limit frame size
    var ceiling: FusionCeiling { get }
    
    /// Configurable `FusionParameters` for `FusionBootstrap`
    ///
    /// - Parameters:
    ///   - timeout: timeout after a connection will be kicked
    ///   - backlog: maximum allowed connections
    ///   - nodelay: enable tcp nagle's algorithmus
    ///   - messages: maximum messages per read
    ///   - ceiling: the `FusionCeiling` to limit frame size
    init(timeout: UInt16?, backlog: UInt16, nodelay: Bool, messages: UInt16, ceiling: FusionCeiling)
}
