//
//  SUCalibrationIntent.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import AppIntents
import Foundation

/// 桌面小组件与快捷指令一键校准 Intent
struct SUCalibrationIntent: AppIntent {

    static var title: LocalizedStringResource = "SpineUp 一键端坐校准"
    static var description = IntentDescription("立即将当前坐姿设置为端正基准零点")

    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        // 执行校准逻辑
        SUCalibrationService.shared.calibrateImmediately(pitchRad: 0.0, rollRad: 0.0)
        return .result()
    }
}
