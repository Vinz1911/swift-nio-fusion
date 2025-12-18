//
//  FusionRegistry.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 18.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Foundation
import NIOCore

actor FusionRegistry: Sendable {
    var storage: [UUID: NIOAsyncChannelOutboundWriter<ByteBuffer>] = [:]
    
    /// Append a `NIOAsyncChannelOutboundWriter`
    ///
    /// - Parameters:
    ///   - id: the channel `UUID`
    ///   - outbound: the channel `NIOAsyncChannelOutboundWriter`
    func append(id: UUID, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void {
        storage[id] = outbound
    }
    
    /// Fetch a `NIOAsyncChannelOutboundWriter`
    ///
    /// - Parameter id: the channel `UUID`
    /// - Returns: the channel `NIOAsyncChannelOutboundWriter`
    func fetch(from id: UUID) async -> NIOAsyncChannelOutboundWriter<ByteBuffer>? {
        return storage[id]
    }
    
    /// Remove a `NIOAsyncChannelOutboundWriter`
    ///
    /// - Parameter id: the channel `UUID`
    func remove(id: UUID) async -> Void {
        storage.removeValue(forKey: id)
    }
}
