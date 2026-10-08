//
//  SUCalibrationService.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 坐姿基准校准服务 —— 负责采集端坐状态下的 Pitch/Roll 均值并持久化
final class SUCalibrationService: @unchecked Sendable {

    private let userDefaultsManager: SUUserDefaultsManager
    private let lock = NSLock()

    private var sampleBuffer: [(pitch: Double, roll: Double)] = []
    private var isSampling: Bool = false
    private var sampleStartTime: Date?

    var onCalibrationCompleted: (@Sendable (Double, Double) -> Void)?
    var onCalibrationProgress: (@Sendable (Double) -> Void)? // 0.0 ~ 1.0

    init(userDefaultsManager: SUUserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
    }

    /// 获取当前存储的基准零点 (pitch, roll)，若未校准则返回 nil
    var savedBaseline: (pitch: Double, roll: Double)? {
        guard userDefaultsManager.isCalibrated else { return nil }
        return (userDefaultsManager.calibrationBasePitch, userDefaultsManager.calibrationBaseRoll)
    }

    /// 开始 2 秒多帧采样校准
    func startSampling() {
        lock.lock()
        sampleBuffer.removeAll()
        isSampling = true
        sampleStartTime = Date()
        lock.unlock()

        SULogger.motion.info("Calibration sampling started for \(SUMotionConstants.calibrationSampleDuration)s")
    }

    /// 在每帧传感器到达时提供读数用于采样
    func feedSample(pitchRad: Double, rollRad: Double) {
        lock.lock()
        guard isSampling, let startTime = sampleStartTime else {
            lock.unlock()
            return
        }

        sampleBuffer.append((pitchRad, rollRad))
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(1.0, elapsed / SUMotionConstants.calibrationSampleDuration)
        lock.unlock()

        onCalibrationProgress?(progress)

        if elapsed >= SUMotionConstants.calibrationSampleDuration {
            finishSampling()
        }
    }

    /// 一键即时重置当前单帧为基准（快速校准）
    func calibrateImmediately(pitchRad: Double, rollRad: Double) {
        lock.lock()
        isSampling = false
        sampleBuffer.removeAll()
        lock.unlock()

        userDefaultsManager.saveCalibrationBaseline(pitch: pitchRad, roll: rollRad)
        SULogger.motion.info("Instant calibration saved: pitch=\(pitchRad), roll=\(rollRad)")
        onCalibrationCompleted?(pitchRad, rollRad)
    }

    private func finishSampling() {
        lock.lock()
        isSampling = false
        guard !sampleBuffer.isEmpty else {
            lock.unlock()
            return
        }

        let totalPitch = sampleBuffer.reduce(0.0) { $0 + $1.pitch }
        let totalRoll = sampleBuffer.reduce(0.0) { $0 + $1.roll }
        let avgPitch = totalPitch / Double(sampleBuffer.count)
        let avgRoll = totalRoll / Double(sampleBuffer.count)
        sampleBuffer.removeAll()
        lock.unlock()

        userDefaultsManager.saveCalibrationBaseline(pitch: avgPitch, roll: avgRoll)
        SULogger.motion.info("Multi-sample calibration finished (\(self.sampleBuffer.count) frames): pitch=\(avgPitch), roll=\(avgRoll)")
        onCalibrationProgress?(1.0)
        onCalibrationCompleted?(avgPitch, avgRoll)
    }

    func cancelSampling() {
        lock.lock()
        isSampling = false
        sampleBuffer.removeAll()
        lock.unlock()
    }
}
