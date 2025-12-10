//
//  MeasureError.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 17.04.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

// MARK: - Measure Bootstrap Error -

/// The `MeasureBootstrapError` specific errors
@frozen
public enum MeasureBootstrapError: Error, Sendable {
    case invalidHostName
    case invalidPortNumber
    
    public var description: String {
        switch self {
        case .invalidHostName: return "host name is invalid, failed to create instance"
        case .invalidPortNumber: return "port number is invalid, failed to create instance" }
    }
}

// MARK: - Fusion Framer Error -

/// The `FusionFramerError` specific errors
@frozen
public enum FusionFramerError: Error, Sendable {
    case inputBufferOverflow
    case outputBufferOverflow
    case loadOpcodeFailed
    case decodeMessageFailed
    
    public var description: String {
        switch self {
        case .inputBufferOverflow: "input buffer overflow occured while reading from the underlying socket"
        case .outputBufferOverflow: "output buffer overflow occured while preparing message frame"
        case .loadOpcodeFailed: "unable to load opcode, discard this frame (this should never happen!)"
        case .decodeMessageFailed: "unable to decode message, discard this frame" }
    }
}
