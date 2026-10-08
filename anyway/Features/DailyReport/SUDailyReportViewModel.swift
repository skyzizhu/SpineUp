//
//  SUDailyReportViewModel.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 骨气战报 ViewModel —— 严格遵循 MVVM 规范，无 UIKit 依赖
final class SUDailyReportViewModel: @unchecked Sendable {

    private let sessionManager: SUPostureSessionManager
    private let personaManager: SUPetPersonaManager

    private let lock = NSLock()

    // MARK: - 状态 Outputs
    private(set) var currentReport: SUDailyReport

    // MARK: - 回调
    var onReportUpdated: (@Sendable (SUDailyReport) -> Void)?

    init(
        sessionManager: SUPostureSessionManager = .shared,
        personaManager: SUPetPersonaManager = .shared
    ) {
        self.sessionManager = sessionManager
        self.personaManager = personaManager

        let session = sessionManager.getTodaySession()
        let persona = personaManager.currentPersona
        self.currentReport = SUDailyReportGenerator.generateReport(session: session, persona: persona)

        setupBindings()
    }

    private func setupBindings() {
        sessionManager.onSessionUpdated = { [weak self] session in
            guard let self = self else { return }
            let persona = self.personaManager.currentPersona
            let report = SUDailyReportGenerator.generateReport(session: session, persona: persona)

            self.lock.lock()
            self.currentReport = report
            self.lock.unlock()

            self.onReportUpdated?(report)
        }

        personaManager.onPersonaChanged = { [weak self] persona in
            guard let self = self else { return }
            let session = self.sessionManager.getTodaySession()
            let report = SUDailyReportGenerator.generateReport(session: session, persona: persona)

            self.lock.lock()
            self.currentReport = report
            self.lock.unlock()

            self.onReportUpdated?(report)
        }
    }

    /// 主动刷新当日战报数据
    func refreshReport() {
        let session = sessionManager.getTodaySession()
        let persona = personaManager.currentPersona
        let report = SUDailyReportGenerator.generateReport(session: session, persona: persona)

        lock.lock()
        self.currentReport = report
        lock.unlock()

        onReportUpdated?(report)
    }
}
