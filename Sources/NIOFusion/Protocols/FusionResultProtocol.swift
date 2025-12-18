//
//  FusionResultProtocol.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 13.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import Foundation

public protocol FusionResultProtocol: Sendable {
    /// The uuid to identify `any Channel`
    var id: UUID { get }
    
    /// The `FusionMessage`
    var message: FusionMessage { get }
    
    /// The local `SocketAddress`
    var local: SocketAddress? { get }
    
    /// The remote `SocketAddress`
    var remote: SocketAddress? { get }
    
    /// Send data on the current channel
    ///
    /// - Parameters:
    ///   - message: the `FusionMessage` to send
    func send(_ message: FusionMessage) async throws -> Void
}
