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

    /// 更新当前实时活动状态
    func updateLiveActivity(
        state: String,
        pitchDeg: Double,
        extraLoadKg: Double,
        uprightMinutes: Int,
        personaId: String,
        quote: String
    ) {
        lock.lock()
        guard let activity = currentActivity else {
            lock.unlock()
            return
        }
        lock.unlock()

        let updatedState = SUPostureActivityAttributes.ContentState(
            postureState: state,
            pitchDeg: pitchDeg,
            extraLoadKg: extraLoadKg,
            uprightMinutes: uprightMinutes,
            personaId: personaId,
            quote: quote
        )

        Task {
            let content = ActivityContent(state: updatedState, staleDate: nil)
            await activity.update(content)
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
