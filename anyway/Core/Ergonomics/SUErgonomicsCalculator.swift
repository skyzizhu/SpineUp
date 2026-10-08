//
//  SUErgonomicsCalculator.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 趣味生活化换算对应实体 —— 严格使用原生 SF Symbols
struct SUEquivalentItem: Sendable, Equatable {
    let name: String
    let count: Double
    let unit: String
    let iconSystemName: String // 严格使用 SF Symbol
    let descriptionText: String

    var formattedCount: String {
        return String(format: "%.1f", count)
    }
}

/// 颈椎力学与生活化受力换算计算器 —— 根据医学人体工学常模计算颈椎承重与等效物
enum SUErgonomicsCalculator {

    /// 根据头部相对俯仰角度（度数）计算颈椎瞬间承受的总负荷（kg）
    /// - Parameter pitchDeg: 俯仰角绝对值（度数）
    /// - Returns: 颈椎总承重（kg，中立位约 5kg）
    static func calculateInstantLoadKg(pitchDeg: Double) -> Double {
        let absDeg = max(0.0, abs(pitchDeg))
        if absDeg <= 0.0 {
            return 5.0
        } else if absDeg <= 15.0 {
            // 0°~15° 线性插值 5.0 -> 12.0
            return 5.0 + (absDeg / 15.0) * 7.0
        } else if absDeg <= 30.0 {
            // 15°~30° 线性插值 12.0 -> 18.0
            return 12.0 + ((absDeg - 15.0) / 15.0) * 6.0
        } else if absDeg <= 45.0 {
            // 30°~45° 线性插值 18.0 -> 22.0
            return 18.0 + ((absDeg - 30.0) / 15.0) * 4.0
        } else if absDeg <= 60.0 {
            // 45°~60° 线性插值 22.0 -> 27.0
            return 22.0 + ((absDeg - 45.0) / 15.0) * 5.0
        } else {
            // 超过 60° 封顶 30.0 kg
            return min(30.0, 27.0 + ((absDeg - 60.0) / 30.0) * 3.0)
        }
    }

    /// 计算相对中立位 (5kg) 的额外多承受负荷 (kg)
    static func calculateExtraLoadKg(pitchDeg: Double) -> Double {
        let total = calculateInstantLoadKg(pitchDeg: pitchDeg)
        return max(0.0, total - 5.0)
    }

    /// 将累计额外承重 (kg · 累计换算量) 转换为生活化趣味比喻
    /// - Parameter accumulatedKg: 累计额外等效公斤数
    /// - Returns: 生活化实体对象
    static func calculateEquivalentItem(accumulatedKg: Double) -> SUEquivalentItem {
        let kg = max(0.2, accumulatedKg)

        // 根据重量区间选择最贴切有趣的生活化道具
        if kg < 2.0 {
            // 奶茶 (约 0.5 kg/杯)
            let cups = kg / 0.5
            let descFormat = SULocalized("equiv_tea", default: "相当于脖子上挂了 %.1f 杯全糖大杯珍珠奶茶")
            return SUEquivalentItem(
                name: "珍珠奶茶",
                count: cups,
                unit: "杯",
                iconSystemName: "cup.and.saucer.fill",
                descriptionText: String(format: descFormat, cups)
            )
        } else if kg < 6.0 {
            // 红砖 (约 2.5 kg/块)
            let bricks = kg / 2.5
            let descFormat = SULocalized("equiv_brick", default: "相当于颈椎上顶了 %.1f 块实心建筑红砖")
            return SUEquivalentItem(
                name: "建筑红砖",
                count: bricks,
                unit: "块",
                iconSystemName: "square.stack.3d.down.forward.fill",
                descriptionText: String(format: descFormat, bricks)
            )
        } else if kg < 12.0 {
            // 猫咪 (约 4.0 kg/只)
            let cats = kg / 4.0
            let descFormat = SULocalized("equiv_cat", default: "相当于脖子上趴了 %.1f 只沉甸甸的成年胖猫")
            return SUEquivalentItem(
                name: "成年胖橘猫",
                count: cats,
                unit: "只",
                iconSystemName: "cat.fill",
                descriptionText: String(format: descFormat, cats)
            )
        } else if kg < 25.0 {
            // 柴犬 (约 10.0 kg/只)
            let dogs = kg / 10.0
            let descFormat = SULocalized("equiv_dog", default: "相当于脖子上驮了 %.1f 只健硕的柴犬")
            return SUEquivalentItem(
                name: "活泼柴犬",
                count: dogs,
                unit: "只",
                iconSystemName: "pawprint.fill",
                descriptionText: String(format: descFormat, dogs)
            )
        } else {
            // 健身哑铃 (约 15.0 kg/个)
            let dumbbells = kg / 15.0
            let descFormat = SULocalized("equiv_dumbbell", default: "相当于给颈椎绑了 %.1f 个 15kg 重型纯铁哑铃")
            return SUEquivalentItem(
                name: "重型哑铃",
                count: dumbbells,
                unit: "个",
                iconSystemName: "dumbbell.fill",
                descriptionText: String(format: descFormat, dumbbells)
            )
        }
    }
}
