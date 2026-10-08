//
//  SUOfflineAIEngine.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 本地离线高频语料 AI 引擎 —— 零网络依赖、毫秒级响应、稳定可靠
final class SUOfflineAIEngine: SUAIServiceProtocol {

    init() {}

    func generateReminder(context: SUPostureContext) async throws -> String {
        let line = SUOfflineCorpus.pickLine(for: context)
        return line
    }
}
