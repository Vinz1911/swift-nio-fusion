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
    
    private let outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>
    private let ceiling: FusionCeiling
    
    /// The `FusionResult`
    ///
    /// - Parameters:
    ///   - id: the uuid to identify `any Channel`
    ///   - message: the `FusionMessage`
    ///   - local: the local `SocketAddress`
    ///   - remote: the remote `SocketAddress`
    ///   - ceiling: the `FusionCeiling` to limit frame size
    ///   - outbound: the `NIOAsyncChannelOutboundWriter`
    init(id: UUID, message: FusionMessage, local: SocketAddress?, remote: SocketAddress?, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>, ceiling: FusionCeiling) {
        self.id = id
        self.message = message
        self.outbound = outbound
        self.ceiling = ceiling
        self.local = local
        self.remote = remote
    }
    
    /// Send data on the current channel
    ///
    /// - Parameters:
    ///   - message: the `FusionMessage` to send
    public func send(_ message: FusionMessage) async throws -> Void {
        guard let message = message as? FusionFrame else { return }
        let frame = try FusionFramer.create(message: message, ceiling: ceiling)
        try await outbound.write(frame)
    }
}
