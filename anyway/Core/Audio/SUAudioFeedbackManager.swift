//
//  SUAudioFeedbackManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import AudioToolbox
import os

/// 提醒提示声音效风格
enum SUAlertSoundStyle: Int, CaseIterable, Sendable {
    case droplet = 0    // 清脆水滴 (1103)
    case woodenFish = 1 // 禅意木鱼 (1057)
    case windChime = 2  // 清爽风铃 (1013)
    case mechanical = 3 // 机械轻按 (1104)

    var displayName: String {
        switch self {
        case .droplet: return SULocalized("sound_style_droplet", default: "清脆水滴")
        case .woodenFish: return SULocalized("sound_style_wooden_fish", default: "禅意木鱼")
        case .windChime: return SULocalized("sound_style_wind_chime", default: "清爽风铃")
        case .mechanical: return SULocalized("sound_style_mechanical", default: "机械轻按")
        }
    }

    var systemSoundId: SystemSoundID {
        switch self {
        case .droplet: return 1103
        case .woodenFish: return 1057
        case .windChime: return 1013
        case .mechanical: return 1104
        }
    }
}

/// 音效与触觉反馈管理器 —— 负责在体态异常、校准成功及恢复挺拔时提供触感与声音提醒
final class SUAudioFeedbackManager: @unchecked Sendable {

    static let shared = SUAudioFeedbackManager()

    private let userDefaultsManager: SUUserDefaultsManager
    private let lock = NSLock()

    private var lastAlertTimestamp: Date?
    private let minAlertInterval: TimeInterval = 15.0 // 相同提示音的最小冷却时间 (秒)

    init(userDefaultsManager: SUUserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
    }

    // MARK: - 触觉反馈
    func triggerHapticWarning() {
        guard userDefaultsManager.isHapticAlertEnabled else { return }
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }

    func triggerHapticSuccess() {
        guard userDefaultsManager.isHapticAlertEnabled else { return }
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    func triggerHapticLightTap() {
        guard userDefaultsManager.isHapticAlertEnabled else { return }
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    func triggerHapticSelection() {
        guard userDefaultsManager.isHapticAlertEnabled else { return }
        DispatchQueue.main.async {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }

    // MARK: - 音频提示
    func playSlumpReminderSound() {
        guard userDefaultsManager.isSoundAlertEnabled else { return }

        lock.lock()
        let now = Date()
        if let last = lastAlertTimestamp, now.timeIntervalSince(last) < minAlertInterval {
            lock.unlock()
            return
        }
        lastAlertTimestamp = now
        lock.unlock()

        let style = SUAlertSoundStyle(rawValue: userDefaultsManager.alertSoundStyle) ?? .droplet
        AudioServicesPlaySystemSound(style.systemSoundId)
        triggerHapticWarning()
        SULogger.lifecycle.info("Played posture slump alert with style: \(style.displayName)")
    }

    func previewSound(style: SUAlertSoundStyle) {
        AudioServicesPlaySystemSound(style.systemSoundId)
        triggerHapticLightTap()
    }

    func playRecoveryChime() {
        guard userDefaultsManager.isSoundAlertEnabled else { return }
        // 1001: Mail sent / positive chime
        AudioServicesPlaySystemSound(1001)
        triggerHapticSuccess()
        SULogger.lifecycle.info("Played posture upright recovery chime")
    }
}
