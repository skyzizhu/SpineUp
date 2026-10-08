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

    private let lock = NSLock()

    // MARK: - 状态 Outputs
    private(set) var latestReading: SUPostureReading?
    private(set) var connectionState: SUHeadphoneConnectionState = .disconnected
    private(set) var currentPostureState: SUPostureState = .upright
    private(set) var isCalibrating: Bool = false

    // MARK: - 回调绑定
    var onReadingUpdated: (@Sendable (SUPostureReading) -> Void)?
    var onConnectionStateChanged: (@Sendable (SUHeadphoneConnectionState) -> Void)?
    var onPostureStateChanged: (@Sendable (SUPostureState) -> Void)?
    var onCalibrationProgress: (@Sendable (Double) -> Void)?
    var onCalibrationFinished: (@Sendable () -> Void)?

    init(
        motionService: SUMotionServiceProtocol? = nil,
        audioFeedbackManager: SUAudioFeedbackManager = .shared,
        userDefaultsManager: SUUserDefaultsManager = .shared
    ) {
        #if targetEnvironment(simulator)
        self.motionService = motionService ?? SUMockMotionManager()
        #else
        self.motionService = motionService ?? SUHeadphoneMotionManager()
        #endif
        self.audioFeedbackManager = audioFeedbackManager
        self.userDefaultsManager = userDefaultsManager

        setupMotionBindings()
    }

    private func setupMotionBindings() {
        motionService.onReadingUpdated = { [weak self] reading in
            guard let self = self else { return }
            self.lock.lock()
            self.latestReading = reading
            self.currentPostureState = reading.state
            self.lock.unlock()

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
            self.lock.unlock()

            // 触发音效与触觉反馈
            if newState == .slightSlump || newState == .severeSlump {
                self.audioFeedbackManager.playSlumpReminderSound()
            } else if oldState != .upright && newState == .upright {
                self.audioFeedbackManager.playRecoveryChime()
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

    /// 供模拟器调试滑块注入倾斜度
    func injectSimulatedAngles(pitchDeg: Double, rollDeg: Double) {
        if let mock = motionService as? SUMockMotionManager {
            mock.injectSimulatedAngles(pitchDeg: pitchDeg, rollDeg: rollDeg)
        }
    }
}
