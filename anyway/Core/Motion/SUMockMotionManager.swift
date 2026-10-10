//
//  SUMockMotionManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 模拟器/测试用 Mock 传感器管理器 —— 结合校准服务与状态机引擎，支持外部实时注入角度
final class SUMockMotionManager: SUMotionServiceProtocol, @unchecked Sendable {

    private(set) var connectionState: SUHeadphoneConnectionState = .connected
    var currentPostureState: SUPostureState {
        stateEngine.currentState
    }

    private let calibrationService: SUCalibrationService
    private let stateEngine: SUPostureStateEngine

    private var basePitchRad: Double = 0.0
    private var baseRollRad: Double = 0.0

    private var currentSimulatedPitchRad: Double = 0.0
    private var currentSimulatedRollRad: Double = 0.0

    private var timer: Timer?
    private let lock = NSLock()

    var onReadingUpdated: (@Sendable (SUPostureReading) -> Void)?
    var onConnectionStateChanged: (@Sendable (SUHeadphoneConnectionState) -> Void)?
    var onPostureStateChanged: (@Sendable (SUPostureState, SUPostureState) -> Void)?
    var onCalibrationProgress: (@Sendable (Double) -> Void)?

    init(
        calibrationService: SUCalibrationService = SUCalibrationService(),
        stateEngine: SUPostureStateEngine = SUPostureStateEngine()
    ) {
        self.calibrationService = calibrationService
        self.stateEngine = stateEngine

        calibrationService.onCalibrationCompleted = { [weak self] pitch, roll in
            guard let self = self else { return }
            self.lock.lock()
            self.basePitchRad = pitch
            self.baseRollRad = roll
            self.lock.unlock()
            self.stateEngine.reset()
        }

        calibrationService.onCalibrationProgress = { [weak self] progress in
            self?.onCalibrationProgress?(progress)
        }

        stateEngine.onStateChanged = { [weak self] oldState, newState in
            self?.onPostureStateChanged?(oldState, newState)
        }

        if let saved = calibrationService.savedBaseline {
            basePitchRad = saved.pitch
            baseRollRad = saved.roll
        }

        SULogger.motion.info("SUMockMotionManager initialized (Simulator Mock Engine Active)")
    }

    func startMonitoring() {
        lock.lock()
        defer { lock.unlock() }

        timer?.invalidate()
        connectionState = .connected
        onConnectionStateChanged?(.connected)

        let timer = Timer(timeInterval: SUMotionConstants.defaultUpdateInterval, repeats: true) { [weak self] _ in
            self?.emitCurrentReading()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        SULogger.motion.debug("SUMockMotionManager started mock streaming")
    }

    func stopMonitoring() {
        lock.lock()
        defer { lock.unlock() }

        timer?.invalidate()
        timer = nil
        SULogger.motion.debug("SUMockMotionManager stopped")
    }

    func calibrateBaseline() {
        lock.lock()
        let pitch = currentSimulatedPitchRad
        let roll = currentSimulatedRollRad
        lock.unlock()

        calibrationService.calibrateImmediately(pitchRad: pitch, rollRad: roll)
        emitCurrentReading()
    }

    func requestMotionAuthorization(completion: (@Sendable (Bool) -> Void)? = nil) {
        lock.lock()
        connectionState = .connected
        lock.unlock()
        onConnectionStateChanged?(.connected)
        completion?(true)
    }

    /// 供模拟器或测试主动注入连接/佩戴/授权状态
    func setSimulatedConnectionState(_ state: SUHeadphoneConnectionState) {
        lock.lock()
        connectionState = state
        lock.unlock()
        DispatchQueue.main.async { [weak self] in
            self?.onConnectionStateChanged?(state)
        }
    }

    /// 供调试面板/滑块或单元测试主动注入模拟倾斜角度 (单位: 角度 Degrees，正数代表前倾低头)
    func injectSimulatedAngles(pitchDeg: Double, rollDeg: Double) {
        lock.lock()
        // 真实 AirPods 在低头时 pitch 为负，故模拟前倾时减去弧度
        self.currentSimulatedPitchRad = basePitchRad - (pitchDeg * .pi / 180.0)
        self.currentSimulatedRollRad = baseRollRad + (rollDeg * .pi / 180.0)
        lock.unlock()

        emitCurrentReading()
    }

    private func emitCurrentReading() {
        lock.lock()
        let pitch = currentSimulatedPitchRad
        let roll = currentSimulatedRollRad
        let bPitch = basePitchRad
        let bRoll = baseRollRad
        lock.unlock()

        calibrationService.feedSample(pitchRad: pitch, rollRad: roll)

        let reading = stateEngine.processFrame(
            rawPitchRad: pitch,
            rawRollRad: roll,
            basePitchRad: bPitch,
            baseRollRad: bRoll
        )

        DispatchQueue.main.async { [weak self] in
            self?.onReadingUpdated?(reading)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
