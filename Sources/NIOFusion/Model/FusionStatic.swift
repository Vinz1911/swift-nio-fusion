//
//  FusionStatic.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 17.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

// MARK: - Message Flow Control -

/// The `FusionStatic` for protocol constants
enum FusionStatic: Int, Sendable {
    case opcode = 0x1
    case header = 0x5
    case total  = 0xFFFFFFFF
}

/// The `FusionOpcode` for the type classification
enum FusionOpcode: UInt8, Sendable {
    case string = 0x1
    case data   = 0x2
    case uint16 = 0x3
    var type: any FusionFrame.Type { switch self { case .string: String.self case .data: ByteBuffer.self case .uint16: UInt16.self } }
}
