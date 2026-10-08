//
//  SUSpineEnergyManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 骨气能量养成系统中心 —— 追踪挺拔时长、自动累积能量币与连续坚持打卡天数
final class SUSpineEnergyManager: @unchecked Sendable {

    static let shared = SUSpineEnergyManager()

    private let userDefaultsManager: SUUserDefaultsManager
    private let lock = NSLock()

    /// 当前会话累积的未结算挺拔秒数
    private var pendingUprightSeconds: TimeInterval = 0.0

    /// 今日会话已赚取的能量币
    private(set) var earnedTodayCoins: Int = 0

    /// 能量变动通知回调 (totalCoins, earnedToday)
    var onEnergyUpdated: (@Sendable (Int, Int) -> Void)?

    init(userDefaultsManager: SUUserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
        checkAndUpdateDailyStreak()
    }

    /// 累计能量币总数
    var totalCoins: Int {
        return userDefaultsManager.spineEnergyCoins
    }

    /// 连续打卡天数
    var streakDays: Int {
        return userDefaultsManager.streakDays
    }

    /// 接收监测帧更新：若当前为端正挺拔态，则累加时长并按规则结算能量币
    /// - Parameter deltaSeconds: 距离上一帧的时间间隔（例如 1/15 秒）
    func trackUprightFrame(deltaSeconds: TimeInterval) {
        lock.lock()
        pendingUprightSeconds += deltaSeconds

        // 每挺拔满 60 秒，铸造 1 枚骨气能量币（结合 Streak 加成系数）
        if pendingUprightSeconds >= 60.0 {
            pendingUprightSeconds -= 60.0

            let baseCoin = Double(SUAppConfig.energyPointsPerMinuteUpright)
            let streakMultiplier = streakDays > 1 ? SUAppConfig.streakBonusMultiplier : 1.0
            let mintedCoins = max(1, Int(round(baseCoin * streakMultiplier)))

            userDefaultsManager.addSpineEnergyCoins(mintedCoins)
            earnedTodayCoins += mintedCoins

            let newTotal = userDefaultsManager.spineEnergyCoins
            let currentEarned = earnedTodayCoins
            lock.unlock()

            SULogger.business.info("Minted \(mintedCoins) spine energy coin(s). Total: \(newTotal)")
            onEnergyUpdated?(newTotal, currentEarned)
            return
        }

        lock.unlock()
    }

    /// 中断重置未结算挺拔秒数（例如发生低头或取下耳机）
    func resetPendingProgress() {
        lock.lock()
        pendingUprightSeconds = 0.0
        lock.unlock()
    }

    /// 检查并刷新每日坚持连续天数 (Streak)
    private func checkAndUpdateDailyStreak() {
        lock.lock()
        defer { lock.unlock() }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())

        guard let lastActiveStr = userDefaultsManager.lastActiveDateString else {
            // 首次启动
            userDefaultsManager.lastActiveDateString = todayStr
            userDefaultsManager.streakDays = 1
            return
        }

        if lastActiveStr == todayStr {
            // 今天已记录，无需重复增加
            return
        }

        guard let lastDate = formatter.date(from: lastActiveStr),
              let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            userDefaultsManager.lastActiveDateString = todayStr
            userDefaultsManager.streakDays = 1
            return
        }

        let yesterdayStr = formatter.string(from: yesterday)
        if lastActiveStr == yesterdayStr {
            // 连续坚持打卡
            userDefaultsManager.streakDays += 1
            SULogger.business.info("Streak increased to \(self.userDefaultsManager.streakDays) day(s)!")
        } else {
            // 中断，重置为 1
            userDefaultsManager.streakDays = 1
        }

        userDefaultsManager.lastActiveDateString = todayStr
    }
}
