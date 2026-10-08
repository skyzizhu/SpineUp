//
//  SUCloudAIEngine.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import Alamofire
import os

/// 云端大模型 AI 引擎 —— 使用 Alamofire 请求后端 LLM 接口，具备严格超时保护
final class SUCloudAIEngine: SUAIServiceProtocol {

    private var currentEndpoint: String {
        return "\(SUAppConfig.apiBaseURL)/ai/reminder"
    }
    private let timeoutInterval: TimeInterval

    init(
        timeoutInterval: TimeInterval = SUAppConfig.aiGenerationTimeoutInterval
    ) {
        self.timeoutInterval = timeoutInterval
    }

    struct ReminderRequest: Encodable, Sendable {
        let systemPrompt: String
        let userPrompt: String
        let persona: String
        let angleDeg: Double
        let durationSec: Double
        let state: String
    }

    struct ReminderResponse: Decodable, Sendable {
        let code: Int
        let reminderText: String
    }

    func generateReminder(context: SUPostureContext) async throws -> String {
        let systemPrompt = SUPromptBuilder.buildSystemPrompt(for: context.persona)
        let userPrompt = SUPromptBuilder.buildUserPrompt(from: context)

        let requestBody = ReminderRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            persona: context.persona.rawValue,
            angleDeg: context.angleDeg,
            durationSec: context.durationSec,
            state: context.state.rawValue
        )

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        configuration.timeoutIntervalForResource = timeoutInterval
        let session = Session(configuration: configuration)

        var headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        if let token = SUUserDefaultsManager.shared.authToken, !token.isEmpty {
            headers.add(.authorization(bearerToken: token))
        }

        let targetURL = currentEndpoint

        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                targetURL,
                method: .post,
                parameters: requestBody,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate(statusCode: 200..<300)
            .responseDecodable(of: ReminderResponse.self) { response in
                switch response.result {
                case .success(let payload):
                    let cleaned = payload.reminderText.trimmingCharacters(in: .whitespacesAndNewlines)
                    continuation.resume(returning: cleaned)
                case .failure(let error):
                    SULogger.network.warning("Cloud AI request failed or timed out: \(error.localizedDescription, privacy: .public)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
