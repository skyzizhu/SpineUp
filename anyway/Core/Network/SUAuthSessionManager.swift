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

    /// 当前缓存的有效 Token (优先读取 Keychain)
    var currentToken: String? {
        return SUKeychainManager.shared.authToken ?? userDefaults.authToken
    }

    /// 是否已经具备认证凭据
    var isAuthenticated: Bool {
        return currentToken != nil && !(currentToken?.isEmpty ?? true)
    }

    /// 获取或生成设备业务唯一标识 (UUID 持久保存在 Keychain 中，App 重装不丢失)
    var deviceUUID: String {
        return SUKeychainManager.shared.deviceUUID
    }

    /// 保存认证 Token
    func saveToken(_ token: String) {
        SUKeychainManager.shared.saveAuthToken(token)
        userDefaults.authToken = token
        SULogger.network.info("Saved auth token to Keychain and local storage")
    }

    /// 清理认证凭据
    func clearToken() {
        SUKeychainManager.shared.clearAuthToken()
        userDefaults.authToken = nil
        SULogger.network.info("Cleared auth token from Keychain and local storage")
    }

    private func fetchCachedToken() -> String? {
        lock.withLock {
            guard let token = currentToken, !token.isEmpty else {
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

    /// 强制刷新会话凭据（当远端提示 Token 失效或用户身份不匹配时由网络层自动调用）
    @discardableResult
    func refreshSession() async throws -> String {
        clearToken()
        return try await loginAsGuestSilently()
    }
}
