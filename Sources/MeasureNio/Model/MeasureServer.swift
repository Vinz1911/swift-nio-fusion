//
//  MeasureServer.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 17.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
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
struct MeasureServer: Sendable {
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
        
        Logger.shared.notice(.init(stringLiteral: .logo))
        Logger.shared.info(.init(stringLiteral: .version))
        Logger.shared.info("System core count: \(System.coreCount)")
        
        try await server.run() { message, outbound in
            await handler(server: server, message: message, outbound: outbound)
        }
    }
    
    /// Server channel handler
    ///
    /// - Parameters:
    ///   - server: the server `MeasureBootstrap`
    ///   - message: the received `FusionMessage`
    ///   - outbound: the outbound channel writer `NIOAsyncChannelOutboundWriter`
    private static func handler(server: MeasureBootstrap, message: FusionMessage, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void {
        if let message = message as? String { await server.send(ByteBuffer(repeating: .zero, count: min(max(Int(message) ?? .zero, 0x1), 0x400000)), outbound) }
        if let message = message as? ByteBuffer { await server.send("\(message.readableBytes)", outbound) }
        if let message = message as? UInt16 { await server.send(message, outbound) }
    }
}
