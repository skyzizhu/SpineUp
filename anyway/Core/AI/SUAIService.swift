//
//  SUAIService.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 统一 AI 服务分发调度器 —— 云端优先，失败/超时 3s 毫秒级静默降级至本地离线高质量语料库
final class SUAIService: SUAIServiceProtocol {

    static let shared = SUAIService()

    private let cloudEngine: SUAIServiceProtocol
    private let offlineEngine: SUAIServiceProtocol

    init(
        cloudEngine: SUAIServiceProtocol = SUCloudAIEngine(),
        offlineEngine: SUAIServiceProtocol = SUOfflineAIEngine()
    ) {
        self.cloudEngine = cloudEngine
        self.offlineEngine = offlineEngine
    }

    func generateReminder(context: SUPostureContext) async -> String {
        do {
            // 优先请求云端（内置 3s 超时与网络中断保护）
            let text = try await cloudEngine.generateReminder(context: context)
            if !text.isEmpty {
                SULogger.business.info("Generated reminder via Cloud AI: \(text, privacy: .public)")
                return text
            }
        } catch {
            SULogger.business.notice("Cloud AI failed, silently degrading to offline corpus: \(error.localizedDescription, privacy: .public)")
        }

        // 离线语料库兜底（100% 成功率）
        do {
            let offlineText = try await offlineEngine.generateReminder(context: context)
            SULogger.business.info("Generated reminder via Offline Corpus: \(offlineText, privacy: .public)")
            return offlineText
        } catch {
            // 极端异常防御性兜底
            return "做人要有骨气，挺直脊椎，继续加油！"
        }
    }
}
