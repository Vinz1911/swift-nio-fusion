//
//  NFKFramer.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 13.04.25.
//

import Foundation

internal actor NFKFramer: Sendable {
    private var buffer: DispatchData
    
    /// Create instance of `FKFramer`
    ///
    /// The `NKFramer` represents the fusion framing protocol.
    /// This is a very fast and lightweight message framing protocol that supports `String` and `Data` based messages.
    /// It also supports `UInt16` for ping based transfer responses.
    /// The protocol's overhead per message is only `0x5` bytes, resulting in high performance.
    ///
    /// This protocol is based on a standardized Type-Length-Value Design Scheme.
    internal init() {
        self.buffer = .empty
    }
    
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to `Data` and `String`
    /// - Returns: generic Result type returning data and possible error
    internal static func create<T: NFKMessage>(message: T) async throws -> Data {
        guard message.raw.count <= NFKConstants.frame.rawValue - NFKConstants.control.rawValue else { throw NFKError.writeBufferOverflow }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + NFKConstants.control.rawValue).bigEndianData)
        frame.append(message.raw)
        return frame
    }
    
    /// Parse a protocol conform message frame
    ///
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns generic Result type with parsed message and possible error
    internal func parse(data: DispatchData) async throws -> [NFKMessage] {
        var messages: [NFKMessage] = []; buffer.append(data); var length = buffer.length; if length <= .zero { return .init() }
        guard buffer.count <= NFKConstants.frame.rawValue else { throw NFKError.readBufferOverflow }
        guard buffer.count >= NFKConstants.control.rawValue, buffer.count >= length else { return .init() }
        while buffer.count >= length && length != .zero {
            guard let bytes = buffer.payload() else { throw NFKError.parsingFailed }
            switch buffer.first {
            case NFKOpcodes.binary.rawValue: messages.append(bytes)
            case NFKOpcodes.ping.rawValue: messages.append(UInt16(bytes.count))
            case NFKOpcodes.text.rawValue: if let message = String(bytes: bytes, encoding: .utf8) { messages.append(message) }
            default: throw NFKError.unexpectedOpcode }
            if buffer.count >= length { buffer = buffer.subdata(in: .init(length)..<buffer.count) }; length = buffer.length
        }
        return messages
    }
}
