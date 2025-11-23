//
//  FusionMessage.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 13.04.25.
//

import NIOCore

// MARK: - Fusion Message Protocol -

/// The `FusionMessage` protocol for message compliance
public protocol FusionMessage: Sendable {
    var opcode: UInt8 { get }
    var raw: ByteBuffer { get }
}

// MARK: - Fusion Message Extensions -

/// Conformance to protocol `FusionMessage`
extension UInt16: FusionMessage {
    public var opcode: UInt8 { FusionOpcodes.ping.rawValue }
    public var raw: ByteBuffer { ByteBuffer(bytes: Array<UInt8>(repeating: .zero, count: Int(self))) }
}

/// Conformance to protocol `FusionMessage`
extension String: FusionMessage {
    public var opcode: UInt8 { FusionOpcodes.text.rawValue }
    public var raw: ByteBuffer { ByteBuffer(string: self) }
}

/// Conformance to protocol `FusionMessage`
extension ByteBuffer: FusionMessage {
    public var opcode: UInt8 { FusionOpcodes.binary.rawValue }
    public var raw: ByteBuffer { self }
}
