//
//  FusionFramer.swift
//  NIOFusion
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
    static nonisolated func create<T: FusionFrame>(message: T) throws -> ByteBuffer {
        guard message.size <= FusionPacket.payload.rawValue else { throw FusionFramerError.outputBufferOverflow }
        var frame = ByteBuffer(); frame.writeInteger(message.opcode); frame.writeInteger(UInt32(message.size), endianness: .big, as: UInt32.self); frame.writeImmutableBuffer(message.encode)
        return frame
    }
    
    /// Parse a `FusionMessage` conform frame
    ///
    /// - Parameter data: pointer to the `ByteBuffer` which holds the `FusionMessage`
    /// - Returns: a collection of `FusionMessage`s
    func parse(data: ByteBuffer) async throws -> [FusionFrame] {
        var messages: [FusionFrame] = []; buffer.writeImmutableBuffer(data); guard var length = buffer.length() else { return .init() }
        guard buffer.readableBytes <= FusionPacket.payload.rawValue else { throw FusionFramerError.inputBufferOverflow }
        guard buffer.readableBytes >= FusionPacket.header.rawValue, buffer.readableBytes >= length else { return .init() }
        while buffer.readableBytes >= length && length != .zero {
            guard let opcode = buffer.getInteger(at: buffer.readerIndex, as: UInt8.self) else { throw FusionFramerError.loadOpcodeFailed }
            guard let message = buffer.decode(with: opcode, from: length) else { throw FusionFramerError.decodeMessageFailed }
            if buffer.readableBytes >= length { buffer.moveReaderIndex(forwardBy: Int(length)); buffer.discardReadBytes() }
            if let index = buffer.length(at: buffer.readerIndex) { length = index }; messages.append(message)
        }
        return messages
    }
}
