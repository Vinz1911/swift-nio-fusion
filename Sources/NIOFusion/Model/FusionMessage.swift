//
//  FusionMessage.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 13.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

// MARK: - Generic Fusion Message Protocol -

/// The public generic `FusionMessage` protocol
///
/// The `FusionMessage` is a generic public message protocol
/// It conforms to `UInt16`, `String` and `Data`
public protocol FusionMessage: Sendable { }

/// The `FusionFrame` protocol for message conformance
protocol FusionFrame: FusionMessage {
    var opcode: UInt8 { get }
    var size: UInt64 { get }
    var encode: ByteBuffer { get }
    static func decode(from payload: ByteBuffer) -> FusionFrame?
}

// MARK: - Fusion Message Extensions -

/// Conformance to protocol `FusionFrame` and `FusionMessage`
extension UInt16: FusionFrame {
    var opcode: UInt8 { FusionOpcode.uint16.rawValue }
    var size: UInt64 { UInt64(self.encode.readableBytes + FusionStatic.header.rawValue) }
    var encode: ByteBuffer { ByteBuffer(repeating: .zero, count: Int(self)) }
    static func decode(from payload: ByteBuffer) -> FusionFrame? { Self(payload.readableBytes) }
}

/// Conformance to protocol `FusionFrame` and `FusionMessage`
extension String: FusionFrame {
    var opcode: UInt8 { FusionOpcode.string.rawValue }
    var size: UInt64 { UInt64(self.encode.readableBytes + FusionStatic.header.rawValue) }
    var encode: ByteBuffer { ByteBuffer(string: self) }
    static func decode(from payload: ByteBuffer) -> FusionFrame? { try? payload.getUTF8ValidatedString(at: payload.readerIndex, length: payload.readableBytes) }
}

/// Conformance to protocol `FusionFrame` and `FusionMessage`
extension ByteBuffer: FusionFrame {
    var opcode: UInt8 { FusionOpcode.data.rawValue }
    var size: UInt64 { UInt64(self.encode.readableBytes + FusionStatic.header.rawValue) }
    var encode: ByteBuffer { self }
    static func decode(from payload: ByteBuffer) -> FusionFrame? { payload }
}
