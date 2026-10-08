//
//  SUHeadphoneMotionManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import CoreMotion
import os

/// 真机 AirPods 空间运动传感器管理器 —— 基于 CoreMotion CMHeadphoneMotionManager
final class SUHeadphoneMotionManager: NSObject, SUMotionServiceProtocol, CMHeadphoneMotionManagerDelegate, @unchecked Sendable {

    private let motionManager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()

    private(set) var connectionState: SUHeadphoneConnectionState = .disconnected
    private(set) var currentPostureState: SUPostureState = .unknown

    private var basePitchRad: Double = 0.0
    private var baseRollRad: Double = 0.0
    private var isCalibrated: Bool = false

    private let stateLock = NSLock()

    var onReadingUpdated: (@Sendable (SUPostureReading) -> Void)?
    var onConnectionStateChanged: (@Sendable (SUHeadphoneConnectionState) -> Void)?

    override init() {
        super.init()
        queue.name = "com.spineup.headphoneMotionQueue"
        queue.maxConcurrentOperationCount = 1
        motionManager.delegate = self

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
        // 在最新一帧中将当前角度记录为中立基准
        stateLock.lock()
        isCalibrated = true
        stateLock.unlock()
        SULogger.motion.info("Calibration baseline requested.")
    }

    private func handleMotionReading(_ motion: CMDeviceMotion) {
        let currentPitch = motion.attitude.pitch
        let currentRoll = motion.attitude.roll

        stateLock.lock()
        if !isCalibrated {
            basePitchRad = currentPitch
            baseRollRad = currentRoll
            isCalibrated = true
        }

        // 计算相对偏移 (弧度 -> 角度)
        // 在 AirPods 佩戴方向上，低头通常体现为 pitch 增加
        let deltaPitchDeg = (currentPitch - basePitchRad) * (180.0 / .pi)
        let deltaRollDeg = (currentRoll - baseRollRad) * (180.0 / .pi)

        let state: SUPostureState
        if deltaPitchDeg > SUMotionConstants.severeSlumpAngleThreshold {
            state = .severeSlump
        } else if deltaPitchDeg > SUMotionConstants.slightSlumpAngleThreshold {
            state = .slightSlump
        } else {
            state = .upright
        }
        currentPostureState = state
        stateLock.unlock()

        let extraLoadKg = max(0.0, (deltaPitchDeg / 60.0) * (SUMotionConstants.loadAt60DegreesKg - SUMotionConstants.neutralHeadWeightKg))

        let reading = SUPostureReading(
            timestamp: Date(),
            rawPitch: currentPitch,
            rawRoll: currentRoll,
            relativePitchDeg: deltaPitchDeg,
            relativeRollDeg: deltaRollDeg,
            state: state,
            extraLoadKg: extraLoadKg
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
        currentPostureState = .unknown
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
