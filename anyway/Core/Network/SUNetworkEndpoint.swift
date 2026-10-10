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

/// 排行榜单项响应载荷
struct SULeaderboardItemData: Decodable, Sendable {
    let rank: Int
    let user_id: Int
    let user_name: String
    let value: Double
    let metric_name: String
    let avatar_id: String
    let streak_days: Int
    let energy_coins: Int
    let quality_ratio: Double
}

/// 排行榜整体响应载荷
struct SULeaderboardResponseData: Decodable, Sendable {
    let board_type: String
    let page: Int
    let my_rank: SULeaderboardItemData?
    let top_list: [SULeaderboardItemData]
    let total_participants: Int
    let positive_policy: String?
}

/// 个人资料更新响应载荷
struct SUUpdateProfileResponseData: Decodable, Sendable {
    let updated: Bool
    let user_id: Int
    let nickname: String
}

// MARK: - AI 深度危害透视与急救方案
struct SUAIHazardRequest: Encodable, Sendable {
    let pitchDeg: Double
    let extraLoadKg: Double
    let slumpDurationSec: Double
    let violationsCount: Int
    let persona: String
    let userName: String
    let locale: String
}

struct SUAIHazardResponseData: Decodable, Sendable {
    let headline: String
    let metaphor_comparison: String
    let appearance_analysis: String
    let timeline_projection: String
    let pet_comment: String
    let is_ai_generated: Bool?
}

struct SUAIReliefPrescriptionRequest: Encodable, Sendable {
    let pitchDeg: Double
    let extraLoadKg: Double
    let persona: String
    let locale: String
}

struct SUAIReliefPrescriptionResponseData: Decodable, Sendable {
    let quick_diagnosis: String
    let action1_tips: String
    let action2_tips: String
    let ergonomic_tips: String
    let pet_encouragement: String
    let is_ai_generated: Bool?
}

// MARK: - 30秒微操打卡领能量
struct SUReliefClaimRequest: Encodable, Sendable {
    let action_type: String
    let pitch_deg: Double
    let extra_load_kg: Double
    let duration_sec: Int
}

struct SUReliefClaimResponseData: Decodable, Sendable {
    let claimed: Bool
    let reward_coins: Int
    let new_balance: Int
    let today_count: Int
}

// MARK: - 全周期体态报告
struct SUPeriodicReportResponseData: Decodable, Sendable {
    let period_type: String
    let period_key: String
    let start_date: String
    let end_date: String
    let total_wear_sec: Double
    let upright_sec: Double
    let slump_sec: Double
    let avg_score: Int
    let accumulated_load_kg: Double
    let alleviated_load_kg: Double
    let total_violations: Int
    let best_day_date: String?
    let fatigue_hotspot_hour: Int
    let dowager_hump_risk: Int
    let equivalent_item_name: String
    let ai_persona_summary: String
    let share_hash: String
    let date_range_text: String
    let daily_breakdown: [SUWeeklyDailyBarItem]?
}

// MARK: - 接口端点枚举

enum SUNetworkEndpoint {
    // 认证与用户
    case guestLogin(request: SUGuestAuthRequest)
    case fetchUserProfile
    case updateUserSettings(request: SUUpdateSettingsRequest)
    case updateProfile(nickname: String)

    // 排行榜
    case fetchLeaderboard(type: String, page: Int = 1, pageSize: Int = 20)

    // AI 网关
    case aiReminder(request: SUCloudAIEngine.ReminderRequest)
    case aiHazard(request: SUAIHazardRequest)
    case aiReliefPrescription(request: SUAIReliefPrescriptionRequest)

    // 减负打卡领能量
    case claimRelief(request: SUReliefClaimRequest)

    // 全周期体态健康报告
    case fetchPeriodicReport(periodType: String, periodKey: String?)

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
        case .updateProfile:
            return "/users/profile"
        case .fetchLeaderboard:
            return "/leaderboard"
        case .aiReminder:
            return "/ai/reminder"
        case .aiHazard:
            return "/ai/posture-hazard"
        case .aiReliefPrescription:
            return "/ai/relief-prescription"
        case .claimRelief:
            return "/relief/claim"
        case .fetchPeriodicReport:
            return "/reports/periodic"
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
        case .guestLogin, .aiReminder, .syncSession, .aiHazard, .aiReliefPrescription, .claimRelief:
            return .post
        case .updateUserSettings, .updateProfile:
            return .put
        case .fetchUserProfile, .fetchSessionHistory, .fetchAppConfig, .fetchLeaderboard, .fetchPeriodicReport:
            return .get
        }
    }

    /// 是否需要 Bearer Token 鉴权头
    var requiresAuth: Bool {
        switch self {
        case .guestLogin, .aiReminder, .fetchAppConfig:
            return false
        case .fetchUserProfile, .updateUserSettings, .syncSession, .fetchSessionHistory, .updateProfile, .fetchLeaderboard, .aiHazard, .aiReliefPrescription, .claimRelief, .fetchPeriodicReport:
            return true
        }
    }
}
