//
//  FusionError.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 17.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore

// MARK: - Fusion Framer Error -

/// The `FusionFramerError` specific errors
@frozen
public enum FusionFramerError: Error, Sendable {
    case inbound
    case outbound
    case invalid
    case opcode
    case decode
    
    public var description: String {
        switch self {
        case .inbound: "inbound buffer overflow occured while reading from the underlying socket"
        case .outbound: "outbound buffer overflow occured while preparing message frame"
        case .invalid: "invalid length is not allowed, discard this frame"
        case .opcode: "unable to extract opcode, discard this frame (this should never happen!)"
        case .decode: "unable to decode message, discard this frame" }
    }
}
