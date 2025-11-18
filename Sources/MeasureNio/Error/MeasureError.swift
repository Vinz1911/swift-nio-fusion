//
//  MeasureError.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 17.04.25.
//

// MARK: - Measure Bootstrap Error -

/// The `FusionConnectionError` specific errors
@frozen
public enum MeasureBootstrapError: Error, Sendable {
    case missingHost
    case missingPort
    
    public var description: String {
        switch self {
        case .missingHost: return "missing host"
        case .missingPort: return "missing port" }
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
