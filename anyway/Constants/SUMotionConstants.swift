//
//  SUMotionConstants.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 传感器采样与体态判定业务常量
enum SUMotionConstants {

    // MARK: - 传感器采样频率
    static let defaultUpdateInterval: TimeInterval = 1.0 / 15.0 // 15 Hz 采样频率
    static let lowPowerUpdateInterval: TimeInterval = 1.0 / 5.0  // 5 Hz 低功耗节能模式

    // MARK: - 体态角度阈值 (单位: 角度 Degrees)
    static let slightSlumpAngleThreshold: Double = 15.0 // 相对基准前倾 > 15° 为轻度前倾
    static let severeSlumpAngleThreshold: Double = 25.0 // 相对基准前倾 > 25° 为重度驼背
    static let uprightRecoveryAngleThreshold: Double = 10.0 // 相对基准前倾 < 10° 视为恢复挺拔

    // MARK: - 时间滤波与防抖缓冲 (单位: 秒 Seconds)
    static let slumpTriggerBufferDuration: TimeInterval = 10.0 // 低头持续 10 秒才正式触发预警（过滤打字、喝水）
    static let recoveryBufferDuration: TimeInterval = 5.0      // 抬头保持 5 秒才判定为彻底复原
    static let calibrationSampleDuration: TimeInterval = 2.0  // 校准端坐采集时长

    // MARK: - 滑动均值平滑窗口帧数
    static let movingAverageFilterFrameCount: Int = 8

    // MARK: - 人体工学物理负荷力学模型参数 (单位: kg)
    static let neutralHeadWeightKg: Double = 5.0
    static let loadAt15DegreesKg: Double = 12.0
    static let loadAt30DegreesKg: Double = 18.0
    static let loadAt45DegreesKg: Double = 22.0
    static let loadAt60DegreesKg: Double = 27.0
}
