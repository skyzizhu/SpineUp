//
//  SULogger.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 统一结构化系统日志类，替代裸 print 调用
enum SULogger {
    private static let subsystem = SUAppConfig.appBundleID

    static let motion  = Logger(subsystem: subsystem, category: "Motion")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let ai      = Logger(subsystem: subsystem, category: "AI")
    static let audio   = Logger(subsystem: subsystem, category: "Audio")
    static let business = Logger(subsystem: subsystem, category: "Business")
    static let ui      = Logger(subsystem: subsystem, category: "UI")
    static let data    = Logger(subsystem: subsystem, category: "Data")
    static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")
}
