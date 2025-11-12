//
//  NMOpcodes.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 17.04.25.
//

import Foundation

/// The `NMOpcodes` for the frame header
internal enum NMOpcodes: UInt8, Sendable {
    case none = 0x0
    case text = 0x1
    case binary = 0x2
    case ping = 0x3
}

/// The `NMConstants` for protocol limits
internal enum NMConstants: Int, Sendable {
    case opcode = 0x1
    case control = 0x5
    case frame = 0xFFFFFFFF
}
