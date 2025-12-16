//
//  Extensions.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 17.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Logging
import NIOCore
import NIOPosix

// MARK: - String -

extension String {
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
    
    /// Log channel `IOError`
    ///
    /// - Parameter error: the `Error`
    func ioerror(from error: Error) -> Void {
        guard let error = error as? IOError else { return }
        guard error.errnoCode != ECONNRESET, error.errnoCode != EPIPE, error.errnoCode != EBADF else { return }
        Logger.shared.error("\(error)")
    }
}

// MARK: - Int -

extension UInt32 {
    /// The fusion frame payload length
    var payload: Int? {
        guard self >= FusionStatic.header.rawValue else { return nil }
        return Int(self) - FusionStatic.header.rawValue
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
        guard let length = length.payload, let payload = self.getSlice(at: FusionStatic.header.rawValue, length: length) else { return nil }
        return FusionOpcode(rawValue: opcode)?.type.decode(from: payload)
    }
}
