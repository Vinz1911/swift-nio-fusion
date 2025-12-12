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
    static let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    static let bootstrap = FusionBootstrap(host: "127.0.0.1", port: 7878, group: group)
    
    /// The `main` entry point.
    ///
    /// Start the `MeasureServer` and receive data.
    /// This is used as Bandwidth throughput server, it receives data or a requested amount of data
    /// and sends the appropriated value back to the client.
    static func main() async throws {
        MallocAdapter.configure()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        
        Logger.shared.notice(.init(stringLiteral: .logo))
        Logger.shared.info(.init(stringLiteral: .version))
        Logger.shared.info("System core count: \(System.coreCount)")
        Logger.shared.info("Mode: Measure")
        
        try await bootstrap.run { result in await handler(result: result) }
    }
}

// MARK: - Private API Extension -

extension MeasureServer {
    /// Server channel handler
    ///
    /// - Parameters:
    ///   - message: the received `FusionMessage`
    ///   - outbound: the outbound channel writer `NIOAsyncChannelOutboundWriter`
    private static func handler(result: FusionResult) async -> Void {
        var message: FusionMessage?
        if let received = result.message as? String { message = ByteBuffer(repeating: .zero, count: min(max(Int(received) ?? .zero, 0x1), 0x400000)) }
        if let received = result.message as? ByteBuffer { message = "\(received.readableBytes)" }
        if let received = result.message as? UInt16 { message = received }
        if let message { await bootstrap.send(message, result.outbound) }
    }
}
