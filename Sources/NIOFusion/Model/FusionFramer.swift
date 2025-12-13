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
    static nonisolated func create<T: FusionFrame>(message: T) throws(FusionFramerError) -> ByteBuffer {
        guard message.size <= FusionStatic.total.rawValue else { throw .outputBufferOverflow }
        var frame = ByteBuffer(); frame.writeInteger(message.opcode); frame.writeInteger(UInt32(message.size), endianness: .big, as: UInt32.self); frame.writeImmutableBuffer(message.encode)
        return frame
    }
    
    /// Parse a `FusionMessage` conform frame
    ///
    /// - Parameter data: pointer to the `ByteBuffer` which holds the `FusionMessage`
    /// - Returns: a collection of `FusionMessage`s
    func parse(data: ByteBuffer) async throws(FusionFramerError) -> [FusionFrame] {
        var messages: [FusionFrame] = []; buffer.writeImmutableBuffer(data)
        guard buffer.readableBytes <= FusionStatic.total.rawValue else { throw .inputBufferOverflow }
        guard buffer.readableBytes >= FusionStatic.header.rawValue else { return .init() }
        while let length = buffer.length(), buffer.readableBytes >= length && length != .zero {
            guard let opcode = buffer.getInteger(at: buffer.readerIndex, as: UInt8.self) else { throw .loadOpcodeFailed }
            guard let message = buffer.decode(with: opcode, from: length) else { throw .decodeMessageFailed }
            buffer.moveReaderIndex(forwardBy: Int(length)); buffer.discardReadBytes(); messages.append(message)
        }
        return messages
    }
}
