//
//  SUAPIClient.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 统一业务 API 客户端门面 —— 为各个 ViewModel 和 Manager 提供高层强类型接口
final class SUAPIClient: Sendable {

    static let shared = SUAPIClient()

    let auth = AuthAPI()
    let user = UserAPI()
    let session = SessionAPI()
    let config = ConfigAPI()

    // MARK: - 认证子模块
    final class AuthAPI: Sendable {
        func loginAsGuest() async throws -> SUAuthResponseData {
            let token = try await SUAuthSessionManager.shared.loginAsGuestSilently()
            return SUAuthResponseData(
                token: token,
                userId: 0,
                userUuid: SUAuthSessionManager.shared.deviceUUID,
                isGuest: true
            )
        }
    }

    // MARK: - 用户与配置子模块
    final class UserAPI: Sendable {
        func fetchProfile() async throws -> SUUserProfileResponseData {
            let res: SUNetworkResponse<SUUserProfileResponseData> = try await SUNetworkManager.shared.request(
                endpoint: .fetchUserProfile
            )
            guard let data = res.data else {
                throw SUNetworkError.serverError(code: res.code, message: res.message)
            }
            return data
        }

        func syncSettings(
            pitch: Double? = nil,
            roll: Double? = nil,
            persona: String? = nil,
            slightThreshold: Double? = nil,
            severeThreshold: Double? = nil
        ) async throws -> Bool {
            let req = SUUpdateSettingsRequest(
                activePersonaId: persona,
                calibrationBasePitch: pitch,
                calibrationBaseRoll: roll,
                slightSlumpThreshold: slightThreshold,
                severeSlumpThreshold: severeThreshold
            )
            let res: SUNetworkResponse<[String: Bool]> = try await SUNetworkManager.shared.request(
                endpoint: .updateUserSettings(request: req)
            )
            return res.isSuccess
        }
    }

    // MARK: - 会话同步子模块
    final class SessionAPI: Sendable {
        func syncSession(_ session: SUPostureSession) async throws -> SUSyncSessionResponseData {
            let req = SUSyncSessionRequest(
                date: session.dateString,
                uprightDurationSec: session.uprightDurationSec,
                slumpDurationSec: session.slumpDurationSec,
                longestStreakSec: session.longestUprightStreakSec,
                accumulatedExtraLoadKg: session.accumulatedExtraLoadKg,
                violationsCount: session.violationsCount,
                score: session.score,
                grade: session.grade
            )
            let res: SUNetworkResponse<SUSyncSessionResponseData> = try await SUNetworkManager.shared.request(
                endpoint: .syncSession(request: req)
            )
            guard let data = res.data else {
                throw SUNetworkError.serverError(code: res.code, message: res.message)
            }
            return data
        }
    }

    // MARK: - 远程配置子模块
    final class ConfigAPI: Sendable {
        func fetchRemoteConfig() async throws -> SURemoteConfigResponseData {
            let res: SUNetworkResponse<SURemoteConfigResponseData> = try await SUNetworkManager.shared.request(
                endpoint: .fetchAppConfig
            )
            guard let data = res.data else {
                throw SUNetworkError.serverError(code: res.code, message: res.message)
            }
            return data
        }
    }
}
