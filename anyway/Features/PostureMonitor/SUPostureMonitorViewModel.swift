//
//  SUPostureMonitorViewModel.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// PostureMonitor 业务逻辑 ViewModel —— 严格遵循 MVVM 规范，不引用 UIKit 视图库
final class SUPostureMonitorViewModel: @unchecked Sendable {

    private let motionService: SUMotionServiceProtocol
    private let audioFeedbackManager: SUAudioFeedbackManager
    private let userDefaultsManager: SUUserDefaultsManager
    private let personaManager: SUPetPersonaManager
    private let aiService: SUAIService
    private let speechManager: SUSpeechManager
    private let energyManager: SUSpineEnergyManager

    private let lock = NSLock()

    // MARK: - 状态 Outputs
    private(set) var latestReading: SUPostureReading?
    private(set) var connectionState: SUHeadphoneConnectionState = .disconnected
    private(set) var currentPostureState: SUPostureState = .upright
    private(set) var isCalibrating: Bool = false
    private(set) var activePersona: SUPetPersona = .worker
    private(set) var latestQuote: String?
    private(set) var todayViolationsCount: Int = 0

    // MARK: - 回调绑定
    var onReadingUpdated: (@Sendable (SUPostureReading) -> Void)?
    var onConnectionStateChanged: (@Sendable (SUHeadphoneConnectionState) -> Void)?
    var onPostureStateChanged: (@Sendable (SUPostureState) -> Void)?
    var onCalibrationProgress: (@Sendable (Double) -> Void)?
    var onCalibrationFinished: (@Sendable () -> Void)?
    var onQuoteUpdated: (@Sendable (String, SUPetPersona) -> Void)?
    var onEnergyUpdated: (@Sendable (Int, Int) -> Void)?
    var onPersonaChanged: (@Sendable (SUPetPersona) -> Void)?

    init(
        motionService: SUMotionServiceProtocol? = nil,
        audioFeedbackManager: SUAudioFeedbackManager = .shared,
        userDefaultsManager: SUUserDefaultsManager = .shared,
        personaManager: SUPetPersonaManager = .shared,
        aiService: SUAIService = .shared,
        speechManager: SUSpeechManager = .shared,
        energyManager: SUSpineEnergyManager = .shared
    ) {
        #if targetEnvironment(simulator)
        self.motionService = motionService ?? SUMockMotionManager()
        #else
        self.motionService = motionService ?? SUHeadphoneMotionManager()
        #endif
        self.audioFeedbackManager = audioFeedbackManager
        self.userDefaultsManager = userDefaultsManager
        self.personaManager = personaManager
        self.aiService = aiService
        self.speechManager = speechManager
        self.energyManager = energyManager

        self.activePersona = personaManager.currentPersona

        setupBindings()
    }

