//
//  SUPetPersona.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 宠物性格人格枚举 —— 决定吐槽台词风格、TTS 语调语速及视觉标识
enum SUPetPersona: String, CaseIterable, Identifiable, Sendable {
    case worker = "worker"   // 毒舌打工人
    case cat = "cat"         // 傲娇猫猫
    case coach = "coach"     // 温柔私教

    var id: String { rawValue }

    /// 人格显示名称
    var displayName: String {
        switch self {
        case .worker:
            return "毒舌打工人"
        case .cat:
            return "傲娇猫猫"
        case .coach:
            return "温柔私教"
        }
    }

    /// 标签副标题
    var subtitle: String {
        switch self {
        case .worker:
            return "反内卷 · 人间清醒"
        case .cat:
            return "傲娇 · 猫咪视角"
        case .coach:
            return "鼓励 · 正向引导"
        }
    }

    /// 人格简短描述
    var description: String {
        switch self {
        case .worker:
            return "犀利自嘲，针针见血，催你挺起脊椎继续搬砖。"
        case .cat:
            return "不要趴着压扁本喵！你再驼背我就从你脖子上滑下去了喵！"
        case .coach:
            return "温柔耐心地指引深呼吸与体态复原，守护你的脊椎健康。"
        }
    }

    /// 严格使用苹果原生 SF Symbols
    var iconSystemName: String {
        switch self {
        case .worker:
            return "briefcase.fill"
        case .cat:
            return "cat.fill"
        case .coach:
            return "figure.mind.and.body"
        }
    }

    /// TTS 语音音调 (Pitch Multiplier: 0.5 ~ 2.0，默认 1.0)
    var speechPitchMultiplier: Float {
        switch self {
        case .worker:
            return 1.05
        case .cat:
            return 1.25 // 稍高偏活泼细尖
        case .coach:
            return 0.95 // 沉稳柔和
        }
    }

    /// TTS 语音速率 (Rate: 0.0 ~ 1.0，标准为 0.5)
    var speechRate: Float {
        switch self {
        case .worker:
            return 0.52 // 稍快利落
        case .cat:
            return 0.50
        case .coach:
            return 0.46 // 舒缓有条不紊
        }
    }

    /// 主题代表色彩 Hex
    var themeColorHex: String {
        switch self {
        case .worker:
            return "#FF9500" // 活力亮橙
        case .cat:
            return "#AF52DE" // 傲娇紫色
        case .coach:
            return "#34C759" // 清新薄荷绿
        }
    }

    /// 根据 ID 查找人格，未知时安全回退至打工人
    static func from(id: String) -> SUPetPersona {
        return SUPetPersona(rawValue: id) ?? .worker
    }
}
