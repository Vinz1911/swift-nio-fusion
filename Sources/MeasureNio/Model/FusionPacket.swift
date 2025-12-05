//
//  FusionPacket.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 17.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

// MARK: - Message Flow Control -

/// The `FusionPacket` for protocol constants
enum FusionPacket: Int, Sendable {
    case opcode = 0x1
    case header = 0x5
    case frame  = 0xFFFFFFFF
}

/// The `FusionOpcode` for the type classification
enum FusionOpcode: UInt8, Sendable {
    case string = 0x1
    case data   = 0x2
    case uint16 = 0x3
}
