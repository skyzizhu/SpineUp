//
//  SUUserDefaultsManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// UserDefaults 轻量级偏好配置管理中心 —— 统一持久化校准零点、Onboarding 状态与用户开关
final class SUUserDefaultsManager: @unchecked Sendable {

    static let shared = SUUserDefaultsManager()

    private let defaults: UserDefaults
    private let lock = NSLock()

    private enum Keys {
        static let hasCompletedOnboarding = "su_hasCompletedOnboarding"
        static let isCalibrated = "su_isCalibrated"
        static let calibrationBasePitch = "su_calibrationBasePitch"
        static let calibrationBaseRoll = "su_calibrationBaseRoll"
        static let activePetPersonaId = "su_activePetPersonaId"
        static let slightSlumpThreshold = "su_slightSlumpThreshold"
        static let severeSlumpThreshold = "su_severeSlumpThreshold"
        static let isSoundAlertEnabled = "su_isSoundAlertEnabled"
        static let isHapticAlertEnabled = "su_isHapticAlertEnabled"
        static let isVoiceAlertEnabled = "su_isVoiceAlertEnabled"
        static let spineEnergyCoins = "su_spineEnergyCoins"
        static let streakDays = "su_streakDays"
        static let lastActiveDateString = "su_lastActiveDateString"
        static let customApiBaseURL = "su_customApiBaseURL"
        static let authToken = "su_authToken"
        static let userName = "su_userName"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Onboarding 引导流状态
    var hasCompletedOnboarding: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
            lock.unlock()
        }
    }

    // MARK: - 坐姿校准基准零点 (Neutral Baseline)
    var isCalibrated: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: Keys.isCalibrated)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.isCalibrated)
            lock.unlock()
        }
    }

    var calibrationBasePitch: Double {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.double(forKey: Keys.calibrationBasePitch)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.calibrationBasePitch)
            lock.unlock()
        }
    }

    var calibrationBaseRoll: Double {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.double(forKey: Keys.calibrationBaseRoll)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.calibrationBaseRoll)
            lock.unlock()
        }
    }

    func saveCalibrationBaseline(pitch: Double, roll: Double) {
        lock.lock()
        defaults.set(pitch, forKey: Keys.calibrationBasePitch)
        defaults.set(roll, forKey: Keys.calibrationBaseRoll)
        defaults.set(true, forKey: Keys.isCalibrated)
        lock.unlock()
    }

    func clearCalibration() {
        lock.lock()
        defaults.removeObject(forKey: Keys.calibrationBasePitch)
        defaults.removeObject(forKey: Keys.calibrationBaseRoll)
        defaults.set(false, forKey: Keys.isCalibrated)
        lock.unlock()
    }

    // MARK: - 阈值偏好配置
    var slightSlumpThreshold: Double {
        get {
            lock.lock()
            defer { lock.unlock() }
            let val = defaults.double(forKey: Keys.slightSlumpThreshold)
            return val > 0 ? val : SUMotionConstants.slightSlumpAngleThreshold
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.slightSlumpThreshold)
            lock.unlock()
        }
    }

    var severeSlumpThreshold: Double {
        get {
            lock.lock()
            defer { lock.unlock() }
            let val = defaults.double(forKey: Keys.severeSlumpThreshold)
            return val > 0 ? val : SUMotionConstants.severeSlumpAngleThreshold
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.severeSlumpThreshold)
            lock.unlock()
        }
    }

    // MARK: - 提醒开关
    var isSoundAlertEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            // 默认开启
            if defaults.object(forKey: Keys.isSoundAlertEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.isSoundAlertEnabled)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.isSoundAlertEnabled)
            lock.unlock()
        }
    }

    var isHapticAlertEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            if defaults.object(forKey: Keys.isHapticAlertEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.isHapticAlertEnabled)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.isHapticAlertEnabled)
            lock.unlock()
        }
    }

    var isVoiceAlertEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            if defaults.object(forKey: Keys.isVoiceAlertEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.isVoiceAlertEnabled)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.isVoiceAlertEnabled)
            lock.unlock()
        }
    }

    // MARK: - 骨气能量与打卡系统 (Spine Energy & Streak)
    var spineEnergyCoins: Int {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.integer(forKey: Keys.spineEnergyCoins)
        }
        set {
            lock.lock()
            defaults.set(max(0, newValue), forKey: Keys.spineEnergyCoins)
            lock.unlock()
        }
    }

    func addSpineEnergyCoins(_ amount: Int) {
        lock.lock()
        let current = defaults.integer(forKey: Keys.spineEnergyCoins)
        defaults.set(max(0, current + amount), forKey: Keys.spineEnergyCoins)
        lock.unlock()
    }

    var streakDays: Int {
        get {
            lock.lock()
            defer { lock.unlock() }
            let val = defaults.integer(forKey: Keys.streakDays)
            return max(1, val)
        }
        set {
            lock.lock()
            defaults.set(max(1, newValue), forKey: Keys.streakDays)
            lock.unlock()
        }
    }

    var lastActiveDateString: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.string(forKey: Keys.lastActiveDateString)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.lastActiveDateString)
            lock.unlock()
        }
    }

    // MARK: - 当前选中的宠物人格
    var activePetPersonaId: String {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.string(forKey: Keys.activePetPersonaId) ?? "worker" // 默认打工人
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.activePetPersonaId)
            lock.unlock()
        }
    }

    // MARK: - 用户个人资料与排行榜昵称
    var userName: String {
        get {
            lock.lock()
            defer { lock.unlock() }
            if let saved = defaults.string(forKey: Keys.userName), !saved.isEmpty {
                return saved
            }
            return SULocalized("default_user_name", default: "挺拔打工人")
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: Keys.userName)
            lock.unlock()
        }
    }

    // MARK: - 网络配置与用户令牌
    var customApiBaseURL: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.string(forKey: Keys.customApiBaseURL)
        }
        set {
            lock.lock()
            if let val = newValue, !val.isEmpty {
                defaults.set(val, forKey: Keys.customApiBaseURL)
            } else {
                defaults.removeObject(forKey: Keys.customApiBaseURL)
            }
            lock.unlock()
        }
    }

    var authToken: String? {
        get {
            if let token = SUKeychainManager.shared.authToken, !token.isEmpty {
                return token
            }
            lock.lock()
            defer { lock.unlock() }
            return defaults.string(forKey: Keys.authToken)
        }
        set {
            SUKeychainManager.shared.authToken = newValue
            lock.lock()
            if let val = newValue, !val.isEmpty {
                defaults.set(val, forKey: Keys.authToken)
            } else {
                defaults.removeObject(forKey: Keys.authToken)
            }
            lock.unlock()
        }
    }
}
