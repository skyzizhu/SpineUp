//
//  SUAuthSessionManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import UIKit
import os

/// 用户认证与会话管理中心 —— 统一管理访客/正式 Token 及无感免密自动鉴权
final class SUAuthSessionManager: @unchecked Sendable {

    static let shared = SUAuthSessionManager()

    private let userDefaults: SUUserDefaultsManager
    private let lock = NSLock()
    private var isAuthenticating = false

    init(userDefaults: SUUserDefaultsManager = .shared) {
        self.userDefaults = userDefaults
    }

    /// 当前缓存的有效 Token
    var currentToken: String? {
        return userDefaults.authToken
    }

    /// 是否已经具备认证凭据
    var isAuthenticated: Bool {
        return currentToken != nil && !(currentToken?.isEmpty ?? true)
    }

    /// 获取或生成设备业务唯一标识 (UUID)
    var deviceUUID: String {
        let key = "su_device_unique_uuid"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }

    /// 保存认证 Token
    func saveToken(_ token: String) {
        userDefaults.authToken = token
        SULogger.network.info("Saved auth token to local storage")
    }

    /// 清理认证凭据
    func clearToken() {
        userDefaults.authToken = nil
        SULogger.network.info("Cleared auth token")
    }

    private func fetchCachedToken() -> String? {
        lock.withLock {
            guard let token = userDefaults.authToken, !token.isEmpty else {
                return nil
            }
            return token
        }
    }

    /// 确保具备有效 Token，若无则自动以访客身份后台静默登录
    func ensureAuthenticated() async throws -> String {
        if let token = fetchCachedToken() {
            return token
        }
        return try await loginAsGuestSilently()
    }

    /// 静默访客免密登录
    @discardableResult
    func loginAsGuestSilently() async throws -> String {
        let deviceModel = await MainActor.run { UIDevice.current.model }
        let locale = Locale.current.identifier

        let request = SUGuestAuthRequest(
            deviceUuid: deviceUUID,
            deviceModel: deviceModel,
            locale: locale
        )

        SULogger.network.info("Initiating silent guest authentication for UUID: \(self.deviceUUID, privacy: .public)")

        let response: SUNetworkResponse<SUAuthResponseData> = try await SUNetworkManager.shared.requestDirect(
            endpoint: .guestLogin(request: request)
        )

        guard let data = response.data, !data.token.isEmpty else {
            throw SUNetworkError.serverError(code: response.code, message: response.message)
        }

        saveToken(data.token)
        return data.token
    }
}
