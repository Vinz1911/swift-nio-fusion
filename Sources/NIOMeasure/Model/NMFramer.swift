//
//  NMFramer.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 13.04.25.
//

import Foundation

internal actor NMFramer: Sendable {
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
    
    /// Clear the message buffer
    ///
    /// Current message buffer will be cleared to
    /// prevent potential buffer overflow
    internal func reset() async -> Void {
        self.buffer = .empty
    }
    
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to `Data` and `String`
    /// - Returns: generic Result type returning data and possible error
    internal static func create<T: NMMessage>(message: T) async throws -> Data {
        guard message.raw.count <= NMConstants.frame.rawValue - NMConstants.control.rawValue else { throw NMError.writeBufferOverflow }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + NMConstants.control.rawValue).bigEndianData)
        frame.append(message.raw)
        return frame
    }
    
    /// Parse a protocol conform message frame
    ///
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns generic Result type with parsed message and possible error
    internal func parse(data: DispatchData) async throws -> [NMMessage] {
        var messages: [NMMessage] = []; buffer.append(data); var length = buffer.length; if length <= .zero { return .init() }
        guard buffer.count <= NMConstants.frame.rawValue else { throw NMError.readBufferOverflow }
        guard buffer.count >= NMConstants.control.rawValue, buffer.count >= length else { return .init() }
        while buffer.count >= length && length != .zero {
            guard let bytes = buffer.payload() else { throw NMError.parsingFailed }
            switch buffer.first {
            case NMOpcodes.binary.rawValue: messages.append(bytes)
            case NMOpcodes.ping.rawValue: messages.append(UInt16(bytes.count))
            case NMOpcodes.text.rawValue: if let message = String(bytes: bytes, encoding: .utf8) { messages.append(message) }
            default: throw NMError.unexpectedOpcode }
            if buffer.count >= length { buffer = buffer.subdata(in: .init(length)..<buffer.count) }; length = buffer.length
        }
        return messages
    }
}
