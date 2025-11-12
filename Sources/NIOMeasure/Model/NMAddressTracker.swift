//
//  NMAddressTracker.swift
//  NIOMeasure
//
//  Created by Vinzenz Weist on 12.11.25.
//

import Foundation

actor NMAddressTracker {
    private var addresses: [String: Date] = [:]
    private let expiration: TimeInterval
    
    /// Create instance of `NMAddressTracker`
    ///
    /// - Parameter expiration: reset interval
    init(expiration: TimeInterval = 60) {
        self.expiration = expiration
    }
    
    /// Address to log
    ///
    /// - Parameter address: the ip address
    /// - Returns: true if it should log again
    func log(_ address: String) -> Bool {
        let now = Date()
        addresses = addresses.filter { now.timeIntervalSince($0.value) < expiration }
        guard addresses[address] == nil else { return false }
        addresses[address] = now; return true
    }
}
