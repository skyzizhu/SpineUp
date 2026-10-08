//
//  SUPostureSession.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 每日姿态监测会话实体 —— 记录单日全量体态监测指标与科学战报数据
struct SUPostureSession: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    let dateString: String // 格式: "yyyy-MM-dd"
    var uprightDurationSec: TimeInterval
    var slumpDurationSec: TimeInterval
    var longestUprightStreakSec: TimeInterval
    var violationsCount: Int
    var accumulatedExtraLoadKg: Double

    init(
        id: UUID = UUID(),
        dateString: String,
        uprightDurationSec: TimeInterval = 0,
        slumpDurationSec: TimeInterval = 0,
        longestUprightStreakSec: TimeInterval = 0,
        violationsCount: Int = 0,
        accumulatedExtraLoadKg: Double = 0
    ) {
        self.id = id
        self.dateString = dateString
        self.uprightDurationSec = uprightDurationSec
        self.slumpDurationSec = slumpDurationSec
        self.longestUprightStreakSec = longestUprightStreakSec
        self.violationsCount = violationsCount
        self.accumulatedExtraLoadKg = accumulatedExtraLoadKg
    }

    /// 总监测时长（秒）
    var totalDurationSec: TimeInterval {
        return uprightDurationSec + slumpDurationSec
    }

    /// 端正挺拔率 (0.0 ~ 1.0)
    var uprightRatio: Double {
        guard totalDurationSec > 0 else { return 1.0 }
        return min(1.0, max(0.0, uprightDurationSec / totalDurationSec))
    }

    /// 骨气健康综合评分 (0 ~ 100 分)
    var score: Int {
        if totalDurationSec < 30 {
            // 时长极短时给予基准鼓励分
            return 95
        }
        // 基于端正率基础分 (最高 70 分) + 违规扣分 (每次扣 3 分) + 连续时长奖励 (最高 15 分)
        let baseRatioScore = uprightRatio * 75.0
        let violationPenalty = min(30.0, Double(violationsCount) * 3.0)
        let streakBonus = min(15.0, (longestUprightStreakSec / 300.0) * 5.0)

        let finalScore = Int(round(baseRatioScore - violationPenalty + streakBonus + 10.0))
        return min(100, max(10, finalScore))
    }

    /// 骨气评级 (S / A / B / C / D)
    var grade: String {
        let s = score
        if s >= 90 { return "S" }
        if s >= 80 { return "A" }
        if s >= 70 { return "B" }
        if s >= 60 { return "C" }
        return "D"
    }

    /// 评级称号
    var gradeTitle: String {
        switch grade {
        case "S": return SULocalized("grade_s_title", default: "铁骨铮铮")
        case "A": return SULocalized("grade_a_title", default: "傲然挺立")
        case "B": return SULocalized("grade_b_title", default: "略显疲态")
        case "C": return SULocalized("grade_c_title", default: "危如累卵")
        default:  return SULocalized("grade_d_title", default: "折叠屏人类")
        }
    }

    /// 格式化挺拔时长文本
    var formattedUprightTime: String {
        return formatTimeInterval(uprightDurationSec)
    }

    /// 格式化低头时长文本
    var formattedSlumpTime: String {
        return formatTimeInterval(slumpDurationSec)
    }

    /// 格式化总监测时长文本
    var formattedTotalTime: String {
        return formatTimeInterval(totalDurationSec)
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            let format = SULocalized("hours_unit", default: "%d小时%d分钟")
            return String(format: format, hours, remainingMinutes)
        } else if minutes > 0 {
            let format = SULocalized("minutes_unit", default: "%d分钟")
            return String(format: format, minutes)
        } else {
            let format = SULocalized("seconds_unit", default: "%d秒")
            return String(format: format, max(1, Int(interval)))
        }
    }
}
