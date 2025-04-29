//
//  NFKFramer.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 13.04.25.
//

import Foundation

internal final actor NFKFramer: Sendable {
    private var buffer: DispatchData = .empty
    internal func reset() { buffer = .empty }
    
    /// The `NFKFramer` represents the fusion framing protocol.
    /// This is a very fast and lightweight message framing protocol that supports `String` and `Data` based messages.
    /// It also supports `UInt16` for ping based transfer responses.
    /// The protocol's overhead per message is only `0x5` bytes, resulting in high performance.
    ///
    /// This protocol is based on a standardized Type-Length-Value Design Scheme.
    
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to `Data` and `String`
    /// - Returns: generic Result type returning data and possible error
    internal static func create<T: NFKMessage>(message: T) async throws -> Data {
        guard message.raw.count <= NFKConstants.frame.rawValue - NFKConstants.control.rawValue else { throw NFKError.writeBufferOverflow }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + NFKConstants.control.rawValue).bigEndianData)
        frame.append(message.raw); return frame
    }
    
    /// Parse a protocol conform message frame
    ///
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns generic Result type with parsed message and possible error
    internal func parse(data: DispatchData, _ completion: (NFKMessage) async throws -> Void) async throws -> Void {
        buffer.append(data)
        guard let length = self.length() else { return }
        guard buffer.count <= NFKConstants.frame.rawValue else { throw NFKError.readBufferOverflow }
        guard buffer.count >= NFKConstants.control.rawValue, buffer.count >= length else { return }
        while buffer.count >= length && length != .zero {
            guard let bytes = message(length: length) else { throw NFKError.parsingFailed }
            switch buffer.first {
            case NFKOpcodes.binary.rawValue: try await completion(bytes)
            case NFKOpcodes.ping.rawValue: try await completion(UInt16(bytes.count))
            case NFKOpcodes.text.rawValue: guard let result = String(bytes: bytes, encoding: .utf8) else { throw NFKError.parsingFailed }; try await completion(result)
            default: throw NFKError.unexpectedOpcode }
            if buffer.count <= length { reset() } else { buffer = buffer.subdata(in: .init(length)..<buffer.count) }
        }
    }
}

// MARK: - Private API Extension -

private extension NFKFramer {
    /// Extract the message frame size from the data,
    /// if not possible it returns nil
    /// - Returns: the size as `UInt32`
    private func length() -> UInt32? {
        guard buffer.count >= NFKConstants.control.rawValue else { return nil }
        let size = Data(buffer.subdata(in: NFKConstants.opcode.rawValue..<NFKConstants.control.rawValue))
        return size.bigEndianUInt32
    }
    
    /// Extract the message and remove the overhead,
    /// if not possible it returns nil
    /// - Parameter length: the length of the extracting message
    /// - Returns: the extracted message as `Data`
    private func message(length: UInt32) -> Data? {
        guard buffer.count >= NFKConstants.control.rawValue else { return nil }
        guard length > NFKConstants.control.rawValue else { return .init() }
        return .init(buffer.subdata(in: NFKConstants.control.rawValue..<Int(length)))
    }
}
