//
//  SUNetworkEndpoint.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import Alamofire

// MARK: - 请求载荷模型定义

/// 访客登录请求
struct SUGuestAuthRequest: Encodable, Sendable {
    let deviceUuid: String
    let deviceModel: String
    let locale: String
}

/// 认证成功响应数据
struct SUAuthResponseData: Decodable, Sendable {
    let token: String
    let userId: Int
    let userUuid: String
    let isGuest: Bool
}

/// 用户偏好设置更新请求
struct SUUpdateSettingsRequest: Encodable, Sendable {
    let activePersonaId: String?
    let calibrationBasePitch: Double?
    let calibrationBaseRoll: Double?
    let slightSlumpThreshold: Double?
    let severeSlumpThreshold: Double?
}

/// 用户个人信息与配置详情响应
struct SUUserProfileResponseData: Decodable, Sendable {
    let id: Int
    let user_uuid: String
    let nickname: String
    let is_guest: Int
    let locale: String
    let active_persona_id: String?
    let calibration_base_pitch: Double?
    let calibration_base_roll: Double?
    let slight_slump_threshold: Double?
    let severe_slump_threshold: Double?
    let is_sound_enabled: Int?
    let is_haptic_enabled: Int?
    let is_voice_enabled: Int?
}

/// 姿态会话同步请求
struct SUSyncSessionRequest: Encodable, Sendable {
    let date: String
    let uprightDurationSec: Double
    let slumpDurationSec: Double
    let longestStreakSec: Double
    let accumulatedExtraLoadKg: Double
    let violationsCount: Int
    let score: Int
    let grade: String
}

/// 姿态会话同步响应
struct SUSyncSessionResponseData: Decodable, Sendable {
    let synced: Bool
    let todayTotalCoins: Int?
    let streakDays: Int?
}

/// 远程配置响应
struct SURemoteConfigResponseData: Decodable, Sendable {
    let appName: String
    let latestVersion: String
    let minSupportedVersion: String
    let forceUpdate: Bool
    let slightSlumpThreshold: Double
    let severeSlumpThreshold: Double
    let aiGenerationTimeoutSec: Double
}

// MARK: - 接口端点枚举

enum SUNetworkEndpoint {
    // 认证与用户
    case guestLogin(request: SUGuestAuthRequest)
    case fetchUserProfile
    case updateUserSettings(request: SUUpdateSettingsRequest)

    // AI 网关
    case aiReminder(request: SUCloudAIEngine.ReminderRequest)

    // 会话同步与历史
    case syncSession(request: SUSyncSessionRequest)
    case fetchSessionHistory(range: String)

    // 远程配置
    case fetchAppConfig

    /// 相对接口路径
    var path: String {
        switch self {
        case .guestLogin:
            return "/auth/guest"
        case .fetchUserProfile:
            return "/users/me"
        case .updateUserSettings:
            return "/users/settings"
        case .aiReminder:
            return "/ai/reminder"
        case .syncSession:
            return "/sessions/sync"
        case .fetchSessionHistory:
            return "/sessions/history"
        case .fetchAppConfig:
            return "/config/app"
        }
    }

    /// HTTP 请求方法
    var method: HTTPMethod {
        switch self {
        case .guestLogin, .aiReminder, .syncSession:
            return .post
        case .updateUserSettings:
            return .put
        case .fetchUserProfile, .fetchSessionHistory, .fetchAppConfig:
            return .get
        }
    }

    /// 是否需要 Bearer Token 鉴权头
    var requiresAuth: Bool {
        switch self {
        case .guestLogin, .aiReminder, .fetchAppConfig:
            return false
        case .fetchUserProfile, .updateUserSettings, .syncSession, .fetchSessionHistory:
            return true
        }
    }
}
