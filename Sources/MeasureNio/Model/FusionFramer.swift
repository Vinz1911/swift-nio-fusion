//
//  FusionFramer.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 13.04.25.
//

import NIOCore

internal actor FusionFramer: FusionFramerProtocol, Sendable {
    private var buffer: ByteBuffer = .init()
    
    /// Clear the message buffer
    ///
    /// Current message buffer will be cleared
    internal func reset() async -> Void {
        self.buffer.clear()
    }
    
    /// Create a `FusionMessage` conform frame
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    /// - Returns: the message frame as `ByteBuffer`
    internal static func create<T: FusionMessage>(message: T) async throws -> ByteBuffer {
        let total = message.raw.readableBytes + FusionConstants.header.rawValue
        guard total <= FusionConstants.frame.rawValue else { throw FusionFramerError.writeBufferOverflow }
        
        var frame = ByteBuffer(), raw = message.raw
        frame.writeInteger(message.opcode)
        frame.writeInteger(UInt32(total), endianness: .big, as: UInt32.self)
        frame.writeBuffer(&raw)
        return frame
    }
    
    /// Parse a `FusionMessage` conform frame
    ///
    /// - Parameter data: pointer to the `ByteBuffer` which holds the `FusionMessage`
    /// - Returns: a collection of `FusionMessage`s
    internal func parse(data: inout ByteBuffer) async throws -> [FusionMessage] {
        var messages: [FusionMessage] = []; buffer.writeBuffer(&data)
        guard var length = buffer.getInteger(at: .one, endianness: .big, as: UInt32.self) else { return .init() }
        guard buffer.readableBytes <= FusionConstants.frame.rawValue else { throw FusionFramerError.readBufferOverflow }
        guard buffer.readableBytes >= FusionConstants.header.rawValue, buffer.readableBytes >= length else { return .init() }
        while buffer.readableBytes >= length && length != .zero {
            guard let opcode = buffer.getInteger(at: buffer.readerIndex, as: UInt8.self) else { throw FusionFramerError.parsingFailed }
            guard let bytes = buffer.extractPayload(length: length) else { throw FusionFramerError.parsingFailed }
            
            switch opcode {
            case FusionOpcodes.binary.rawValue: messages.append(ByteBuffer(bytes: bytes))
            case FusionOpcodes.ping.rawValue: messages.append(UInt16(bytes.count))
            case FusionOpcodes.text.rawValue: messages.append(String(bytes: bytes, encoding: .utf8) ?? .init())
            default: throw FusionFramerError.unexpectedOpcode }
            
            if buffer.readableBytes <= Int(length) { buffer.clear() } else { buffer.moveReaderIndex(forwardBy: Int(length)); buffer.discardReadBytes() }
            if let extracted = buffer.getInteger(at: buffer.readerIndex + .one, endianness: .big, as: UInt32.self) { length = extracted }
        }
        return messages
    }
}
