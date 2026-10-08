//
//  SUMotionServiceProtocol.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 当前体态判定状态
enum SUPostureState: String, Codable, Sendable {
    case upright      // 端正挺拔
    case slightSlump  // 轻度前倾
    case severeSlump  // 严重驼背
    case calibrating  // 正在校准基准
    case unknown      // 传感器不可用/未佩戴
}

/// AirPods 耳机运动传感器连接状态
enum SUHeadphoneConnectionState: String, Codable, Sendable {
    case connected     // 已连接且可用
    case disconnected  // 未佩戴或蓝牙断开
    case unsupported   // 设备不支持耳机空间运动追踪
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

    /// 姿态读数更新回调
    var onReadingUpdated: (@Sendable (SUPostureReading) -> Void)? { get set }

    /// 连接状态变化回调
    var onConnectionStateChanged: (@Sendable (SUHeadphoneConnectionState) -> Void)? { get set }
}
