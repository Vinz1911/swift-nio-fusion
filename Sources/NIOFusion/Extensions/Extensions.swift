//
//  Extensions.swift
//  NIOFusion
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
    
           _____   _______________     __________             _____              
           ___  | / /___  _/_  __ \    ___  ____/___  ___________(_)____________ 
           __   |/ / __  / _  / / /    __  /_   _  / / /_  ___/_  /_  __ \_  __ \
           _  /|  / __/ /  / /_/ /     _  __/   / /_/ /_(__  )_  / / /_/ /  / / /
           /_/ |_/  /___/  \____/      /_/      \__,_/ /____/ /_/  \____//_/ /_/ 
    +----------------------------------------------------------------------------------+
    | A high-performance, low-overhead protocol built on top of TCP.                   |
    | Support for various types of high performance applications like data transfer.   |
    | More information can be found at: https://weist.org                              |
    +----------------------------------------------------------------------------------+
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
    
    /// Decode a `FusionMessage` as `FusionFrame`
    ///
    /// - Parameters:
    ///   - opcode: the `FusionOpcode`
    ///   - length: the length of the payload
    /// - Returns: the `FusionMessage`
    func decode(with opcode: UInt8, from length: UInt32) -> FusionFrame? {
        guard let payload = self.getSlice(at: FusionPacket.header.rawValue, length: Int(length) - FusionPacket.header.rawValue) else { return nil }
        guard let opcode = FusionOpcode(rawValue: opcode) else { return nil }
        return switch opcode { case .string: String.decode(from: payload) case .data: ByteBuffer.decode(from: payload) case .uint16: UInt16.decode(from: payload) }
    }
}
