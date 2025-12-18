//
//  FusionParameters.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 15.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

public struct FusionParameters: FusionParametersProtocol, Sendable {
    public let timeout: UInt16?
    public let backlog: UInt16
    public let nodelay: Bool
    public let messages: UInt16
    public let ceiling: FusionCeiling
    
    /// Configurable `FusionParameters` for `FusionBootstrap`
    ///
    /// - Parameters:
    ///   - timeout: timeout after a connection will be kicked
    ///   - backlog: maximum allowed connections
    ///   - nodelay: enable tcp nagle's algorithmus
    ///   - messages: maximum messages per read
    ///   - ceiling: the `FusionCeiling` to limit frame size
    public init(timeout: UInt16? = nil, backlog: UInt16 = 256, nodelay: Bool = true, messages: UInt16 = 32, ceiling: FusionCeiling = .medium) {
        self.timeout = timeout
        self.backlog = backlog
        self.nodelay = nodelay
        self.messages = messages
        self.ceiling = ceiling
    }
}
