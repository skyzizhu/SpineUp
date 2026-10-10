//
//  SUKeychainManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/10.
//

import Foundation
import os

/// 钥匙串安全存储管理器 —— 基于 KeychainAccess 库持久化存储设备 UUID 与认证 Token
/// 解决用户卸载重装 App 导致 user_id 变化或访客资产丢失的问题
final class SUKeychainManager: @unchecked Sendable {

    static let shared = SUKeychainManager()

    private let keychain: Keychain
    private let lock = NSLock()

    private let serviceName = "com.iashes.anyway.keychain"
    private let deviceUUIDKey = "su_device_unique_uuid"
    private var authTokenKey: String {
        return "su_auth_token_\(SUAppConfig.currentEnvironment.rawValue)"
    }

    init() {
        self.keychain = Keychain(service: serviceName)
            .accessibility(.afterFirstUnlock)
    }

    // MARK: - Device UUID (唯一持久化设备标识)

    /// 获取或生成全局持久化设备 UUID
    /// 优先级: Keychain -> UserDefaults (平滑迁移) -> 新生成 UUID 并写入 Keychain
    var deviceUUID: String {
        lock.lock()
        defer { lock.unlock() }

        // 1. 优先从钥匙串读取 (即使 App 被卸载重装，Keychain 仍被保留)
        if let storedUUID = try? keychain.getString(deviceUUIDKey), !storedUUID.isEmpty {
            // 同步镜像到 UserDefaults 以备离线与轻量读取
            if UserDefaults.standard.string(forKey: deviceUUIDKey) != storedUUID {
                UserDefaults.standard.set(storedUUID, forKey: deviceUUIDKey)
            }
            return storedUUID
        }

        // 2. 检查历史版本 UserDefaults 中已有的 UUID 进行无损迁移入钥匙串
        if let legacyUUID = UserDefaults.standard.string(forKey: deviceUUIDKey), !legacyUUID.isEmpty {
            do {
                try keychain.set(legacyUUID, key: deviceUUIDKey)
                SULogger.data.info("Migrated existing UUID from UserDefaults to Keychain: \(legacyUUID, privacy: .public)")
            } catch {
                SULogger.data.warning("Failed to migrate UUID to Keychain: \(error.localizedDescription, privacy: .public)")
            }
            return legacyUUID
        }

        // 3. 首次全新生成并持久化写入钥匙串与 UserDefaults
        let newUUID = UUID().uuidString
        do {
            try keychain.set(newUUID, key: deviceUUIDKey)
            SULogger.data.info("Generated and saved new device UUID to Keychain: \(newUUID, privacy: .public)")
        } catch {
            SULogger.data.warning("Failed to save new UUID to Keychain: \(error.localizedDescription, privacy: .public)")
        }
        UserDefaults.standard.set(newUUID, forKey: deviceUUIDKey)
        return newUUID
    }

    // MARK: - Auth Token (用户凭据)

    /// 获取或设置钥匙串中的 Token
    var authToken: String? {
        get {
            lock.lock()
            defer { lock.unlock() }

            if let token = try? keychain.getString(authTokenKey), !token.isEmpty {
                return token
            }
            return UserDefaults.standard.string(forKey: authTokenKey)
        }
        set {
            if let token = newValue, !token.isEmpty {
                saveAuthToken(token)
            } else {
                clearAuthToken()
            }
        }
    }

    /// 保存 Token 到钥匙串与本地镜像
    func saveAuthToken(_ token: String) {
        lock.lock()
        defer { lock.unlock() }

        do {
            try keychain.set(token, key: authTokenKey)
            SULogger.data.info("Saved auth token to Keychain successfully")
        } catch {
            SULogger.data.warning("Failed to save auth token to Keychain: \(error.localizedDescription, privacy: .public)")
        }
        UserDefaults.standard.set(token, forKey: authTokenKey)
    }

    /// 清空钥匙串中的 Token
    func clearAuthToken() {
        lock.lock()
        defer { lock.unlock() }

        do {
            try keychain.remove(authTokenKey)
            SULogger.data.info("Removed auth token from Keychain")
        } catch {
            SULogger.data.warning("Failed to remove auth token from Keychain: \(error.localizedDescription, privacy: .public)")
        }
        UserDefaults.standard.removeObject(forKey: authTokenKey)
    }
}
