//
//  SUPostureStateEngine.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 防抖动滤波与体态状态机判定引擎 —— 包含 8 帧滑动平均与 10s/5s 防抖时间缓冲
final class SUPostureStateEngine: @unchecked Sendable {

    private let lock = NSLock()

    // MARK: - 状态输出
    private(set) var currentState: SUPostureState = .upright

    // MARK: - 滑动均值滤波窗口
    private var pitchWindow: [Double] = []
    private var rollWindow: [Double] = []

    // MARK: - 时间防抖缓冲
    private var slumpStartTime: Date?
    private var recoveryStartTime: Date?

    // MARK: - 回调
    var onStateChanged: (@Sendable (SUPostureState, SUPostureState) -> Void)? // (oldState, newState)

    init() {}

    /// 重置状态与滤波器窗口
    func reset() {
        lock.lock()
        pitchWindow.removeAll()
        rollWindow.removeAll()
        slumpStartTime = nil
        recoveryStartTime = nil
        currentState = .upright
        lock.unlock()
    }

    /// 输入新一帧原始弧度并结合校准基准计算平滑姿态
    func processFrame(
        rawPitchRad: Double,
        rawRollRad: Double,
        basePitchRad: Double,
        baseRollRad: Double
    ) -> SUPostureReading {
        lock.lock()
        defer { lock.unlock() }

        // 1. 滑动平均均值平滑 (Moving Average Filter)
        pitchWindow.append(rawPitchRad)
        if pitchWindow.count > SUMotionConstants.movingAverageFilterFrameCount {
            pitchWindow.removeFirst()
        }
        let smoothedPitchRad = pitchWindow.reduce(0.0, +) / Double(pitchWindow.count)

        rollWindow.append(rawRollRad)
        if rollWindow.count > SUMotionConstants.movingAverageFilterFrameCount {
            rollWindow.removeFirst()
        }
        let smoothedRollRad = rollWindow.reduce(0.0, +) / Double(rollWindow.count)

        // 2. 计算相对基准角度 (单位: 度 Degrees)
        // 在 AirPods CoreMotion 空间坐标系中：低头/前倾时 pitch 沿负方向减小 (nodding down is negative pitch)
        // 转换为业务语义：正数代表前倾/低头角度，负数代表后仰伸展
        let deltaPitchDeg = (basePitchRad - smoothedPitchRad) * (180.0 / .pi)
        let deltaRollDeg = (smoothedRollRad - baseRollRad) * (180.0 / .pi)

        // 3. 状态判定与防抖时间缓冲
        let now = Date()
        let oldState = currentState

        if deltaPitchDeg > SUMotionConstants.slightSlumpAngleThreshold {
            // 用户处于低头/前倾姿态
            recoveryStartTime = nil

            if slumpStartTime == nil {
                slumpStartTime = now
            }

            let slumpDuration = now.timeIntervalSince(slumpStartTime!)

            // 持续低头达到防抖阈值 (10秒)
            if slumpDuration >= SUMotionConstants.slumpTriggerBufferDuration {
                if deltaPitchDeg > SUMotionConstants.severeSlumpAngleThreshold {
                    currentState = .severeSlump
                } else {
                    currentState = .slightSlump
                }
            }
        } else if deltaPitchDeg < SUMotionConstants.uprightRecoveryAngleThreshold {
            // 用户处于挺拔姿势
            slumpStartTime = nil

            if currentState != .upright {
                if recoveryStartTime == nil {
                    recoveryStartTime = now
                }

                let recoveryDuration = now.timeIntervalSince(recoveryStartTime!)
                // 持续端正达到复原缓冲 (5秒)
                if recoveryDuration >= SUMotionConstants.recoveryBufferDuration {
                    currentState = .upright
                    recoveryStartTime = nil
                }
            }
        } else {
            // 处于 10° ~ 15° 的缓冲区间，保持当前判定
            slumpStartTime = nil
            recoveryStartTime = nil
        }

        let evaluatedState = currentState
        if oldState != evaluatedState {
            DispatchQueue.main.async { [weak self] in
                self?.onStateChanged?(oldState, evaluatedState)
            }
        }

        // 4. 计算人体工学颈椎附加负荷 (kg)
        let extraLoadKg = calculateNeckLoadKg(deltaPitchDeg: deltaPitchDeg)

        return SUPostureReading(
            timestamp: now,
            rawPitch: smoothedPitchRad,
            rawRoll: smoothedRollRad,
            relativePitchDeg: deltaPitchDeg,
            relativeRollDeg: deltaRollDeg,
            state: evaluatedState,
            extraLoadKg: extraLoadKg
        )
    }

    /// 基于医学力学曲线拟合颈椎额外承重 (kg)
    private func calculateNeckLoadKg(deltaPitchDeg: Double) -> Double {
        let angle = max(0.0, deltaPitchDeg)
        if angle <= 0 { return 0.0 }
        if angle <= 15.0 {
            return (angle / 15.0) * (SUMotionConstants.loadAt15DegreesKg - SUMotionConstants.neutralHeadWeightKg)
        } else if angle <= 30.0 {
            let ratio = (angle - 15.0) / 15.0
            return 7.0 + ratio * (SUMotionConstants.loadAt30DegreesKg - SUMotionConstants.loadAt15DegreesKg)
        } else if angle <= 45.0 {
            let ratio = (angle - 30.0) / 15.0
            return 13.0 + ratio * (SUMotionConstants.loadAt45DegreesKg - SUMotionConstants.loadAt30DegreesKg)
        } else {
            let ratio = min(1.0, (angle - 45.0) / 15.0)
            return 17.0 + ratio * (SUMotionConstants.loadAt60DegreesKg - SUMotionConstants.loadAt45DegreesKg)
        }
    }
}
