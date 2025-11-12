//
//  NMMessage.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 13.04.25.
//

import Foundation

/// Protocol for message compliance
public protocol NMMessage: Sendable {
    var opcode: UInt8 { get }
    var raw: Data { get }
}

/// Conformance to protocol 'NMMessage'
extension UInt16: NMMessage {
    public var opcode: UInt8 { NMOpcodes.ping.rawValue }
    public var raw: Data { Data(count: Int(self)) }
}

/// Conformance to protocol 'NMMessage'
extension String: NMMessage {
    public var opcode: UInt8 { NMOpcodes.text.rawValue }
    public var raw: Data { Data(self.utf8) }
}

/// Conformance to protocol 'NMMessage'
extension Data: NMMessage {
    public var opcode: UInt8 { NMOpcodes.binary.rawValue }
    public var raw: Data { self }
}
