//
//  SUAudioFeedbackManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import AudioToolbox
import os

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

        // 播放系统清脆的水滴/敲击声 (1103: Tink / 1057: Pop)
        AudioServicesPlaySystemSound(1103)
        triggerHapticWarning()
        SULogger.lifecycle.info("Played posture slump audio/haptic alert")
    }

    func playRecoveryChime() {
        guard userDefaultsManager.isSoundAlertEnabled else { return }
        // 1001: Mail sent / positive chime
        AudioServicesPlaySystemSound(1001)
        triggerHapticSuccess()
        SULogger.lifecycle.info("Played posture upright recovery chime")
    }
}
