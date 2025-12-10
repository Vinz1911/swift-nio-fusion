//
//  EchoServer.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 10.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import NIOPosix
import Logging

// @main << TODO: Enable -
struct EchoServer: Sendable {
    /// The `main` entry point.
    ///
    /// Start the `EchoServer` and receive data.
    static func main() async throws {
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let server = try FusionBootstrap(host: "127.0.0.1", port: 7878, group: group)
        
        Logger.shared.notice(.init(stringLiteral: .logo))
        Logger.shared.info(.init(stringLiteral: .version))
        Logger.shared.info("System core count: \(System.coreCount)")
        Logger.shared.info("Mode: Echo")
        
        try await server.run() { await server.send($0, $1) }
    }
}

