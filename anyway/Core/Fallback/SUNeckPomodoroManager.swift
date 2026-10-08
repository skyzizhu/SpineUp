//
//  SUNeckPomodoroManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 护颈番茄钟运行状态
enum SUNeckPomodoroState: String, Sendable {
    case idle     // 未启动
    case working  // 专注挺拔工作中 (25分钟)
    case resting  // 颈椎舒展休息中 (5分钟)
}

/// 无耳机/未佩戴场景下的优雅降级方案 —— 护颈番茄钟管理器
final class SUNeckPomodoroManager: @unchecked Sendable {

    static let shared = SUNeckPomodoroManager()

    private let lock = NSLock()
    private var timer: Timer?

    private(set) var state: SUNeckPomodoroState = .idle
    private(set) var remainingSeconds: Int = 25 * 60
    private(set) var completedCycles: Int = 0

    /// 每秒倒计时状态变化回调 (state, remainingSeconds)
    var onTick: (@Sendable (SUNeckPomodoroState, Int) -> Void)?
    /// 状态切换回调 (oldState, newState)
    var onStateChanged: (@Sendable (SUNeckPomodoroState, SUNeckPomodoroState) -> Void)?

    private init() {}

    /// 启动护颈专注番茄钟
    func startWorkSession() {
        lock.lock()
        let old = state
        state = .working
        remainingSeconds = 25 * 60
        stopTimerInternal()
        startTimerInternal()
        lock.unlock()

        onStateChanged?(old, .working)
    }

    /// 暂停或重置
    func stopSession() {
        lock.lock()
        let old = state
        state = .idle
        remainingSeconds = 25 * 60
        stopTimerInternal()
        lock.unlock()

        onStateChanged?(old, .idle)
    }

    private func startTimerInternal() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }

    private func stopTimerInternal() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            self?.timer = nil
        }
    }

    private func tick() {
        lock.lock()
        guard state != .idle else {
            lock.unlock()
            return
        }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
            let current = remainingSeconds
            let curState = state
            lock.unlock()

            // 专注工作期间，每秒记录到体态会话中 (挺拔状态)
            if curState == .working {
                SUPostureSessionManager.shared.recordFrame(state: .upright, pitchDeg: 0.0, deltaSeconds: 1.0)
                SUSpineEnergyManager.shared.trackUprightFrame(deltaSeconds: 1.0)
            }

            onTick?(curState, current)
        } else {
            // 阶段交替
            let old = state
            if state == .working {
                state = .resting
                remainingSeconds = 5 * 60
                completedCycles += 1
                lock.unlock()
                SUAudioFeedbackManager.shared.playRecoveryChime()
                onStateChanged?(old, .resting)
            } else {
                state = .working
                remainingSeconds = 25 * 60
                lock.unlock()
                SUAudioFeedbackManager.shared.playSlumpReminderSound()
                onStateChanged?(old, .working)
            }
        }
    }
}
