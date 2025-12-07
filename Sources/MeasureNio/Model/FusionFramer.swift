//
//  FusionFramer.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 13.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

actor FusionFramer: FusionFramerProtocol {
    private var buffer: ByteBuffer = .init()
    
    /// Clear the message buffer
    ///
    /// Current message buffer will be cleared
    func clear() async -> Void { self.buffer.clear() }
    
    /// Create a `FusionMessage` conform frame
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    /// - Returns: the message frame as `ByteBuffer`
    static func create<T: FusionFrame>(message: T) async throws -> ByteBuffer {
        guard message.size <= FusionPacket.frame.rawValue else { throw FusionFramerError.writeBufferOverflow }
        var frame = ByteBuffer(); frame.writeInteger(message.opcode); frame.writeInteger(message.size, endianness: .big, as: UInt32.self); frame.writeImmutableBuffer(message.encode)
        return frame
    }
    
    /// Parse a `FusionMessage` conform frame
    ///
    /// - Parameter data: pointer to the `ByteBuffer` which holds the `FusionMessage`
    /// - Returns: a collection of `FusionMessage`s
    func parse(data: ByteBuffer) async throws -> [FusionFrame] {
        var messages: [FusionFrame] = []; buffer.writeImmutableBuffer(data); guard var length = buffer.length() else { return .init() }
        guard buffer.readableBytes <= FusionPacket.frame.rawValue else { throw FusionFramerError.readBufferOverflow }
        guard buffer.readableBytes >= FusionPacket.header.rawValue, buffer.readableBytes >= length else { return .init() }
        while buffer.readableBytes >= length && length != .zero {
            guard let opcode = buffer.getInteger(at: buffer.readerIndex, as: UInt8.self) else { throw FusionFramerError.parsingFailed }
            guard let payload = buffer.payload(length: length) else { throw FusionFramerError.parsingFailed }
            guard let message = payload.decode(with: opcode) else { throw FusionFramerError.parsingFailed }
            if buffer.readableBytes >= length { buffer.moveReaderIndex(forwardBy: Int(length)); buffer.discardReadBytes() }
            if let index = buffer.length(at: buffer.readerIndex) { length = index }; messages.append(message)
        }
        return messages
    }
}
