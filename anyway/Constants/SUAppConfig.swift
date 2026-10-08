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
    static let appDisplayName = "SpineUp: AI Posture Pet"
    static let appBundleID = Bundle.main.bundleIdentifier ?? "com.iashes.anyway"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - 网络与 AI 服务配置
    static let apiBaseURL = "https://api.spineup.app/v1"
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
}
