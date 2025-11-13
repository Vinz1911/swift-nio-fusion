//
//  NMServer.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 17.04.25.
//

import NIOCore
import NIOPosix
import Foundation
import Logging

#if os(Linux)
import Glibc

let M_TRIM_THRESHOLD: Int32 = -1
let M_MMAP_THRESHOLD: Int32 = -3
let M_ARENA_MAX: Int32 = -8

@_silgen_name("mallopt")
func c_mallopt(_ param: Int32, _ value: Int32) -> Int32
func configMalloc() {
    _ = c_mallopt(M_ARENA_MAX, 2)
    _ = c_mallopt(M_TRIM_THRESHOLD, 131_072)
    _ = c_mallopt(M_MMAP_THRESHOLD, 131_072)
}
#endif

@main
internal struct NMServer: Sendable {
    /// The `main` entry point.
    ///
    /// Start the `NMServer` and receive data.
    /// This is used as Bandwidth measurement server, it receives data or a requested amount of data
    /// and sends the appropriated value back to the client.
    static func main() async throws {
        #if os(Linux)
        configMalloc()
        #endif
        
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let server = NMBootstrap(host: "0.0.0.0", port: 7878, group: group)
        Logger.shared.notice(.init(stringLiteral: .logo))
        Logger.shared.info(.init(stringLiteral: .version))
        try await server.run() { await handleMessage(server: server, message: $0, outbound: $1) }
    }
    
    /// Server connection handler
    ///
    /// - Parameters:
    ///   - server: the server `NMBootstrap`
    ///   - message: the received `NMMessage`
    ///   - outbound: the outbound channel writer `NIOAsyncChannelOutboundWriter`
    private static func handleMessage(server: NMBootstrap, message: NMMessage, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void {
        if let message = message as? String { await server.send(Data(count: min(max(Int(message) ?? .zero, Int.minimum), Int.maximum)), outbound) }
        if let message = message as? Data { await server.send("\(message.count)", outbound) }
        if let message = message as? UInt16 { await server.send(message, outbound) }
    }
}
