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
}
