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

@main
internal struct NMServer: Sendable {
    /// The `main` entry point.
    ///
    /// Start the `NMServer` and receive data.
    /// This is used as Bandwidth measurement server, it receives data or a requested amount of data
    /// and sends the appropriated value back to the client.
    static func main() async throws {
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let server = NMBootstrap(host: "127.0.0.1", port: 7878, group: group)
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
