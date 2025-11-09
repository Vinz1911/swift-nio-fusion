//
//  Extensions.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 17.04.25.
//

import Foundation

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

internal extension DispatchData {
    /// Extract the message frame size from the data,
    /// if not possible it returns nil
    ///
    /// - Returns: the size as `UInt32`
    var length: UInt32 {
        guard self.count >= NFKConstants.control.rawValue else { return .zero }
        let size = self.subdata(in: NFKConstants.opcode.rawValue..<NFKConstants.control.rawValue)
        return Data(size).bigEndian
    }
    
    /// Extract the message and remove the overhead,
    /// if not possible it returns nil
    ///
    /// - Returns: the extracted message as `Data`
    func payload() -> Data? {
        guard self.count >= NFKConstants.control.rawValue else { return nil }
        guard self.length > NFKConstants.control.rawValue else { return Data() }
        return Data(self.subdata(in: NFKConstants.control.rawValue..<Int(self.length)))
    }
}
