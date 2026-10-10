//
//  SUDailyReportViewModel.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 报告周期类型
enum SUReportPeriodType: Int, CaseIterable, Sendable {
    case daily = 0
    case weekly = 1

    var localizedTitle: String {
        switch self {
        case .daily:
            return SULocalized("period_daily", default: "今日战报")
        case .weekly:
            return SULocalized("period_weekly", default: "本周战报")
        }
    }
}

/// 骨气报告 ViewModel —— 严格遵循 MVVM 规范，支持日/周双周期聚合与快速切换
final class SUDailyReportViewModel: @unchecked Sendable {

    private let sessionManager: SUPostureSessionManager
    private let personaManager: SUPetPersonaManager

    private let lock = NSLock()

    // MARK: - 状态 Outputs
    private(set) var selectedPeriod: SUReportPeriodType = .daily
    private(set) var currentDailyReport: SUDailyReport
    private(set) var currentWeeklyReport: SUWeeklyReport

    // 缓存上次计算的入参，避免无变动时无谓刷新
    private var lastCalculatedSession: SUPostureSession?
    private var lastCalculatedPersona: SUPetPersona?
    private var isWeeklyDirty: Bool = false

    // 兼容原有的 currentReport 访问
    var currentReport: SUDailyReport {
        return currentDailyReport
    }

    // MARK: - 回调
    var onReportUpdated: (@Sendable (SUDailyReport) -> Void)?
    var onWeeklyReportUpdated: (@Sendable (SUWeeklyReport) -> Void)?
    var onPeriodChanged: (@Sendable (SUReportPeriodType) -> Void)?

    init(
        sessionManager: SUPostureSessionManager = .shared,
        personaManager: SUPetPersonaManager = .shared
    ) {
        self.sessionManager = sessionManager
        self.personaManager = personaManager

        let session = sessionManager.getTodaySession()
        let persona = personaManager.currentPersona
        self.currentDailyReport = SUDailyReportGenerator.generateReport(session: session, persona: persona)
        self.currentWeeklyReport = SUWeeklyReportGenerator.generateReport(todaySession: session, persona: persona)
        self.lastCalculatedSession = session
        self.lastCalculatedPersona = persona
        self.isWeeklyDirty = false

        setupBindings()
    }

    private func setupBindings() {
        sessionManager.onSessionUpdated = { [weak self] _ in
            self?.refreshReport(force: false)
        }

        personaManager.onPersonaChanged = { [weak self] _ in
            self?.refreshReport(force: true)
        }
    }

    /// 切换周期 (日 / 周)
    func selectPeriod(_ period: SUReportPeriodType) {
        lock.lock()
        self.selectedPeriod = period
        let shouldUpdateWeekly = (period == .weekly && isWeeklyDirty)
        if shouldUpdateWeekly {
            let session = sessionManager.getTodaySession()
            let persona = personaManager.currentPersona
            let weekly = SUWeeklyReportGenerator.generateReport(todaySession: session, persona: persona)
            self.currentWeeklyReport = weekly
            self.isWeeklyDirty = false
        }
        let weeklySnapshot = self.currentWeeklyReport
        lock.unlock()

        onPeriodChanged?(period)
        if shouldUpdateWeekly {
            onWeeklyReportUpdated?(weeklySnapshot)
        }

        if period == .weekly {
            fetchWeeklyReportFromCloud()
        }
    }

    /// 尝试从云端拉取真实周报数据进行平滑更新 (离线优先)
    func fetchWeeklyReportFromCloud() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let cloudData = try await SUAPIClient.shared.report.fetchPeriodicReport(periodType: "weekly")
                let cloudWeekly = SUWeeklyReport(fromCloud: cloudData, persona: self.personaManager.currentPersona)
                self.applyCloudWeeklyReport(cloudWeekly)
            } catch {
                SULogger.network.debug("Weekly report cloud fetch fallback to local computation: \(error.localizedDescription)")
            }
        }
    }

    private func applyCloudWeeklyReport(_ cloudWeekly: SUWeeklyReport) {
        let isCurrentWeekly = lock.withLock {
            self.currentWeeklyReport = cloudWeekly
            self.isWeeklyDirty = false
            return self.selectedPeriod == .weekly
        }

        if isCurrentWeekly {
            DispatchQueue.main.async {
                self.onWeeklyReportUpdated?(cloudWeekly)
            }
        }
    }

    /// 主动刷新报告数据（带智能变动检测与周报懒计算）
    func refreshReport(force: Bool = false) {
        let session = sessionManager.getTodaySession()
        let persona = personaManager.currentPersona

        lock.lock()
        if !force, session == lastCalculatedSession, persona == lastCalculatedPersona {
            // 数据未变更，无需触发昂贵的二次计算与全量卡片重新排版
            lock.unlock()
            return
        }

        self.lastCalculatedSession = session
        self.lastCalculatedPersona = persona
        let daily = SUDailyReportGenerator.generateReport(session: session, persona: persona)
        self.currentDailyReport = daily

        var weeklyToNotify: SUWeeklyReport? = nil
        if selectedPeriod == .weekly {
            let weekly = SUWeeklyReportGenerator.generateReport(todaySession: session, persona: persona)
            self.currentWeeklyReport = weekly
            self.isWeeklyDirty = false
            weeklyToNotify = weekly
        } else {
            self.isWeeklyDirty = true
        }
        lock.unlock()

        onReportUpdated?(daily)
        if let weekly = weeklyToNotify {
            onWeeklyReportUpdated?(weekly)
        }
    }
}
