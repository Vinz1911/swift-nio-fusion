//
//  Extensions.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 17.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import NIOPosix

// MARK: - Int -

extension UInt32 {
    /// The fusion frame payload length
    var payload: Int? {
        guard self >= FusionStatic.header.rawValue else { return nil }
        return Int(self) - Int(FusionStatic.header.rawValue)
    }
}

// MARK: - ByteBuffer -

extension ByteBuffer {
    /// Extract `UInt32` from payload
    ///
    /// - Returns: the extracted length as `UInt32
    func length(at index: Int = .zero) throws(FusionFramerError) -> UInt32? {
        guard self.readableBytes >= FusionStatic.header.rawValue else { return nil }
        let length = self.getInteger(at: index + 1, endianness: .big, as: UInt32.self)
        if length != .zero { return length } else { throw FusionFramerError.invalid }
    }
    
    /// Decode a `FusionMessage` as `FusionFrame`
    ///
    /// - Parameters:
    ///   - opcode: the `FusionOpcode`
    ///   - length: the length of the payload
    /// - Returns: the `FusionMessage`
    func decode(with opcode: UInt8, from length: UInt32) -> FusionFrame? {
        guard let length = length.payload, let payload = self.getSlice(at: Int(FusionStatic.header.rawValue), length: length) else { return nil }
        return FusionOpcode(rawValue: opcode)?.rawType.decode(from: payload)
    }
}
