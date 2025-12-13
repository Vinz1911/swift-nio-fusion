//
//  MallocAdapter.swift
//  NIOFusion
//
//  Created by Vinzenz Weist on 10.12.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import NIOCore
import Logging

#if os(Linux)
import Glibc
#endif

struct MallocAdapter {
    private static let M_TRIM_THRESHOLD: Int32  = -1
    private static let M_MMAP_THRESHOLD: Int32  = -3
    private static let M_ARENA_MAX: Int32       = -8
    
    static func configure() {
        #if os(Linux)
        _ = Glibc.mallopt(M_ARENA_MAX, 2)
        _ = Glibc.mallopt(M_TRIM_THRESHOLD, 131_072)
        _ = Glibc.mallopt(M_MMAP_THRESHOLD, 131_072)
        #else
        Logger.shared.error("Malloc configuaration is not supported")
        #endif
    }
}
