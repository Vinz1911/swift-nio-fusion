//
//  NMServer.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 17.04.25.
//

import NIOCore
import NIOPosix
import Foundation

@main
internal struct NFKServer: Sendable {
    /// The `main` entry point.
    ///
    /// Start the `NFKServer` and receive data.
    /// This is used as Bandwidth measurement server, it receives data or a requested amount of data
    /// and sends the appropriated value back to the client.
    static func main() async throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let server = NFKBootstrap(host: "127.0.0.1", port: 7878, group: group)
        try await server.run() { await handleMessage(server: server, message: $0, outbound: $1) }
    }
    
    private static func handleMessage(server: NFKBootstrap, message: NFKMessage, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) async -> Void {
        if let message = message as? String { await server.send(Data(count: min(max(Int(message) ?? .zero, 1000), 4096 * 4096)), outbound) }
        if let message = message as? Data { await server.send("\(message.count)", outbound) }
        if let message = message as? UInt16 { await server.send(message, outbound) }
    }
}
