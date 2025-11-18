//
//  MeasureServer.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 17.04.25.
//

import NIOCore
import NIOPosix
import Logging

#if os(Linux)
import Glibc

let M_TRIM_THRESHOLD: Int32 = -1
let M_MMAP_THRESHOLD: Int32 = -3
let M_ARENA_MAX: Int32 = -8

@_silgen_name("mallopt")
func c_mallopt(_ param: Int32, _ value: Int32) -> Int32
func config_malloc() {
    _ = c_mallopt(M_ARENA_MAX, 2)
    _ = c_mallopt(M_TRIM_THRESHOLD, 131_072)
    _ = c_mallopt(M_MMAP_THRESHOLD, 131_072)
}
#endif

@main
internal struct MeasureServer: Sendable {
    /// The `main` entry point.
    ///
    /// Start the `MeasureServer` and receive data.
    /// This is used as Bandwidth measurement server, it receives data or a requested amount of data
    /// and sends the appropriated value back to the client.
    static func main() async throws {
        #if os(Linux)
        config_malloc()
        #endif
        
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let server = try MeasureBootstrap(host: "127.0.0.1", port: 7878, group: group)
        
        await startup()
        try await server.run() {
            await handler(server: server, message: $0, outbound: $1)
        }
    }
    
    /// Log startup
    ///
    /// Show logo and other information
    private static func startup() async -> Void {
        Logger.shared.notice(.init(stringLiteral: .logo))
        Logger.shared.info(.init(stringLiteral: .version))
        Logger.shared.info("System core count: \(System.coreCount)")
    }
    
    /// Server connection handler
    ///
    /// - Parameters:
    ///   - server: the server `MeasureBootstrap`
    ///   - message: the received `FusionMessage`
    ///   - outbound: the outbound channel writer `NIOAsyncChannelOutboundWriter`
    private static func handler(server: MeasureBootstrap, message: FusionMessage, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void {
        if let message = message as? String { await server.send(ByteBuffer(bytes: Array<UInt8>(repeating: .zero, count: min(max(Int(message) ?? .zero, Int.minimum), Int.maximum))), outbound) }
        if let message = message as? ByteBuffer { await server.send("\(message.readableBytes)", outbound) }
        if let message = message as? UInt16 { await server.send(message, outbound) }
    }
}
