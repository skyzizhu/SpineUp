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
    let leaderboard = LeaderboardAPI()
    let ai = AIAPI()
    let relief = ReliefAPI()
    let report = ReportAPI()

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

    // MARK: - 排行榜与个人资料子模块
    final class LeaderboardAPI: Sendable {
        func fetchLeaderboard(type: String, page: Int = 1, pageSize: Int = 20) async throws -> SULeaderboardResponseData {
            let res: SUNetworkResponse<SULeaderboardResponseData> = try await SUNetworkManager.shared.request(
                endpoint: .fetchLeaderboard(type: type, page: page, pageSize: pageSize)
            )
            guard let data = res.data else {
                throw SUNetworkError.serverError(code: res.code, message: res.message)
            }
            return data
        }

        func updateProfile(nickname: String) async throws -> SUUpdateProfileResponseData {
            let res: SUNetworkResponse<SUUpdateProfileResponseData> = try await SUNetworkManager.shared.request(
                endpoint: .updateProfile(nickname: nickname)
            )
            guard let data = res.data else {
                throw SUNetworkError.serverError(code: res.code, message: res.message)
            }
            return data
        }
    }

    // MARK: - AI 深度体态分析与处方子模块
    final class AIAPI: Sendable {
        func fetchHazardAnalysis(
            pitchDeg: Double,
            extraLoadKg: Double,
            slumpDurationSec: Double,
            violationsCount: Int,
            persona: String,
            userName: String,
            locale: String
        ) async throws -> SUAIHazardResponseData {
            let req = SUAIHazardRequest(
                pitchDeg: pitchDeg,
                extraLoadKg: extraLoadKg,
                slumpDurationSec: slumpDurationSec,
                violationsCount: violationsCount,
                persona: persona,
                userName: userName,
                locale: locale
            )
            let res: SUNetworkResponse<SUAIHazardResponseData> = try await SUNetworkManager.shared.request(
                endpoint: .aiHazard(request: req)
            )
            guard let data = res.data else {
                throw SUNetworkError.serverError(code: res.code, message: res.message)
            }
            return data
        }

        func fetchReliefPrescription(
            pitchDeg: Double,
            extraLoadKg: Double,
            persona: String,
            locale: String
        ) async throws -> SUAIReliefPrescriptionResponseData {
            let req = SUAIReliefPrescriptionRequest(
                pitchDeg: pitchDeg,
                extraLoadKg: extraLoadKg,
                persona: persona,
                locale: locale
            )
            let res: SUNetworkResponse<SUAIReliefPrescriptionResponseData> = try await SUNetworkManager.shared.request(
                endpoint: .aiReliefPrescription(request: req)
            )
            guard let data = res.data else {
                throw SUNetworkError.serverError(code: res.code, message: res.message)
            }
            return data
        }
    }

    // MARK: - 30秒微操急救打卡子模块
    final class ReliefAPI: Sendable {
        func claim(
            actionType: String,
            pitchDeg: Double,
            extraLoadKg: Double,
            durationSec: Int = 30
        ) async throws -> SUReliefClaimResponseData {
            let req = SUReliefClaimRequest(
                action_type: actionType,
                pitch_deg: pitchDeg,
                extra_load_kg: extraLoadKg,
                duration_sec: durationSec
            )
            let res: SUNetworkResponse<SUReliefClaimResponseData> = try await SUNetworkManager.shared.request(
                endpoint: .claimRelief(request: req)
            )
            guard let data = res.data else {
                throw SUNetworkError.serverError(code: res.code, message: res.message)
            }
            return data
        }
    }

    // MARK: - 全周期体态战报与历史归档子模块
    final class ReportAPI: Sendable {
        func fetchPeriodicReport(periodType: String = "weekly", periodKey: String? = nil) async throws -> SUPeriodicReportResponseData {
            let res: SUNetworkResponse<SUPeriodicReportResponseData> = try await SUNetworkManager.shared.request(
                endpoint: .fetchPeriodicReport(periodType: periodType, periodKey: periodKey)
            )
            guard let data = res.data else {
                throw SUNetworkError.serverError(code: res.code, message: res.message)
            }
            return data
        }
    }
}
