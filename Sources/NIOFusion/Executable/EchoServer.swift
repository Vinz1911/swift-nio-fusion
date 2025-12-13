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
    static let endpoint: FusionEndpoint = .localhost
    static let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    static let bootstrap = FusionBootstrap(from: .localhost, group: group)
    
    /// The `main` entry point.
    ///
    /// Start the `EchoServer` and receive data.
    static func main() async throws {
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        
        Logger.shared.notice(.init(stringLiteral: .logo))
        Logger.shared.info(.init(stringLiteral: .version))
        Logger.shared.info("System core count: \(System.coreCount)")
        Logger.shared.info("Echo Server")
        Logger.shared.info("Listening on \(self.endpoint.host):\(self.endpoint.port)")
        
        Task { for await result in bootstrap.receive() { await bootstrap.send(result.message, result.outbound) } }
        try await bootstrap.run()
    }
}
