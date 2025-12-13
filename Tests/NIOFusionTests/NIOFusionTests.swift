import Testing
import NIOCore
@testable import NIOFusion

@Suite("NIO Fusion Tests")
struct NIOFusionTests {
    /// Framer error validation
    @Test("Famer Error")
    func framerError() async throws {
        let framer = FusionFramer()
        let malformed = ByteBuffer(bytes: [1, 0, 0, 0, 1, 0, 0, 0, 10, 80, 97, 115, 115, 33])
        let invalid = ByteBuffer(bytes: [0x1, 0x0, 0x0, 0x0, 0x6, 0xFF])
        await #expect(throws: FusionFramerError.decodeMessageFailed) { await framer.clear(); let _ = try await framer.parse(data: invalid) }
        await #expect(throws: FusionFramerError.decodeMessageFailed) { await framer.clear(); let _ = try await framer.parse(data: malformed) }
    }
    
    /// Create + parse with `FusionFramer`
    @Test("Parse Message") func parseMessage() async throws {
        let framer = FusionFramer(); var frames: ByteBuffer = .init()
        let messages: [FusionMessage] = ["Hello World! 🌍", ByteBuffer(repeating: .zero, count: 16384), UInt16.max]
        var parsed: [FusionMessage] = .init()
        
        guard let messages = messages as? [FusionFrame] else { return }
        frames.writeImmutableBuffer(try FusionFramer.create(message: messages[0]))
        frames.writeImmutableBuffer(try FusionFramer.create(message: messages[1]))
        frames.writeImmutableBuffer(try FusionFramer.create(message: messages[2]))
        
        for message in try await framer.parse(data: frames) { parsed.append(message) }
        
        if let message = messages[0] as? String, let parse = parsed[0] as? String { #expect(message == parse) }
        if let message = messages[1] as? ByteBuffer, let parse = parsed[1] as? ByteBuffer { #expect(message == parse) }
        if let message = messages[2] as? UInt16, let parse = parsed[2] as? UInt16 { #expect(message == parse) }
    }
    
    /// Robustness check
    @Test("Parse Incomplete") func parseIncomplete() async throws {
        let framer = FusionFramer(); var messages: [String] = []
        var frames = try FusionFramer.create(message: "Pass!")
        let slices: [ByteBuffer] = [ByteBuffer(bytes: [1, 0, 0, 0]), ByteBuffer(bytes: [10, 80, 97]), ByteBuffer(bytes: [115, 115, 33])]
        
        frames.writeImmutableBuffer(slices[0])
        for message in try await framer.parse(data: frames) { if let message = message as? String { messages.append(message) } }
        
        let _ = try await framer.parse(data: slices[1])
        
        frames.writeImmutableBuffer(slices[2])
        for message in try await framer.parse(data: slices[2]) { if let message = message as? String { messages.append(message) } }
        #expect(messages[0] == messages[1])
    }
    
    /// Zer0 payload
    @Test("Zero Payload")
    func zeroPayload() async throws {
        let framer = FusionFramer()
        do {
            let frame = try FusionFramer.create(message: ByteBuffer())
            let parsed = try await framer.parse(data: frame)
            #expect(parsed.count == 1); #expect(parsed[0] is ByteBuffer); #expect((parsed[0] as? ByteBuffer)?.readableBytes == 0)
        }
        await framer.clear()
        do {
            let frame = try FusionFramer.create(message: "")
            let parsed = try await framer.parse(data: frame)
            #expect(parsed.count == 1); #expect(parsed[0] is String); #expect((parsed[0] as? String) == "")
        }
    }
}
