//
//  SUMotionServiceProtocol.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SwiftUI

/// 当前体态判定状态
enum SUPostureState: String, Codable, Sendable {
    case upright      // 精神挺拔
    case slightSlump  // 轻微前倾
    case severeSlump  // 严重驼背
    case calibrating  // 正在校准基准
    case unknown      // 传感器不可用/未佩戴
}

extension SUPostureState {

    /// 状态统一中文短名称（精神挺拔、轻微前倾、严重驼背）
    var displayName: String {
        switch self {
        case .upright:
            return SULocalized("posture_state_upright", default: "精神挺拔")
        case .slightSlump:
            return SULocalized("posture_state_slight", default: "轻微前倾")
        case .severeSlump:
            return SULocalized("posture_state_severe", default: "严重驼背")
        case .calibrating:
            return SULocalized("posture_state_calibrating", default: "校准中")
        case .unknown:
            return SULocalized("posture_state_unknown", default: "未连接")
        }
    }

    /// 状态体态医学评估简评（用于仪表卡片/评估胶囊）
    var evaluationSummary: String {
        switch self {
        case .upright:
            return SULocalized("gauge_status_ideal_short", default: "零负担 · 完美体态")
        case .slightSlump:
            return SULocalized("gauge_status_slight_short", default: "轻度前倾 · 适度微调")
        case .severeSlump:
            return SULocalized("gauge_status_severe_short", default: "高危超负荷 · 立即抬头")
        case .calibrating:
            return SULocalized("gauge_status_calibrating", default: "基准校准中 · 端坐感知")
        case .unknown:
            return SULocalized("gauge_status_waiting", default: "正在同步空间姿态...")
        }
    }

    /// 紧急程度分级规范
    enum UrgencyLevel: Int, Comparable, Sendable {
        case safe = 0       // 绿色：安全健康（0° ~ 15°，额外承重 0 ~ 7kg）
        case warning = 1    // 橙色：中度预警（15° ~ 25°/30°，额外承重 7 ~ 13kg）
        case critical = 2   // 红色：紧急高危（> 25°/30°，额外承重 13 ~ 22kg+）
        case inProgress = 3 // 蓝色：校准进行中
        case offline = 4    // 灰色：未连接离线

        static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    var urgencyLevel: UrgencyLevel {
        switch self {
        case .upright: return .safe
        case .slightSlump: return .warning
        case .severeSlump: return .critical
        case .calibrating: return .inProgress
        case .unknown: return .offline
        }
    }

    /// 全局统一体态主题色 (UIKit)
    var themeColor: UIColor {
        switch self {
        case .upright: return .systemGreen
        case .slightSlump: return .systemOrange
        case .severeSlump: return .systemRed
        case .calibrating: return .systemBlue
        case .unknown: return .systemGray
        }
    }

    /// 全局统一体态胶囊背景浅色 (UIKit)
    var badgeBackgroundColor: UIColor {
        switch self {
        case .upright: return UIColor.systemGreen.withAlphaComponent(0.12)
        case .slightSlump: return UIColor.systemOrange.withAlphaComponent(0.12)
        case .severeSlump: return UIColor.systemRed.withAlphaComponent(0.12)
        case .calibrating: return UIColor.systemBlue.withAlphaComponent(0.12)
        case .unknown: return UIColor.systemGray.withAlphaComponent(0.12)
        }
    }

    /// 全局统一体态胶囊微描边色 (UIKit)
    var badgeBorderColor: UIColor {
        switch self {
        case .upright: return UIColor.systemGreen.withAlphaComponent(0.25)
        case .slightSlump: return UIColor.systemOrange.withAlphaComponent(0.25)
        case .severeSlump: return UIColor.systemRed.withAlphaComponent(0.25)
        case .calibrating: return UIColor.systemBlue.withAlphaComponent(0.25)
        case .unknown: return UIColor.systemGray.withAlphaComponent(0.25)
        }
    }

    /// 全局统一体态主题色 (SwiftUI)
    var swiftUIColor: Color {
        switch self {
        case .upright: return .green
        case .slightSlump: return .orange
        case .severeSlump: return .red
        case .calibrating: return .blue
        case .unknown: return .gray
        }
    }

