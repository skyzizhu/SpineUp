//
//  SUPostureContext.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 触发提醒时的体态与环境动态上下文 —— 作为 AI 生成个性化台词的输入参数
struct SUPostureContext: Sendable {
    /// 相对基准零点的低头俯仰角（绝对值，度数）
    let angleDeg: Double

    /// 持续低头时长（秒）
    let durationSec: TimeInterval

    /// 当天累计低头违规次数
    let violationCountToday: Int

    /// 当前时间戳
    let currentTime: Date

    /// 目标宠物人格
    let persona: SUPetPersona

    /// 连续挺拔打卡天数
    let streakDays: Int

    /// 体态状态 (upright / slightSlump / severeSlump)
    let state: SUPostureState

    /// 物理额外承重 (kg)
    let extraLoadKg: Double

    /// 是否处于深夜/加班时段 (21:00 ~ 次日 06:00)
    var isLateNight: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        return hour >= 21 || hour < 6
    }

    /// 是否为今天首次犯规
    var isFirstViolation: Bool {
        return violationCountToday <= 1
    }

    /// 是否多次反复低头（>= 4 次）
    var isRepeatedViolation: Bool {
        return violationCountToday >= 4
    }

    init(
        angleDeg: Double,
        durationSec: TimeInterval = 10.0,
        violationCountToday: Int = 1,
        currentTime: Date = Date(),
        persona: SUPetPersona,
        streakDays: Int = 1,
        state: SUPostureState,
        extraLoadKg: Double = 0.0
    ) {
        self.angleDeg = angleDeg
        self.durationSec = durationSec
        self.violationCountToday = violationCountToday
        self.currentTime = currentTime
        self.persona = persona
        self.streakDays = streakDays
        self.state = state
        self.extraLoadKg = extraLoadKg
    }
}