    private func setupBindings() {
        // 绑定动作传感器
        motionService.onReadingUpdated = { [weak self] reading in
            guard let self = self else { return }
            self.lock.lock()
            self.latestReading = reading
            self.currentPostureState = reading.state
            self.lock.unlock()

            // 端坐状态下每帧累加挺拔能量
            if reading.state == .upright {
                self.energyManager.trackUprightFrame(deltaSeconds: 1.0 / 15.0)
            }

            // 实时记录到每日会话持久化引擎中
            SUPostureSessionManager.shared.recordFrame(
                state: reading.state,
                pitchDeg: reading.relativePitchDeg,
                deltaSeconds: 1.0 / 15.0
            )

            self.onReadingUpdated?(reading)
        }

        motionService.onConnectionStateChanged = { [weak self] state in
            guard let self = self else { return }
            self.lock.lock()
            self.connectionState = state
            self.lock.unlock()

            self.onConnectionStateChanged?(state)
        }

        motionService.onPostureStateChanged = { [weak self] oldState, newState in
            guard let self = self else { return }
            self.lock.lock()
            self.currentPostureState = newState
            if newState == .slightSlump || newState == .severeSlump {
                self.todayViolationsCount += 1
                SUPostureSessionManager.shared.recordViolation()
            }
            let violations = self.todayViolationsCount
            let persona = self.activePersona
            let reading = self.latestReading
            self.lock.unlock()

            // 触发音效与触觉反馈
            if newState == .slightSlump || newState == .severeSlump {
                self.audioFeedbackManager.playSlumpReminderSound()
                self.energyManager.resetPendingProgress()

                // 异步调度 AI 生成吐槽台词并播报
                Task { [weak self] in
                    guard let self = self else { return }
                    let context = SUPostureContext(
                        angleDeg: reading?.relativePitchDeg ?? 20.0,
                        durationSec: 10.0,
                        violationCountToday: violations,
                        currentTime: Date(),
                        persona: persona,
                        streakDays: self.energyManager.streakDays,
                        state: newState,
                        extraLoadKg: reading?.extraLoadKg ?? 12.0
                    )

                    let quote = await self.aiService.generateReminder(context: context)
                    self.updateQuoteState(quote)

                    self.onQuoteUpdated?(quote, persona)

                    // 若开启语音提醒，则播报台词（受 3 分钟冷却控制）
                    if self.userDefaultsManager.isVoiceAlertEnabled {
                        self.speechManager.speak(text: quote, persona: persona, force: false)
                    }
                }
            } else if oldState != .upright && newState == .upright {
                self.audioFeedbackManager.playRecoveryChime()

                // 挺拔鼓励台词
                Task { [weak self] in
                    guard let self = self else { return }
                    let context = SUPostureContext(
                        angleDeg: 0.0,
                        durationSec: 5.0,
                        violationCountToday: violations,
                        currentTime: Date(),
                        persona: persona,
                        streakDays: self.energyManager.streakDays,
                        state: .upright,
                        extraLoadKg: 0.0
                    )

                    let encouragement = await self.aiService.generateReminder(context: context)
                    self.updateQuoteState(encouragement)

                    self.onQuoteUpdated?(encouragement, persona)
                }
            }

            self.onPostureStateChanged?(newState)
        }

        motionService.onCalibrationProgress = { [weak self] progress in
            self?.onCalibrationProgress?(progress)
            if progress >= 1.0 {
                self?.lock.lock()
                self?.isCalibrating = false
                self?.lock.unlock()
                self?.audioFeedbackManager.triggerHapticSuccess()
                self?.onCalibrationFinished?()
            }
        }

        // 监听人格切换
        personaManager.onPersonaChanged = { [weak self] persona in
            guard let self = self else { return }
            self.lock.lock()
            self.activePersona = persona
            self.lock.unlock()
            self.onPersonaChanged?(persona)
        }

        // 监听能量更新
        energyManager.onEnergyUpdated = { [weak self] total, today in
            self?.onEnergyUpdated?(total, today)
        }
    }

    private func updateQuoteState(_ quote: String) {
        lock.lock()
        latestQuote = quote
        lock.unlock()
    }

    // MARK: - 页面业务 Actions
    func startMonitoring() {
        motionService.startMonitoring()
    }

    func stopMonitoring() {
        motionService.stopMonitoring()
    }

    func startCalibration() {
        lock.lock()
        isCalibrating = true
        lock.unlock()

        audioFeedbackManager.triggerHapticLightTap()
        motionService.calibrateBaseline()
    }

    /// 用户点击台词气泡重听语音（无视 3 分钟冷却）
    func replayCurrentQuote() {
        lock.lock()
        guard let quote = latestQuote, !quote.isEmpty else {
            lock.unlock()
            return
        }
        let persona = activePersona
        lock.unlock()

        audioFeedbackManager.triggerHapticLightTap()
        speechManager.speak(text: quote, persona: persona, force: true)
    }

    /// 供模拟器调试滑块注入倾斜度
    func injectSimulatedAngles(pitchDeg: Double, rollDeg: Double) {
        if let mock = motionService as? SUMockMotionManager {
            mock.injectSimulatedAngles(pitchDeg: pitchDeg, rollDeg: rollDeg)
        }
    }

    // MARK: - 能量与人格数据读取
    var currentTotalEnergyCoins: Int {
        return energyManager.totalCoins
    }

    var currentEarnedTodayCoins: Int {
        return energyManager.earnedTodayCoins
    }

    var currentStreakDays: Int {
        return energyManager.streakDays
    }
}