    /// 对应 SF Symbol 状态图标
    var iconSystemName: String {
        switch self {
        case .upright: return "checkmark.circle.fill"
        case .slightSlump: return "exclamationmark.triangle.fill"
        case .severeSlump: return "exclamationmark.octagon.fill"
        case .calibrating: return "scope"
        case .unknown: return "headphones.circle"
        }
    }

    /// 根据瞬时低头角度推断归属状态 (角度阈值：< 15° 为挺拔，15° ~ 25° 为临界，>= 25° 为报警)
    static func state(forPitchDeg pitch: Double) -> SUPostureState {
        if pitch >= SUMotionConstants.severeSlumpAngleThreshold {
            return .severeSlump
        } else if pitch >= SUMotionConstants.slightSlumpAngleThreshold {
            return .slightSlump
        } else {
            return .upright
        }
    }
}

/// AirPods 耳机运动传感器连接、入耳佩戴与权限授权状态 (涵盖产品 5 大核心状态 + 硬件不支持状态)
enum SUHeadphoneConnectionState: String, Codable, Sendable {
    /// 状态 1: 用户手机未连接 AirPods (蓝牙关闭或未连接耳机)
    case disconnected
    /// 状态 2: 用户连接了 AirPods，但未佩戴入耳，也未给应用授权
    case connectedUnwornUnauthorized
    /// 状态 3: 用户连接了 AirPods，但未佩戴入耳，且已给应用授权 (摘下耳机挂起状态)
    case connectedUnwornAuthorized
    /// 状态 4: 用户连接且佩戴了 AirPods，但未给应用授权 (待一键授权即可使用)
    case connectedWornUnauthorized
    /// 状态 5 (黄金终态): 用户连接且佩戴了 AirPods，也已给应用授权 (实时姿态追踪中)
    case connected
    /// 边缘状态: 设备或当前蓝牙外设不支持头部空间姿态追踪
    case unsupported
}

extension SUHeadphoneConnectionState {
    /// 是否处于正常姿态追踪中 (状态 5)
    var isWorking: Bool {
        return self == .connected
    }

    /// 是否已通过权限授权 (状态 3, 状态 5)
    var isAuthorized: Bool {
        switch self {
        case .connectedUnwornAuthorized, .connected:
            return true
        default:
            return false
        }
    }

    /// 是否处于佩戴入耳状态 (状态 4, 状态 5)
    var isWorn: Bool {
        switch self {
        case .connectedWornUnauthorized, .connected:
            return true
        default:
            return false
        }
    }

    /// 是否已连接蓝牙 (状态 2, 3, 4, 5)
    var isBluetoothConnected: Bool {
        switch self {
        case .connectedUnwornUnauthorized, .connectedUnwornAuthorized, .connectedWornUnauthorized, .connected:
            return true
        case .disconnected, .unsupported:
            return false
        }
    }

    /// 顶部胶囊/横幅短标题
    var displayTitle: String {
        switch self {
        case .connected:
            return SULocalized("conn_state_connected_title", default: "AirPods 空间运动追踪中")
        case .connectedWornUnauthorized:
            return SULocalized("conn_state_worn_unauth_title", default: "AirPods 已就绪 · 待授权")
        case .connectedUnwornAuthorized:
            return SULocalized("conn_state_unworn_auth_title", default: "AirPods 已摘下 / 挂起中")
        case .connectedUnwornUnauthorized:
            return SULocalized("conn_state_unworn_unauth_title", default: "检测到 AirPods · 待佩戴并授权")
        case .disconnected:
            return SULocalized("conn_state_disconnected_title", default: "AirPods 未连接")
        case .unsupported:
            return SULocalized("conn_state_unsupported_title", default: "设备暂不支持耳机动作感知")
        }
    }

