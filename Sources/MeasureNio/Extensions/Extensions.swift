//
//  Extensions.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 17.04.25.
//

import Logging
import NIOCore

// MARK: - String -

internal extension String {
    /// Version number
    static let version = "v1.2.0"
    
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

internal extension Logger {
    /// Singleton to access logger
    static let shared = Logger(label: .init())
}

// MARK: - Int -

internal extension Int {
    /// The minimum buffer size
    static var minimum: Self { 0x1 }
    
    /// The maximum buffer size
    static var maximum: Self { 0x400000 }
}

internal extension Int32 {
    /// The maximum backlog
    static var backlogMax: Self { 256 }
}

internal extension Int64 {
    /// The channel timeout
    static var timeout: Self { 90 }
}

internal extension UInt {
    /// The maximum messages
    static var messageMax: Self { 16 }
}

// MARK: - Numeric -

internal extension Numeric where Self: ExpressibleByIntegerLiteral {
    /// One is the identity element
    static var one: Self { 1 }
}

// MARK: - ByteBuffer -

internal extension ByteBuffer {
    /// Extract `[UInt8]` from `ByteBuffer`
    ///
    /// - Parameter length: the amount of bytes to extract
    /// - Returns: the extracted bytes as `[UInt8]`
    func extractPayload(length: UInt32) -> [UInt8]? {
        self.getBytes(at: FusionConstants.header.rawValue, length: Int(length) - FusionConstants.header.rawValue)
    }
}
