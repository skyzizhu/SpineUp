//
//  SUSettingsViewModel.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 设置页 ViewModel —— 严格遵循 MVVM 规范，无 UIKit 依赖
final class SUSettingsViewModel: @unchecked Sendable {

    private let userDefaultsManager: SUUserDefaultsManager
    private let personaManager: SUPetPersonaManager
    private let speechManager: SUSpeechManager
    private let energyManager: SUSpineEnergyManager
    private let audioFeedbackManager: SUAudioFeedbackManager

    private let lock = NSLock()

    // MARK: - 状态 Outputs
    private(set) var activePersona: SUPetPersona
    private(set) var isVoiceAlertEnabled: Bool
    private(set) var isHapticAlertEnabled: Bool
    private(set) var isSoundAlertEnabled: Bool
    private(set) var totalCoins: Int
    private(set) var streakDays: Int

    // MARK: - 回调
    var onStateChanged: (@Sendable () -> Void)?

    init(
        userDefaultsManager: SUUserDefaultsManager = .shared,
        personaManager: SUPetPersonaManager = .shared,
        speechManager: SUSpeechManager = .shared,
        energyManager: SUSpineEnergyManager = .shared,
        audioFeedbackManager: SUAudioFeedbackManager = .shared
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.personaManager = personaManager
        self.speechManager = speechManager
        self.energyManager = energyManager
        self.audioFeedbackManager = audioFeedbackManager

        self.activePersona = personaManager.currentPersona
        self.isVoiceAlertEnabled = userDefaultsManager.isVoiceAlertEnabled
        self.isHapticAlertEnabled = userDefaultsManager.isHapticAlertEnabled
        self.isSoundAlertEnabled = userDefaultsManager.isSoundAlertEnabled
        self.totalCoins = energyManager.totalCoins
        self.streakDays = energyManager.streakDays
    }

    var availablePersonas: [SUPetPersona] {
        return personaManager.availablePersonas
    }

    func selectPersona(_ persona: SUPetPersona) {
        lock.lock()
        self.activePersona = persona
        lock.unlock()

        personaManager.selectPersona(persona)
        audioFeedbackManager.triggerHapticSelection()

        // 切换时播放该人格的专属欢迎试听语
        let previewText: String
        switch persona {
        case .worker:
            previewText = "打工人人格已就位，准备好迎接扎心提醒了吗？"
        case .cat:
            previewText = "喵呜！傲娇猫猫已上线，不许再把本喵压扁了喵！"
        case .coach:
            previewText = "温柔私教已连接，让我们一起保持挺拔与深呼吸。"
        }
        speechManager.speak(text: previewText, persona: persona, force: true)

        onStateChanged?()
    }

    func setVoiceAlertEnabled(_ enabled: Bool) {
        lock.lock()
        isVoiceAlertEnabled = enabled
        lock.unlock()
        userDefaultsManager.isVoiceAlertEnabled = enabled
        audioFeedbackManager.triggerHapticLightTap()
        onStateChanged?()
    }

    func setHapticAlertEnabled(_ enabled: Bool) {
        lock.lock()
        isHapticAlertEnabled = enabled
        lock.unlock()
        userDefaultsManager.isHapticAlertEnabled = enabled
        audioFeedbackManager.triggerHapticLightTap()
        onStateChanged?()
    }

    func setSoundAlertEnabled(_ enabled: Bool) {
        lock.lock()
        isSoundAlertEnabled = enabled
        lock.unlock()
        userDefaultsManager.isSoundAlertEnabled = enabled
        audioFeedbackManager.triggerHapticLightTap()
        onStateChanged?()
    }

    func refreshEnergyData() {
        lock.lock()
        totalCoins = energyManager.totalCoins
        streakDays = energyManager.streakDays
        lock.unlock()
        onStateChanged?()
    }
}
