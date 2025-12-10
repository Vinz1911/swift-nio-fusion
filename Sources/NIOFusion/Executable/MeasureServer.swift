//
//  MeasureServer.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 17.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import NIOPosix
import Logging

@main
struct MeasureServer: Sendable {
    /// The `main` entry point.
    ///
    /// Start the `MeasureServer` and receive data.
    /// This is used as Bandwidth throughput server, it receives data or a requested amount of data
    /// and sends the appropriated value back to the client.
    static func main() async throws {
        MallocAdapter.configure()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let server = try FusionBootstrap(host: "127.0.0.1", port: 7878, group: group)
        
        Logger.shared.notice(.init(stringLiteral: .logo))
        Logger.shared.info(.init(stringLiteral: .version))
        Logger.shared.info("System core count: \(System.coreCount)")
        Logger.shared.info("Mode: Measure")

        try await server.run() { message, outbound in
            await handler(server: server, message: message, outbound: outbound)
        }
    }
}

// MARK: - Private API Extension -

extension MeasureServer {
    /// Server channel handler
    ///
    /// - Parameters:
    ///   - server: the server `FusionBootstrap`
    ///   - message: the received `FusionMessage`
    ///   - outbound: the outbound channel writer `NIOAsyncChannelOutboundWriter`
    private static func handler(server: FusionBootstrap, message: FusionMessage, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void {
        if let message = message as? String { await server.send(ByteBuffer(repeating: .zero, count: min(max(Int(message) ?? .zero, 0x1), 0x400000)), outbound) }
        if let message = message as? ByteBuffer { await server.send("\(message.readableBytes)", outbound) }
        if let message = message as? UInt16 { await server.send(message, outbound) }
    }
}
