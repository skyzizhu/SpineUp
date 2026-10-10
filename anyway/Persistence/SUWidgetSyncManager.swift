//
//  SUWidgetSyncManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import Foundation
import WidgetKit

/// 桌面小组件与共享容器数据同步管理器 —— 负责跨进程 App Group 姿态数据写入、力学模型对齐与 WidgetKit 刷新调度
final class SUWidgetSyncManager: @unchecked Sendable {

    static let shared = SUWidgetSyncManager()

    static let appGroupSuiteName = "group.com.iashes.anyway"

    private let sharedDefaults: UserDefaults?
    private let lock = NSLock()

    private var lastWidgetReloadUptime: TimeInterval = 0
    private var lastSyncedState: String = ""

    enum Keys {
        static let currentPitchDeg = "currentPitchDeg"
        static let currentPostureState = "currentPostureState"
        static let todayUprightMinutes = "todayUprightMinutes"
        static let currentPersonaId = "currentPersonaId"
        static let extraLoadKg = "extraLoadKg"
        static let lastUpdateTime = "lastUpdateTime"
        static let pendingWidgetCalibration = "su_pendingWidgetCalibration"
        static let lastCalibrationTriggerTime = "lastCalibrationTriggerTime"
        static let appLanguageCode = "su_appLanguageCode"
    }

    private init() {
        self.sharedDefaults = UserDefaults(suiteName: Self.appGroupSuiteName) ?? .standard
    }

    /// 同步主 App 姿态数据至小组件共享容器，并按需调度 WidgetCenter 刷新
    /// - Parameters:
    ///   - state: 当前体态状态
    ///   - pitchDeg: 相对前倾角度（度）
    ///   - extraLoadKg: 额外颈椎负荷（千克）
    ///   - uprightMinutes: 今日累计挺拔分钟数
    ///   - personaId: 当前桌宠人格代号
    ///   - languageCode: 当前语言代号
    ///   - forceReload: 是否强制刷新小组件时间线
    func syncPostureData(
        state: SUPostureState,
        pitchDeg: Double,
        extraLoadKg: Double,
        uprightMinutes: Int,
        personaId: String,
        languageCode: String? = nil,
        forceReload: Bool = false
    ) {
        lock.lock()
        defer { lock.unlock() }

        guard let defaults = sharedDefaults else { return }

        let stateStr = state.rawValue
        let stateChanged = (lastSyncedState != stateStr)
        if stateChanged {
            lastSyncedState = stateStr
        }

        defaults.set(pitchDeg, forKey: Keys.currentPitchDeg)
        defaults.set(stateStr, forKey: Keys.currentPostureState)
        defaults.set(uprightMinutes, forKey: Keys.todayUprightMinutes)
        defaults.set(personaId, forKey: Keys.currentPersonaId)
        defaults.set(extraLoadKg, forKey: Keys.extraLoadKg)
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastUpdateTime)

        if let lang = languageCode {
            defaults.set(lang, forKey: Keys.appLanguageCode)
        }

        // WidgetKit 刷新调度策略（兼顾实时性与系统 Timeline 预算）：
        // 1. 状态跃迁（如挺拔 -> 前倾 -> 严重驼背）：立即触发 WidgetCenter 刷新
        // 2. 强制触发（校准、切人格、改语言）：立即触发刷新
        // 3. 常规持续状态：间隔至少 45 秒允许刷新一次，保证分钟数递增能够上屏
        let now = ProcessInfo.processInfo.systemUptime
        if forceReload || stateChanged || (now - lastWidgetReloadUptime >= 45.0) {
            lastWidgetReloadUptime = now
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 同步当前选中的语言至小组件
    func syncLanguagePreference(_ languageCode: String) {
        lock.lock()
        defer { lock.unlock() }

        sharedDefaults?.set(languageCode, forKey: Keys.appLanguageCode)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 检查并消费来自小组件的快捷校准指令
    func checkAndConsumePendingCalibration() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let defaults = sharedDefaults else { return false }
        let isPending = defaults.bool(forKey: Keys.pendingWidgetCalibration)
        if isPending {
            defaults.set(false, forKey: Keys.pendingWidgetCalibration)
            return true
        }
        return false
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let suRequestCalibrationFromWidget = Notification.Name("suRequestCalibrationFromWidget")
}

