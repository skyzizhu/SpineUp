//
//  SUPostureSessionManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 每日姿态会话管理中心 —— 线程安全聚合监测时长、颈椎累积受力并持久化至本地
final class SUPostureSessionManager: @unchecked Sendable {

    static let shared = SUPostureSessionManager()

    private let lock = NSLock()
    private var todaySession: SUPostureSession
    private var currentUprightRunSec: TimeInterval = 0.0
    private var lastPeriodicSaveUptime: TimeInterval = 0.0

    private let fileURL: URL

    /// 会话数据变更回调
    var onSessionUpdated: (@Sendable (SUPostureSession) -> Void)?

    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDir = paths.first ?? FileManager.default.temporaryDirectory
        self.fileURL = docDir.appendingPathComponent("SUPostureSessions.json")

        let todayStr = Self.todayDateString()
        self.todaySession = SUPostureSession(dateString: todayStr)

        loadPersistedSession()
    }

    /// 获取今日日期字符串 ("yyyy-MM-dd")
    static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// 获取当前最新的今日会话快照
    func getTodaySession() -> SUPostureSession {
        lock.lock()
        defer { lock.unlock() }
        ensureCorrectDate()
        return todaySession
    }

    /// 记录每一帧的监测数据
    /// - Parameters:
    ///   - state: 当前姿态状态
    ///   - pitchDeg: 俯仰角度（度数）
    ///   - deltaSeconds: 距上一帧的秒数
    func recordFrame(state: SUPostureState, pitchDeg: Double, deltaSeconds: TimeInterval) {
        lock.lock()
        ensureCorrectDate()

        if state == .upright {
            todaySession.uprightDurationSec += deltaSeconds
            currentUprightRunSec += deltaSeconds
            if currentUprightRunSec > todaySession.longestUprightStreakSec {
                todaySession.longestUprightStreakSec = currentUprightRunSec
            }
        } else if state == .slightSlump || state == .severeSlump {
            todaySession.slumpDurationSec += deltaSeconds
            currentUprightRunSec = 0.0

            // 累加额外受力当量
            let extraKg = SUErgonomicsCalculator.calculateExtraLoadKg(pitchDeg: pitchDeg)
            // 转换为累积微增量 (例如每秒累加)
            todaySession.accumulatedExtraLoadKg += (extraKg * deltaSeconds / 60.0)
        }

        let now = ProcessInfo.processInfo.systemUptime
        let shouldAutoSave = (now - lastPeriodicSaveUptime >= 30.0)
        if shouldAutoSave {
            lastPeriodicSaveUptime = now
        }

        let snapshot = todaySession
        lock.unlock()

        if shouldAutoSave {
            persistSessionAsync()
        }

        onSessionUpdated?(snapshot)
    }

    /// 记录一次低头违规
    func recordViolation() {
        lock.lock()
        ensureCorrectDate()
        todaySession.violationsCount += 1
        let snapshot = todaySession
        lock.unlock()

        persistSessionAsync()
        onSessionUpdated?(snapshot)
    }

    /// 30 秒微操急救成功后的体态回血对冲（卸下颈椎额外负荷，重置疲劳连续时长）
    func applyReliefRecovery(alleviatedKg: Double = 2.0) {
        lock.lock()
        ensureCorrectDate()
        todaySession.accumulatedExtraLoadKg = max(0.0, todaySession.accumulatedExtraLoadKg - alleviatedKg)
        currentUprightRunSec = 0.0
        let snapshot = todaySession
        lock.unlock()

        persistSessionAsync()
        onSessionUpdated?(snapshot)
    }

    /// 手动持久化保存
    func saveSession() {
        lock.lock()
        let snapshot = todaySession
        lock.unlock()

        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
            SULogger.data.debug("Saved today posture session to disk")
            syncToCloudIfPossible(session: snapshot)
        } catch {
            SULogger.data.warning("Failed to save session: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 尝试后台静默同步当日会话至云端服务器 (离线优先)
    func syncToCloudIfPossible(session: SUPostureSession? = nil) {
        let target = session ?? getTodaySession()
        Task.detached(priority: .background) {
            do {
                _ = try await SUAPIClient.shared.session.syncSession(target)
                SULogger.network.info("Successfully synced today posture session to backend")
            } catch {
                SULogger.network.debug("Cloud session sync skipped or failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func persistSessionAsync() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.saveSession()
        }
    }

    private func loadPersistedSession() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let loaded = try JSONDecoder().decode(SUPostureSession.self, from: data)
            let todayStr = Self.todayDateString()
            if loaded.dateString == todayStr {
                lock.lock()
                todaySession = loaded
                lock.unlock()
                SULogger.data.info("Loaded persisted today posture session with score: \(loaded.score)")
            }
        } catch {
            SULogger.data.warning("Failed to load persisted session: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func ensureCorrectDate() {
        let todayStr = Self.todayDateString()
        if todaySession.dateString != todayStr {
            todaySession = SUPostureSession(dateString: todayStr)
            currentUprightRunSec = 0.0
        }
    }
}