    /// 详细说明/引导副标题
    var displaySubtitle: String {
        switch self {
        case .connected:
            return SULocalized("conn_state_connected_sub", default: "正在以 60Hz 采样率实时感知头部姿态与颈椎负荷")
        case .connectedWornUnauthorized:
            return SULocalized("conn_state_worn_unauth_sub", default: "检测到耳机已戴入耳中，轻触一键开启运动权限即可守护")
        case .connectedUnwornAuthorized:
            return SULocalized("conn_state_unworn_auth_sub", default: "已获得授权，戴入双耳系统将自动恢复体态感知")
        case .connectedUnwornUnauthorized:
            return SULocalized("conn_state_unworn_unauth_sub", default: "耳机已连手机但未入耳，请戴上耳机并轻触允许权限")
        case .disconnected:
            return SULocalized("conn_state_disconnected_sub", default: "请在系统设置中连接支持的 AirPods (Pro/Max/3/4代)")
        case .unsupported:
            return SULocalized("conn_state_unsupported_sub", default: "需要 AirPods Pro / 3代 / 4代 / Max 或 Beats Fit Pro 支持")
        }
    }

    /// 引导按钮文本 (CTA)
    var actionButtonTitle: String? {
        switch self {
        case .connected:
            return SULocalized("action_calibrate_baseline", default: "一键端坐校准")
        case .connectedWornUnauthorized:
            return SULocalized("action_request_auth", default: "一键允许授权")
        case .connectedUnwornUnauthorized:
            return SULocalized("action_wear_and_auth", default: "戴好后，点击授权")
        case .connectedUnwornAuthorized:
            return nil
        case .disconnected:
            return SULocalized("action_connect_help", default: "查看连接指南")
        case .unsupported:
            return SULocalized("action_know_more", default: "了解支持设备")
        }
    }

    /// 主题色彩
    var themeColor: UIColor {
        switch self {
        case .connected:
            return .systemGreen
        case .connectedWornUnauthorized:
            return .systemBlue
        case .connectedUnwornAuthorized:
            return .systemOrange
        case .connectedUnwornUnauthorized:
            return .systemYellow
        case .disconnected:
            return .systemOrange
        case .unsupported:
            return .secondaryLabel
        }
    }

    /// SF Symbol 图标名称
    var iconSystemName: String {
        switch self {
        case .connected:
            return "circle.fill"
        case .connectedWornUnauthorized:
            return "hand.raised.badge.shield.half.filled"
        case .connectedUnwornAuthorized:
            return "ear.and.waveform"
        case .connectedUnwornUnauthorized:
            return "exclamationmark.triangle.fill"
        case .disconnected:
            return "headphones"
        case .unsupported:
            return "circle.slash"
        }
    }
}

/// 单次姿态读数快照
struct SUPostureReading: Sendable {
    let timestamp: Date
    let rawPitch: Double        // 原始俯仰角 (弧度 Radians)
    let rawRoll: Double         // 原始横滚角 (弧度 Radians)
    let relativePitchDeg: Double // 相对校准基准的前倾角 (角度 Degrees，正数代表前倾)
    let relativeRollDeg: Double  // 相对校准基准的偏头角 (角度 Degrees)
    let state: SUPostureState
    let extraLoadKg: Double      // 额外颈椎负荷 (kg)
}

/// 运动传感器抽象协议 —— 解耦真机 AirPods 与模拟器 Mock
protocol SUMotionServiceProtocol: AnyObject, Sendable {
    /// 当前耳机连接状态
    var connectionState: SUHeadphoneConnectionState { get }

    /// 当前体态判定状态
    var currentPostureState: SUPostureState { get }

    /// 启动姿态监听更新
    func startMonitoring()

    /// 停止姿态监听更新
    func stopMonitoring()

    /// 以当前坐姿重置/校准基准零位 (Neutral Baseline)
    func calibrateBaseline()

    /// 请求运动授权或检测
    func requestMotionAuthorization(completion: (@Sendable (Bool) -> Void)?)

    /// 姿态读数更新回调
    var onReadingUpdated: (@Sendable (SUPostureReading) -> Void)? { get set }

    /// 连接状态变化回调
    var onConnectionStateChanged: (@Sendable (SUHeadphoneConnectionState) -> Void)? { get set }

    /// 体态状态跃迁回调 (oldState, newState)
    var onPostureStateChanged: (@Sendable (SUPostureState, SUPostureState) -> Void)? { get set }

    /// 校准进度回调 (0.0 ~ 1.0)
    var onCalibrationProgress: (@Sendable (Double) -> Void)? { get set }
}
