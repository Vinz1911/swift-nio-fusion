//
//  NIOFusionTracker.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 12.11.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Foundation

actor FusionTracker: FusionTrackerProtocol {
    private var addresses: [String: Date] = [:]
    private let expiration: TimeInterval
    
    /// Create instance of `FusionTracker`
    ///
    /// - Parameter expiration: reset interval
    init(expiration: TimeInterval = 30) {
        self.expiration = expiration
    }
    
    /// Address to log
    ///
    /// - Parameter address: the ip address
    /// - Returns: true if it should log again
    func log(_ address: String) async -> Bool {
        let now = Date(); addresses = addresses.filter { now.timeIntervalSince($0.value) < expiration }
        guard addresses[address] == nil else { return false }; addresses[address] = now; return true
    }
}
