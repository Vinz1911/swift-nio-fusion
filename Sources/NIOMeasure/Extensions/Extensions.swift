//
//  Extensions.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 17.04.25.
//

import Foundation
import Logging

internal extension String {
    /// Version number
    static let version = "v1.0.1"
    
    /// Prompt logo
    static let logo = #"""
    
     _____   _______________     ______  ___                                      
     ___  | / /___  _/_  __ \    ___   |/  /__________ ___________  _____________ 
     __   |/ / __  / _  / / /    __  /|_/ /_  _ \  __ `/_  ___/  / / /_  ___/  _ \
     _  /|  / __/ /  / /_/ /     _  /  / / /  __/ /_/ /_(__  )/ /_/ /_  /   /  __/
     /_/ |_/  /___/  \____/      /_/  /_/  \___/\__,_/ /____/ \__,_/ /_/    \___/ 
    +-----------------------------------------------------------------------------+
    | High performance TCP measurement server based on custom Fusion Engine.      |
    | Support's inbound and outbound connection speed measurement + RTT.          |
    | More information at: https://weist.org                                      |
    +-----------------------------------------------------------------------------+
    """#
}

internal extension UInt32 {
    /// Convert integer to data with bigEndian
    var bigEndianData: Data { withUnsafeBytes(of: self.bigEndian) { Data($0) } }
}

internal extension Data {
    /// Extract integers from data as big endian
    var bigEndian: UInt32 {
        guard !self.isEmpty else { return .zero }
        return UInt32(bigEndian: withUnsafeBytes { $0.load(as: UInt32.self) })
    }
}

internal extension Logger {
    /// Singleton to access logger
    static let shared = Logger(label: .init())
}

internal extension Int {
    /// The minimum buffer size
    static var minimum: Self { 0x4000 }
    
    /// The maximum buffer size
    static var maximum: Self { 0x400000 }
}

internal extension DispatchData {
    /// Extract the message frame size from the data,
    /// if not possible it returns nil
    ///
    /// - Returns: the size as `UInt32`
    var length: UInt32 {
        guard self.count >= NMConstants.control.rawValue else { return .zero }
        let size = self.subdata(in: NMConstants.opcode.rawValue..<NMConstants.control.rawValue)
        return Data(size).bigEndian
    }
    
    /// Extract the message and remove the overhead,
    /// if not possible it returns nil
    ///
    /// - Returns: the extracted message as `Data`
    func payload() -> Data? {
        guard self.count >= NMConstants.control.rawValue else { return nil }
        guard self.length > NMConstants.control.rawValue else { return Data() }
        return Data(self.subdata(in: NMConstants.control.rawValue..<Int(self.length)))
    }
}
