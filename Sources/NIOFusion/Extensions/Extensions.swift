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
    
    /// Log channel `IOError`
    ///
    /// - Parameter error: the `Error`
    func outin(from error: Error) -> Void {
        guard let error = error as? IOError else { return }
        guard error.errnoCode != ECONNRESET, error.errnoCode != EPIPE, error.errnoCode != EBADF else { return }
        Logger.shared.error("\(error)")
    }
}

// MARK: - Endpoint -

extension FusionEndpoint {
    /// The localhost endpoint
    static var localhost: Self { .init(host: "127.0.0.1", port: 7878) }
    
    /// The production endpoint
    static var production: Self { .init(host: "0.0.0.0", port: 7878) }
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
        guard let length = length.payload, let payload = self.getSlice(at: FusionStatic.header.rawValue, length: length) else { return nil }
        return FusionOpcode(rawValue: opcode)?.type.decode(from: payload)
    }
}
