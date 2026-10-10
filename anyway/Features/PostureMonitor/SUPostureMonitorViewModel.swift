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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDidChange),
            name: SULocalizationManager.languageDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleLanguageDidChange() {
        lock.lock()
        latestQuote = nil // 清除缓存的旧语言台词
        let reading = latestReading
        let state = currentPostureState
        let persona = activePersona
        lock.unlock()

        let langCode = SULocalizationManager.shared.currentLanguage.rawValue
        let uprightMins = Int(SUPostureSessionManager.shared.getTodaySession().uprightDurationSec / 60.0)

        // 同步语言偏好至小组件共享容器
        SUWidgetSyncManager.shared.syncLanguagePreference(langCode)
        SUWidgetSyncManager.shared.syncPostureData(
            state: state,
            pitchDeg: reading?.relativePitchDeg ?? 0,
            extraLoadKg: reading?.extraLoadKg ?? 0,
            uprightMinutes: uprightMins,
            personaId: persona.rawValue,
            languageCode: langCode,
            forceReload: true
        )

        // 刷新灵动岛/锁屏状态以显示新语言的默认台词
        SULiveActivityManager.shared.updateLiveActivity(
            state: state.rawValue,
            pitchDeg: reading?.relativePitchDeg ?? 0,
            extraLoadKg: reading?.extraLoadKg ?? 0,
            uprightMinutes: uprightMins,
            personaId: persona.rawValue,
            quote: SULocalized("default_posture_quote", default: "做人要有骨气，端正挺拔中！"),
            forceImmediate: true
        )
    }

    private func setupBindings() {
        // 绑定动作传感器
        motionService.onReadingUpdated = { [weak self] reading in
            guard let self = self else { return }
            self.lock.lock()
            self.latestReading = reading
            self.currentPostureState = reading.state
            let persona = self.activePersona
            let quote = self.latestQuote
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

            let uprightMins = Int(SUPostureSessionManager.shared.getTodaySession().uprightDurationSec / 60.0)

            // 同步小组件 AppGroup 数据
            SUWidgetSyncManager.shared.syncPostureData(
                state: reading.state,
                pitchDeg: reading.relativePitchDeg,
                extraLoadKg: reading.extraLoadKg,
                uprightMinutes: uprightMins,
                personaId: persona.rawValue,
                languageCode: SULocalizationManager.shared.currentLanguage.rawValue
            )

            // 同步更新灵动岛与锁屏实时活动
            SULiveActivityManager.shared.updateLiveActivity(
                state: reading.state.rawValue,
                pitchDeg: reading.relativePitchDeg,
                extraLoadKg: reading.extraLoadKg,
                uprightMinutes: uprightMins,
                personaId: persona.rawValue,
                quote: quote ?? SULocalized("default_posture_quote", default: "做人要有骨气，端正挺拔中！")
            )

            self.onReadingUpdated?(reading)
        }

        motionService.onConnectionStateChanged = { [weak self] state in
            guard let self = self else { return }
            self.lock.lock()
            self.connectionState = state
            let persona = self.activePersona
            self.lock.unlock()

            // 边界问题防护：当耳机处于非工作状态（挂起/未佩戴/未授权/未连接）时，
            // 立即同步灵动岛与小组件为待命挂起状态，杜绝灵动岛滞留虚假挺拔读数
            if !state.isWorking {
                let uprightMins = Int(SUPostureSessionManager.shared.getTodaySession().uprightDurationSec / 60.0)
                let langCode = SULocalizationManager.shared.currentLanguage.rawValue
                SUWidgetSyncManager.shared.syncPostureData(
                    state: .unknown,
                    pitchDeg: 0.0,
                    extraLoadKg: 0.0,
                    uprightMinutes: uprightMins,
                    personaId: persona.rawValue,
                    languageCode: langCode,
                    forceReload: true
                )
                SULiveActivityManager.shared.updateLiveActivity(
                    state: SUPostureState.unknown.rawValue,
                    pitchDeg: 0.0,
                    extraLoadKg: 0.0,
                    uprightMinutes: uprightMins,
                    personaId: persona.rawValue,
                    quote: state.displaySubtitle,
                    forceImmediate: true
                )
            }

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
                guard let self = self else { return }
                self.lock.lock()
                self.isCalibrating = false
                let persona = self.activePersona
                self.lock.unlock()
                self.audioFeedbackManager.triggerHapticSuccess()
                self.onCalibrationFinished?()

                // 校准完成后立即强制同步挺拔0度至小组件与灵动岛
                let uprightMins = Int(SUPostureSessionManager.shared.getTodaySession().uprightDurationSec / 60.0)
                let langCode = SULocalizationManager.shared.currentLanguage.rawValue
                SUWidgetSyncManager.shared.syncPostureData(
                    state: .upright,
                    pitchDeg: 0.0,
                    extraLoadKg: 0.0,
                    uprightMinutes: uprightMins,
                    personaId: persona.rawValue,
                    languageCode: langCode,
                    forceReload: true
                )
                SULiveActivityManager.shared.updateLiveActivity(
                    state: SUPostureState.upright.rawValue,
                    pitchDeg: 0.0,
                    extraLoadKg: 0.0,
                    uprightMinutes: uprightMins,
                    personaId: persona.rawValue,
                    quote: SULocalized("default_posture_quote", default: "做人要有骨气，端正挺拔中！"),
                    forceImmediate: true
                )
            }
        }

        // 监听人格切换
        personaManager.onPersonaChanged = { [weak self] persona in
            guard let self = self else { return }
            self.lock.lock()
            self.activePersona = persona
            let reading = self.latestReading
            let state = self.currentPostureState
            let quote = self.latestQuote
            self.lock.unlock()
            self.onPersonaChanged?(persona)

            let uprightMins = Int(SUPostureSessionManager.shared.getTodaySession().uprightDurationSec / 60.0)
            let langCode = SULocalizationManager.shared.currentLanguage.rawValue
            SUWidgetSyncManager.shared.syncPostureData(
                state: state,
                pitchDeg: reading?.relativePitchDeg ?? 0,
                extraLoadKg: reading?.extraLoadKg ?? 0,
                uprightMinutes: uprightMins,
                personaId: persona.rawValue,
                languageCode: langCode,
                forceReload: true
            )
            SULiveActivityManager.shared.updateLiveActivity(
                state: state.rawValue,
                pitchDeg: reading?.relativePitchDeg ?? 0,
                extraLoadKg: reading?.extraLoadKg ?? 0,
                uprightMinutes: uprightMins,
                personaId: persona.rawValue,
                quote: quote ?? SULocalized("default_posture_quote", default: "做人要有骨气，端正挺拔中！"),
                forceImmediate: true
            )
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
        SULiveActivityManager.shared.startLiveActivity(
            initialQuote: latestQuote ?? SULocalized("default_posture_quote", default: "做人要有骨气，端正挺拔中！"),
            personaId: activePersona.rawValue
        )
    }

    func stopMonitoring() {
        motionService.stopMonitoring()
        SULiveActivityManager.shared.endLiveActivity()
        SUPostureSessionManager.shared.saveSession()
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

    /// 请求耳机运动权限或引导设置
    func requestMotionAuthorization(completion: (@Sendable (Bool) -> Void)? = nil) {
        motionService.requestMotionAuthorization(completion: completion)
    }

    /// 供模拟器调试注入耳机连接状态
    func injectSimulatedConnectionState(_ state: SUHeadphoneConnectionState) {
        if let mock = motionService as? SUMockMotionManager {
            mock.setSimulatedConnectionState(state)
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
