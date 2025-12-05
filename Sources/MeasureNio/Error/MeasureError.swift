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
    case parsingFailed
    case readBufferOverflow
    case writeBufferOverflow
    case unexpectedOpcode
    
    public var description: String {
        switch self {
        case .parsingFailed: return "message parsing failed"
        case .readBufferOverflow: return "read buffer overflow"
        case .writeBufferOverflow: return "write buffer overflow"
        case .unexpectedOpcode: return "unexpected opcode" }
    }
}
