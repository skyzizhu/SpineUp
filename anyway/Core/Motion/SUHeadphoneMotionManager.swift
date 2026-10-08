//
//  SUHeadphoneMotionManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import CoreMotion
import os

/// 真机 AirPods 空间运动传感器管理器 —— 基于 CoreMotion CMHeadphoneMotionManager、状态机引擎与校准服务
final class SUHeadphoneMotionManager: NSObject, SUMotionServiceProtocol, CMHeadphoneMotionManagerDelegate, @unchecked Sendable {

    private let motionManager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()

    private let calibrationService: SUCalibrationService
    private let stateEngine: SUPostureStateEngine

    private(set) var connectionState: SUHeadphoneConnectionState = .disconnected
    var currentPostureState: SUPostureState {
        stateEngine.currentState
    }

    private var basePitchRad: Double = 0.0
    private var baseRollRad: Double = 0.0

    private let stateLock = NSLock()

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
        super.init()

        queue.name = "com.spineup.headphoneMotionQueue"
        queue.maxConcurrentOperationCount = 1
        motionManager.delegate = self

        // 绑定校准完成
        calibrationService.onCalibrationCompleted = { [weak self] pitch, roll in
            guard let self = self else { return }
            self.stateLock.lock()
            self.basePitchRad = pitch
            self.baseRollRad = roll
            self.stateLock.unlock()
            self.stateEngine.reset()
        }

        calibrationService.onCalibrationProgress = { [weak self] progress in
            self?.onCalibrationProgress?(progress)
        }

        // 绑定状态跃迁
        stateEngine.onStateChanged = { [weak self] oldState, newState in
            self?.onPostureStateChanged?(oldState, newState)
        }

        // 读取已有持久化基准
        if let saved = calibrationService.savedBaseline {
            basePitchRad = saved.pitch
            baseRollRad = saved.roll
            SULogger.motion.info("Loaded persisted calibration baseline: pitch=\(saved.pitch), roll=\(saved.roll)")
        }

        checkDeviceAvailability()
    }

    private func checkDeviceAvailability() {
        if motionManager.isDeviceMotionAvailable {
            connectionState = motionManager.isDeviceMotionActive ? .connected : .disconnected
        } else {
            connectionState = .unsupported
        }
        SULogger.motion.info("AirPods Device Motion Available: \(self.motionManager.isDeviceMotionAvailable)")
    }

    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            stateLock.lock()
            connectionState = .unsupported
            stateLock.unlock()
            onConnectionStateChanged?(.unsupported)
            SULogger.motion.warning("Device does not support headphone motion tracking.")
            return
        }

        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else {
                if let error = error {
                    SULogger.motion.error("Headphone motion update error: \(error.localizedDescription)")
                }
                return
            }

            self.handleMotionReading(motion)
        }

        stateLock.lock()
        connectionState = .connected
        stateLock.unlock()
        onConnectionStateChanged?(.connected)
        SULogger.motion.info("Started headphone motion tracking updates.")
    }

    func stopMonitoring() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
            SULogger.motion.info("Stopped headphone motion tracking updates.")
        }
    }

    func calibrateBaseline() {
        // 启动 2s 采样校准
        calibrationService.startSampling()
        SULogger.motion.info("Calibration baseline requested.")
    }

    private func handleMotionReading(_ motion: CMDeviceMotion) {
        let currentPitch = motion.attitude.pitch
        let currentRoll = motion.attitude.roll

        // 提供给校准服务进行采样
        calibrationService.feedSample(pitchRad: currentPitch, rollRad: currentRoll)

        stateLock.lock()
        let bPitch = basePitchRad
        let bRoll = baseRollRad
        stateLock.unlock()

        // 经过状态机引擎滤波与防抖判定
        let reading = stateEngine.processFrame(
            rawPitchRad: currentPitch,
            rawRollRad: currentRoll,
            basePitchRad: bPitch,
            baseRollRad: bRoll
        )

        DispatchQueue.main.async { [weak self] in
            self?.onReadingUpdated?(reading)
        }
    }

    // MARK: - CMHeadphoneMotionManagerDelegate
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        stateLock.lock()
        connectionState = .connected
        stateLock.unlock()
        SULogger.motion.notice("AirPods connected to headphone motion manager.")
        DispatchQueue.main.async { [weak self] in
            self?.onConnectionStateChanged?(.connected)
        }
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        stateLock.lock()
        connectionState = .disconnected
        stateLock.unlock()
        SULogger.motion.notice("AirPods disconnected from headphone motion manager.")
        DispatchQueue.main.async { [weak self] in
            self?.onConnectionStateChanged?(.disconnected)
        }
    }

    deinit {
        stopMonitoring()
    }
}
