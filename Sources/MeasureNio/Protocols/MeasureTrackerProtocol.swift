//
//  MeasureTrackerProtocol.swift
//  MeasureNio
//
//  Created by Vinzenz Weist on 15.11.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Foundation

protocol MeasureTrackerProtocol: Sendable {
    /// Create instance of `MeasureTracker`
    ///
    /// - Parameter expiration: reset interval
    init(expiration: TimeInterval)
    
    /// Address to log
    ///
    /// - Parameter address: the ip address
    /// - Returns: true if it should log again
    func log(_ address: String) async -> Bool
}
