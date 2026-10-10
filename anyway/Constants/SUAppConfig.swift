//
//  SUAppConfig.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 应用级全局高级别公共配置 —— 跨模块复用的参数统一定义于此
enum SUAppConfig {

    // MARK: - 应用基本信息
    static let appName = "SpineUp"
    static let bundleDisplayName = "SpineUp"
    static let appDisplayName = "SpineUp: AI Posture Pet"
    static let appBundleID = Bundle.main.bundleIdentifier ?? "com.iashes.anyway"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - 服务器环境配置 (Server Environment)
    /// 服务器运行环境枚举 —— 上线发布时仅需将 currentEnvironment 切换为 .production
    enum ServerEnvironment: String, CaseIterable, Sendable {
        case local        // 本地 / 局域网联调服务器
        case production   // 线上正式生产服务器
    }

    /// 当前激活的服务器环境：一键切换 .local 或 .production
    static let currentEnvironment: ServerEnvironment = .production

    /// 局域网开发联调服务器根地址 (当前配置)
    static let localServerRootURL: String = "http://192.168.31.101/spineup"

    /// 线上正式生产服务器根地址 (已配置为线上正式环境)
    static let productionServerRootURL: String = "https://www.yourtools.xyz/spineup"

    /// API 版本路由前缀
    static let apiVersionPrefix: String = "/v1"

    /// 统一计算的 API 基础地址 (各网络接口直接使用此地址)
    static var apiBaseURL: String {
        if let custom = SUUserDefaultsManager.shared.customApiBaseURL, !custom.isEmpty {
            return custom.hasSuffix("/") ? String(custom.dropLast()) : custom
        }
        let root = (currentEnvironment == .local) ? localServerRootURL : productionServerRootURL
        let trimmedRoot = root.hasSuffix("/") ? String(root.dropLast()) : root
        let prefix = apiVersionPrefix.hasPrefix("/") ? apiVersionPrefix : "/\(apiVersionPrefix)"
        return "\(trimmedRoot)\(prefix)"
    }
    static let networkTimeoutInterval: TimeInterval = 15.0
    static let aiGenerationTimeoutInterval: TimeInterval = 3.0 // 云端 AI 响应超时阈值，超时自动降级至离线语料

    // MARK: - 功能开关 (Feature Flags)
    static let isMockMotionEnabledOnSimulator: Bool = true
    static let isProSubscriptionEnabled: Bool = false
    static let isHealthKitSyncEnabled: Bool = false
    static let isFallbackCameraModeEnabled: Bool = false

    // MARK: - 提醒与声音配置
    static let voiceReminderCooldownSeconds: TimeInterval = 180.0 // 两次语音提醒的最小冷却间隔
    static let audioAlertMaxVolume: Float = 0.35 // 轻量提示音最大音量

    // MARK: - 社交与战报
    static let shareWatermarkText = "SpineUp · 做人要有骨气"
    static let shareCardFooterNote = "Protected by AirPods Spatial Motion & AI"

    // MARK: - 骨气能量养成
    static let energyPointsPerMinuteUpright: Int = 1
    static let streakBonusMultiplier: Double = 1.5

    // MARK: - 法律与合规公网链接 (Legal & Compliance Public URLs)
    static let legalBaseURL = "https://skyzizhu.github.io/SpineUp"
    static var medicalDisclaimerURL: String { "\(legalBaseURL)/medical.html" }
    static var privacyPolicyURL: String { "\(legalBaseURL)/privacy.html" }
    static var termsOfServiceURL: String { "\(legalBaseURL)/terms.html" }
}
