//
//  SULeaderboardModel.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import Foundation

/// 排行榜展示条目模型
struct SULeaderboardEntry: Identifiable, Codable {
    let id: String
    let rank: Int
    let userName: String
    let personaId: String
    let energyCoins: Int
    let uprightRatioPercent: Int   // 挺拔质量优秀率 (例如 96%)
    let streakDays: Int            // 连续达标天数
    let isCurrentUser: Bool
    let tag: String?               // 特殊称号 (如 "天鹅颈榜首", "连续打卡王")
}

/// 排行榜分类维度
enum SULeaderboardCategory: Int, CaseIterable {
    case energyCoins = 0     // 骨气能量总榜
    case postureQuality = 1  // 挺拔大师榜 (优秀率)
    case streakDays = 2      // 连胜毅力榜

    var localizedTitle: String {
        switch self {
        case .energyCoins:
            return SULocalized("leaderboard_tab_energy", default: "骨气能量榜")
        case .postureQuality:
            return SULocalized("leaderboard_tab_quality", default: "挺拔大师榜")
        case .streakDays:
            return SULocalized("leaderboard_tab_streak", default: "连续毅力榜")
        }
    }
}
