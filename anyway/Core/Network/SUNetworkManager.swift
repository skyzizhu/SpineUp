//
//  SUNetworkManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import Alamofire
import os

/// 核心网络请求管理器 —— 基于 Alamofire 封装的统一强类型请求客户端
final class SUNetworkManager: @unchecked Sendable {

    static let shared = SUNetworkManager()

    private let session: Session

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = SUAppConfig.networkTimeoutInterval
        configuration.timeoutIntervalForResource = SUAppConfig.networkTimeoutInterval
        self.session = Session(configuration: configuration)
    }

    /// 执行带认证鉴权的异步网络请求
    func request<T: Decodable & Sendable>(endpoint: SUNetworkEndpoint) async throws -> SUNetworkResponse<T> {
        if endpoint.requiresAuth {
            _ = try await SUAuthSessionManager.shared.ensureAuthenticated()
        }
        return try await requestDirect(endpoint: endpoint)
    }

    /// 执行直接网络请求 (底层通用分发)
    func requestDirect<T: Decodable & Sendable>(endpoint: SUNetworkEndpoint) async throws -> SUNetworkResponse<T> {
        let baseURL = SUAppConfig.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fullURL = "\(baseURL)\(endpoint.path)"

        guard let url = URL(string: fullURL) else {
            throw SUNetworkError.invalidURL
        }

        var headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-Client-Platform": "iOS",
            "X-App-Version": SUAppConfig.appVersion
        ]

        if let token = SUAuthSessionManager.shared.currentToken, !token.isEmpty {
            headers.add(.authorization(bearerToken: token))
        }

        SULogger.network.debug("Requesting [\(endpoint.method.rawValue)] \(fullURL, privacy: .public)")

        return try await withCheckedThrowingContinuation { continuation in
            let request = buildRequest(url: url, endpoint: endpoint, headers: headers)

            request
                .validate(statusCode: 200..<300)
                .responseDecodable(of: SUNetworkResponse<T>.self) { response in
                    switch response.result {
                    case .success(let payload):
                        SULogger.network.debug("Request success: \(endpoint.path) (code: \(payload.code))")
                        continuation.resume(returning: payload)
                    case .failure(let error):
                        SULogger.network.warning("Network request failed: \(endpoint.path) -> \(error.localizedDescription, privacy: .public)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    private func buildRequest(url: URL, endpoint: SUNetworkEndpoint, headers: HTTPHeaders) -> DataRequest {
        switch endpoint {
        case .guestLogin(let req):
            return session.request(url, method: endpoint.method, parameters: req, encoder: JSONParameterEncoder.default, headers: headers)
        case .updateUserSettings(let req):
            return session.request(url, method: endpoint.method, parameters: req, encoder: JSONParameterEncoder.default, headers: headers)
        case .aiReminder(let req):
            return session.request(url, method: endpoint.method, parameters: req, encoder: JSONParameterEncoder.default, headers: headers)
        case .syncSession(let req):
            return session.request(url, method: endpoint.method, parameters: req, encoder: JSONParameterEncoder.default, headers: headers)
        case .fetchUserProfile, .fetchSessionHistory, .fetchAppConfig:
            return session.request(url, method: endpoint.method, headers: headers)
        }
    }
}
