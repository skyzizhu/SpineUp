//
//  SUSpeechManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import AVFoundation
import os

/// 语音拟人播报中心 —— 负责高质量 TTS 合成、音频智能避让 (Audio Ducking) 与 3 分钟防疲劳冷却
final class SUSpeechManager: NSObject, @unchecked Sendable, AVSpeechSynthesizerDelegate {

    static let shared = SUSpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    private let userDefaultsManager: SUUserDefaultsManager
    private let lock = NSLock()

    /// 上次语音播报完成时间点（用于严格执行 3 分钟冷却）
    private var lastSpokenTimestamp: Date?

    /// 播报状态回调
    var onSpeechStateChanged: (@Sendable (Bool) -> Void)? // isSpeaking

    init(userDefaultsManager: SUUserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
        super.init()
        self.synthesizer.delegate = self
    }

    /// 当前是否正在发音
    var isSpeaking: Bool {
        return synthesizer.isSpeaking
    }

    /// 检查是否已脱离 3 分钟冷却期
    func canPlayVoiceReminder() -> Bool {
        guard userDefaultsManager.isVoiceAlertEnabled else { return false }
        lock.lock()
        defer { lock.unlock() }

        guard let last = lastSpokenTimestamp else {
            return true
        }

        let elapsed = Date().timeIntervalSince(last)
        return elapsed >= SUAppConfig.voiceReminderCooldownSeconds
    }

    /// 播报台词
    /// - Parameters:
    ///   - text: 台词文本
    ///   - persona: 宠物人格（决定语速、音调）
    ///   - force: 是否无视冷却（例如用户在气泡上主动点击重听，或设置页试听）
    func speak(
        text: String,
        persona: SUPetPersona,
        force: Bool = false
    ) {
        guard !text.isEmpty else { return }

        if !force && !canPlayVoiceReminder() {
            SULogger.audio.info("Voice reminder throttled by 3-minute cooldown")
            return
        }

        // 配置音频会话：使用 .playback 与 .duckOthers，轻柔压低用户正在收听的音乐/播客
        setupAudioSessionForDucking()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = persona.speechRate
        utterance.pitchMultiplier = persona.speechPitchMultiplier
        utterance.volume = 1.0

        // 优先匹配当前系统多语言的发音人
        let currentLocale = Locale.current.identifier
        if let voice = AVSpeechSynthesisVoice(language: currentLocale) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        }

        lock.lock()
        lastSpokenTimestamp = Date()
        lock.unlock()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        synthesizer.speak(utterance)
        SULogger.audio.info("Started speaking reminder for persona: \(persona.displayName, privacy: .public)")
        onSpeechStateChanged?(true)
    }

    /// 停止发音
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        restoreAudioSession()
        onSpeechStateChanged?(false)
    }

    // MARK: - Audio Session Ducking
    private func setupAudioSessionForDucking() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .mixWithOthers]
            )
            try session.setActive(true, options: [])
        } catch {
            SULogger.audio.warning("Failed to configure AVAudioSession ducking: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func restoreAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            SULogger.audio.debug("Failed to deactivate AVAudioSession: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        restoreAudioSession()
        onSpeechStateChanged?(false)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        restoreAudioSession()
        onSpeechStateChanged?(false)
    }
}
