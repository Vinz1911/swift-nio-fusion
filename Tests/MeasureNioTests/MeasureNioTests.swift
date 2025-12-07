import Testing
import NIOCore
@testable import MeasureNio

@Suite("Measure Nio Tests")
struct MeasureNioTests {
    @Test("Framer Parser")
    func parser() async throws {
        let framer = FusionFramer(); var buffer = ByteBuffer()
        
        let messageText = "Hello World! ⭐️"
        let messageRaw = ByteBuffer(bytes: [0x0, 0x1, 0x2, 0x3, 0x4])
        let messagePing = UInt16.max
        
        var bufferText = try await FusionFramer.create(message: messageText)
        var bufferRaw = try await FusionFramer.create(message: messageRaw)
        var bufferPing = try await FusionFramer.create(message: messagePing)
        
        buffer.writeImmutableBuffer(bufferText)
        buffer.writeImmutableBuffer(bufferRaw)
        buffer.writeImmutableBuffer(bufferPing)
        
        for message in try await framer.parse(data: buffer) {
            if let message = message as? String { #expect(message == messageText) }
            if let message = message as? ByteBuffer { #expect(message.readableBytes == messageRaw.readableBytes) }
            if let message = message as? UInt16 { #expect(message == messagePing) }
        }
    }
}
