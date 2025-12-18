//
//  FusionResult.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 12.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import Foundation

// MARK: - Fusion Result -

public struct FusionResult: FusionResultProtocol, Sendable {
    public let id: UUID
    public let message: FusionMessage
    public let local: SocketAddress?
    public let remote: SocketAddress?
    
    /// The `FusionResult`
    ///
    /// - Parameters:
    ///   - id: the uuid to identify `any Channel`
    ///   - message: the `FusionMessage`
    ///   - local: the local `SocketAddress`
    ///   - remote: the remote `SocketAddress`
    init(id: UUID, message: FusionMessage, local: SocketAddress?, remote: SocketAddress?) {
        self.id = id
        self.message = message
        self.local = local
        self.remote = remote
    }
}
