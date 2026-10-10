//
//  SUCalibrationIntent.swift
//  SpineUpWidgetExtension
//
//  Created by Antigravity on 2026/10/8.
//

import AppIntents
import Foundation
import WidgetKit

/// 桌面小组件快捷一键校准 AppIntent (iOS 26+)
struct SUCalibrationIntent: AppIntent {

    static var title: LocalizedStringResource = LocalizedStringResource("intent_calibration_title", defaultValue: "SpineUp 一键端坐校准")
    static var description = IntentDescription(LocalizedStringResource("intent_calibration_desc", defaultValue: "立即将当前坐姿设置为端正基准零点"))

    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        // 记录触发标记与时间至共享容器
        let sharedDefaults = UserDefaults(suiteName: "group.com.iashes.anyway")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "lastCalibrationTriggerTime")
        sharedDefaults?.set(true, forKey: "su_pendingWidgetCalibration")
        // 立即在小组件共享容器中归零角度与负荷，呈现即时端正反馈
        sharedDefaults?.set(0.0, forKey: "currentPitchDeg")
        sharedDefaults?.set(0.0, forKey: "extraLoadKg")
        sharedDefaults?.set("upright", forKey: "currentPostureState")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
