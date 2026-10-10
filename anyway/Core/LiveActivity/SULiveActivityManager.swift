//
//  SULiveActivityManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import ActivityKit
import os

/// 灵动岛与锁屏实时活动生命周期管理器 —— 统一管理启动、实时更新与结束活动
final class SULiveActivityManager: @unchecked Sendable {

    static let shared = SULiveActivityManager()

    private let lock = NSLock()
    private var currentActivity: Activity<SUPostureActivityAttributes>?

    private init() {}

    /// 当前设备是否支持并开启了 Live Activity
    var areActivitiesEnabled: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// 启动实时活动
    /// - Parameters:
    ///   - initialQuote: 初始欢迎台词
    ///   - personaId: 当前激活人格
    func startLiveActivity(initialQuote: String, personaId: String) {
        guard areActivitiesEnabled else {
            SULogger.lifecycle.info("Live Activities are not enabled on this device/environment")
            return
        }

        lock.lock()
        if currentActivity != nil {
            lock.unlock()
            return
        }
        lock.unlock()

        let attributes = SUPostureActivityAttributes(sessionTitle: "SpineUp 实时守护")
        let initialState = SUPostureActivityAttributes.ContentState(
            postureState: "upright",
            pitchDeg: 0.0,
            extraLoadKg: 0.0,
            uprightMinutes: 0,
            personaId: personaId,
            quote: initialQuote
        )

        do {
            let content = ActivityContent(state: initialState, staleDate: nil)
            let activity = try Activity.request(attributes: attributes, content: content)
            lock.lock()
            self.currentActivity = activity
            lock.unlock()
            SULogger.lifecycle.info("Started Live Activity with ID: \(activity.id, privacy: .public)")
        } catch {
            SULogger.lifecycle.warning("Failed to start Live Activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    private var lastState: String?
    private var lastPersonaId: String?
    private var lastPitchDeg: Double = 0.0
    private var lastUprightMinutes: Int = -1
    private var lastUpdateTime: TimeInterval = 0

    /// 更新当前实时活动状态
    func updateLiveActivity(
        state: String,
        pitchDeg: Double,
        extraLoadKg: Double,
        uprightMinutes: Int,
        personaId: String,
        quote: String,
        forceImmediate: Bool = false
    ) {
        lock.lock()
        guard let activity = currentActivity else {
            lock.unlock()
            return
        }

        let isStateTransition = (lastState != state)
        let isPersonaChanged = (lastPersonaId != personaId)
        let isMinutesChanged = (lastUprightMinutes != uprightMinutes)
        let pitchDelta = abs(pitchDeg - lastPitchDeg)
        let now = ProcessInfo.processInfo.systemUptime
        let timeElapsed = now - lastUpdateTime

        // 智能节流防抖控制（关键实时性与系统预算防护）：
        // 1. 状态跃迁（挺拔 -> 前倾 -> 严重驼背 -> 恢复挺拔）：立即无延迟推送（0ms 响应）
        // 2. 人格改变或强制刷新：立即无延迟推送
        // 3. 稳定状态内：至少间隔 1.5 秒，且角度变化 >= 1.0° 或分钟数递增才提交刷新
        // 彻底杜绝每秒 15 次高频调用耗尽 iOS ActivityKit 预算导致灵动岛卡死不更新的严重问题
        if !forceImmediate && !isStateTransition && !isPersonaChanged {
            guard timeElapsed >= 1.5 && (pitchDelta >= 1.0 || isMinutesChanged) else {
                lock.unlock()
                return
            }
        }

        lastState = state
        lastPersonaId = personaId
        lastPitchDeg = pitchDeg
        lastUprightMinutes = uprightMinutes
        lastUpdateTime = now
        lock.unlock()

        let updatedState = SUPostureActivityAttributes.ContentState(
            postureState: state,
            pitchDeg: pitchDeg,
            extraLoadKg: extraLoadKg,
            uprightMinutes: uprightMinutes,
            personaId: personaId,
            quote: quote
        )

        let isSevere = (state == "severeSlump")
        let alertConfig: AlertConfiguration?
        if isSevere {
            let title = SULocalized("state_severe_slump", default: "严重驼背预警")
            let body = SULocalized("gauge_status_severe", default: "高危超负荷 · 请立刻抬头")
            alertConfig = AlertConfiguration(title: LocalizedStringResource(stringLiteral: title), body: LocalizedStringResource(stringLiteral: body), sound: .default)
        } else {
            alertConfig = nil
        }

        Task {
            let content = ActivityContent(
                state: updatedState,
                staleDate: nil,
                relevanceScore: isSevere ? 100.0 : 1.0
            )
            await activity.update(content, alertConfiguration: alertConfig)
            SULogger.lifecycle.debug("Updated Live Activity: state=\(state)")
        }
    }

    /// 结束当前实时活动
    func endLiveActivity() {
        lock.lock()
        guard let activity = currentActivity else {
            lock.unlock()
            return
        }
        self.currentActivity = nil
        lock.unlock()

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            SULogger.lifecycle.info("Ended Live Activity successfully")
        }
    }
}
