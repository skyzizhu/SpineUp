//
//  SUAIServiceProtocol.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// AI 提醒生成服务协议 —— 统一云端 LLM 与本地离线语料引擎接口
protocol SUAIServiceProtocol: Sendable {
    /// 根据当前姿态上下文生成专属拟人提醒台词
    func generateReminder(context: SUPostureContext) async throws -> String
}
