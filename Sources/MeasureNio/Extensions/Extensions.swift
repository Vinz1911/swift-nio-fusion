//
//  Extensions.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 17.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Logging
import NIOCore

// MARK: - String -

extension String {
    /// Version number
    static let version = "v1.4.0"
    
    /// Prompt logo
    static let logo = #"""
    
        _____   _______________     ______  ___                                      
        ___  | / /___  _/_  __ \    ___   |/  /__________ ___________  _____________ 
        __   |/ / __  / _  / / /    __  /|_/ /_  _ \  __ `/_  ___/  / / /_  ___/  _ \
        _  /|  / __/ /  / /_/ /     _  /  / / /  __/ /_/ /_(__  )/ /_/ /_  /   /  __/
        /_/ |_/  /___/  \____/      /_/  /_/  \___/\__,_/ /____/ \__,_/ /_/    \___/ 
    +-----------------------------------------------------------------------------------+
    | High-performance measurement engine server based on the Fusion Framing Protocol.  |
    | Supports inbound and outbound channel speed measurement, including RTT.           |
    | More information can be found at: https://weist.org                               |
    +-----------------------------------------------------------------------------------+
    """#
}

// MARK: - Logger -

extension Logger {
    /// Singleton to access logger
    static let shared = Logger(label: .init())
}

// MARK: - Int -

extension Int32 {
    /// The maximum backlog
    static var backlogMax: Self { 256 }
}

extension Int64 {
    /// The channel timeout
    static var timeout: Self { 90 }
}

extension UInt {
    /// The maximum messages
    static var messageMax: Self { 16 }
}

// MARK: - ByteBuffer -

extension ByteBuffer {
    /// Extract `UInt32` from payload
    ///
    /// - Returns: the extracted length as `UInt32
    func length(at index: Int = .zero) -> UInt32? {
        return self.getInteger(at: index + 1, endianness: .big, as: UInt32.self)
    }
    
    /// Extract from `ByteBuffer` from payload
    ///
    /// - Parameter length: the amount of bytes to extract
    /// - Returns: the extracted bytes as `ByteBuffer`
    func payload(length: UInt32) -> ByteBuffer? {
        return self.getSlice(at: FusionPacket.header.rawValue, length: Int(length) - FusionPacket.header.rawValue)
    }
    
    /// Decode a `FusionMessage` as `FusionFrame`
    ///
    /// - Parameters:
    ///   - opcode: the `FusionOpcode`
    /// - Returns: the `FusionMessage`
    func decode(with opcode: UInt8) -> FusionFrame? {
        guard let opcode = FusionOpcode(rawValue: opcode) else { return nil }
        switch opcode { case .string: return String.decode(from: self) case .data: return ByteBuffer.decode(from: self) case .uint16: return UInt16.decode(from: self) }
    }
}
