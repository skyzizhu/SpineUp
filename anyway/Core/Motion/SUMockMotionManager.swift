//
//  SUMockMotionManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 模拟器/测试用 Mock 传感器管理器 —— 支持无 AirPods 环境下通过代码或滑块模拟体态变化
final class SUMockMotionManager: SUMotionServiceProtocol, @unchecked Sendable {

    private(set) var connectionState: SUHeadphoneConnectionState = .connected
    private(set) var currentPostureState: SUPostureState = .upright

    private var basePitch: Double = 0.0
    private var baseRoll: Double = 0.0

    private var currentSimulatedPitchDeg: Double = 0.0
    private var currentSimulatedRollDeg: Double = 0.0

    private var timer: Timer?
    private let lock = NSLock()

    var onReadingUpdated: (@Sendable (SUPostureReading) -> Void)?
    var onConnectionStateChanged: (@Sendable (SUHeadphoneConnectionState) -> Void)?

    init() {
        SULogger.motion.info("SUMockMotionManager initialized (Simulator Mock Engine Active)")
    }

    func startMonitoring() {
        lock.lock()
        defer { lock.unlock() }

        timer?.invalidate()
        connectionState = .connected
        onConnectionStateChanged?(.connected)

        // 启动定时模拟心跳
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
        basePitch = currentSimulatedPitchDeg
        baseRoll = currentSimulatedRollDeg
        currentPostureState = .upright
        lock.unlock()

        SULogger.motion.info("SUMockMotionManager calibrated to basePitch: \(self.basePitch)°")
        emitCurrentReading()
    }

    /// 供调试面板/滑块主动注入模拟倾斜角度 (单位: 角度)
    func injectSimulatedAngles(pitchDeg: Double, rollDeg: Double) {
        lock.lock()
        self.currentSimulatedPitchDeg = pitchDeg
        self.currentSimulatedRollDeg = rollDeg

        let deltaPitch = pitchDeg - basePitch

        if deltaPitch > SUMotionConstants.severeSlumpAngleThreshold {
            currentPostureState = .severeSlump
        } else if deltaPitch > SUMotionConstants.slightSlumpAngleThreshold {
            currentPostureState = .slightSlump
        } else {
            currentPostureState = .upright
        }
        lock.unlock()

        emitCurrentReading()
    }

    private func emitCurrentReading() {
        let pitch = currentSimulatedPitchDeg
        let roll = currentSimulatedRollDeg
        let state = currentPostureState

        // 简单估算额外承重
        let extraLoad: Double
        switch state {
        case .upright: extraLoad = 0.0
        case .slightSlump: extraLoad = 7.0 // 12 - 5
        case .severeSlump: extraLoad = 22.0 // 27 - 5
        case .calibrating, .unknown: extraLoad = 0.0
        }

        let reading = SUPostureReading(
            timestamp: Date(),
            rawPitch: pitch * .pi / 180.0,
            rawRoll: roll * .pi / 180.0,
            relativePitchDeg: pitch - basePitch,
            relativeRollDeg: roll - baseRoll,
            state: state,
            extraLoadKg: extraLoad
        )

        DispatchQueue.main.async { [weak self] in
            self?.onReadingUpdated?(reading)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
