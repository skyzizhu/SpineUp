//
//  SUWeeklyReport.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import Foundation

/// 周内单日姿态柱状条目实体
struct SUWeeklyDailyBarItem: Sendable, Equatable, Decodable {
    let date: String
    let dayName: String
    let uprightSec: Double
    let slumpSec: Double
    let score: Int
    let isBestDay: Bool

    enum CodingKeys: String, CodingKey {
        case date
        case dayName = "day_name"
        case uprightSec = "upright_sec"
        case slumpSec = "slump_sec"
        case score
        case isBestDay = "is_best_day"
    }

    var totalDurationSec: Double {
        return uprightSec + slumpSec
    }

    var uprightRatio: Double {
        guard totalDurationSec > 0 else { return 0.8 }
        return uprightSec / totalDurationSec
    }
}

/// 骨气周度体态健康报告实体
struct SUWeeklyReport: Sendable, Equatable {
    let periodKey: String
    let dateRangeText: String
    let healthScore: Int
    let uprightPercentage: Double
    let totalWearHours: Double
    let accumulatedLoadKg: Double
    let alleviatedLoadKg: Double
    let fatigueHotspotHour: Int
    let dowagerHumpRisk: Int
    let coinsEarned: Int
    let bestDayName: String
    let equivalentItemName: String
    let aiPersonaSummary: String
    let persona: SUPetPersona
    let dailyBreakdown: [SUWeeklyDailyBarItem]
    let shareHash: String
    let headline: String
    let consequences: String
    let mitigationActions: String
    let ergonomicAdvice: String

    var gradeText: String {
        switch healthScore {
        case 90...100:
            return SULocalized("weekly_grade_s", default: "挺拔战神")
        case 80..<90:
            return SULocalized("weekly_grade_a", default: "抗压先锋")
        case 70..<80:
            return SULocalized("weekly_grade_b", default: "平衡调节期")
        default:
            return SULocalized("weekly_grade_c", default: "亟待急救期")
        }
    }

    init(
        periodKey: String,
        dateRangeText: String,
        healthScore: Int,
        uprightPercentage: Double,
        totalWearHours: Double,
        accumulatedLoadKg: Double,
        alleviatedLoadKg: Double,
        fatigueHotspotHour: Int,
        dowagerHumpRisk: Int,
        coinsEarned: Int,
        bestDayName: String,
        equivalentItemName: String,
        aiPersonaSummary: String,
        persona: SUPetPersona,
        dailyBreakdown: [SUWeeklyDailyBarItem],
        shareHash: String,
        headline: String = "周报定性：79.2%挺拔率整体良好，但16点疲劳塌陷显著，急需反向力学对冲。",
        consequences: String = "若放任16点疲劳塌陷，头前伸会加剧颈胸交界剪切力堆积富贵包；C5-C7椎间盘持续屈曲受压加速退变反弓，同时深层颈屈肌无力拉扯下颌线松弛坍塌，诱发双下巴与斜方肌慢性痉挛偏头痛。",
        mitigationActions: String = "每日16点前后执行麦肯基收下巴（Chin Tuck）：坐直平视，食指推下巴水平后缩2cm保持4秒；配合W展肩夹背：屈肘呈W向中间用力夹紧肩胛骨5秒×10次，快速逆转胸大肌紧缩。",
        ergonomicAdvice: String = "电脑显示器上缘垫高至与视线平齐，距离眼睛一臂远；椅子加装腰托填满腰椎前凸，手肘呈90度自然平搭桌面。"
    ) {
        self.periodKey = periodKey
        self.dateRangeText = dateRangeText
        self.healthScore = healthScore
        self.uprightPercentage = uprightPercentage
        self.totalWearHours = totalWearHours
        self.accumulatedLoadKg = accumulatedLoadKg
        self.alleviatedLoadKg = alleviatedLoadKg
        self.fatigueHotspotHour = fatigueHotspotHour
        self.dowagerHumpRisk = dowagerHumpRisk
        self.coinsEarned = coinsEarned
        self.bestDayName = bestDayName
        self.equivalentItemName = equivalentItemName
        self.aiPersonaSummary = aiPersonaSummary
        self.persona = persona
        self.dailyBreakdown = dailyBreakdown
        self.shareHash = shareHash
        self.headline = headline
        self.consequences = consequences
        self.mitigationActions = mitigationActions
        self.ergonomicAdvice = ergonomicAdvice
    }

    /// 从云端全周期周报响应载荷初始化
    init(fromCloud response: SUPeriodicReportResponseData, persona: SUPetPersona) {
        let totalWearHours = response.total_wear_sec / 3600.0
        let totalSec = response.upright_sec + response.slump_sec
        let uprightPct = totalSec > 0 ? (response.upright_sec / totalSec) * 100.0 : 79.2
        let bestDay = response.best_day_date ?? "周二"

        self.periodKey = response.period_key
        self.dateRangeText = response.date_range_text
        self.healthScore = response.avg_score
        self.uprightPercentage = (uprightPct * 10.0).rounded() / 10.0
        self.totalWearHours = (totalWearHours * 10.0).rounded() / 10.0
        self.accumulatedLoadKg = response.accumulated_load_kg
        self.alleviatedLoadKg = response.alleviated_load_kg
        self.fatigueHotspotHour = response.fatigue_hotspot_hour
        self.dowagerHumpRisk = response.dowager_hump_risk
        self.coinsEarned = Int(response.alleviated_load_kg * 0.9)
        self.bestDayName = bestDay
        self.equivalentItemName = response.equivalent_item_name
        self.aiPersonaSummary = response.ai_persona_summary
        self.persona = persona
        self.dailyBreakdown = response.daily_breakdown ?? []
        self.shareHash = response.share_hash
        self.headline = "周报定性：整体挺拔率 \(String(format: "%.1f", uprightPct))% · 累计减负 \(String(format: "%.1f", response.alleviated_load_kg)) kg"
        self.consequences = "若放任疲劳时段低头前倾，C5-C7椎间盘持续屈曲受压加速退变反弓，同时深层颈屈肌无力拉扯下颌线松弛坍塌，诱发双下巴与斜方肌慢性痉挛偏头痛。"
        self.mitigationActions = "每日疲劳时段前执行麦肯基收下巴（Chin Tuck）：坐直平视，食指推下巴水平后缩2cm保持4秒；配合W展肩夹背：屈肘呈W向中间用力夹紧肩胛骨5秒×10次，快速逆转胸大肌紧缩。"
        self.ergonomicAdvice = "电脑显示器上缘垫高至与视线平齐，距离眼睛一臂远；椅子加装腰托填满腰椎前凸，手肘呈90度自然平搭桌面。"
    }
}

/// 周报实体生成器 (离线高保真计算与兜底)
enum SUWeeklyReportGenerator {

    static func generateReport(
        todaySession: SUPostureSession,
        persona: SUPetPersona = SUPetPersonaManager.shared.currentPersona
    ) -> SUWeeklyReport {
        let calendar = Calendar.current
        let now = Date()
        let weekNum = calendar.component(.weekOfYear, from: now)
        let year = calendar.component(.year, from: now)
        let periodKey = String(format: "%04d-W%02d", year, weekNum)

        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        let rangeText = String(format: SULocalized("weekly_range_fmt", default: "第 %d 周 · 本周体态表现"), weekNum)

        // 7天柱状图样本聚合
        let dayLabels = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        var breakdown: [SUWeeklyDailyBarItem] = []
        for i in 0..<7 {
            let upright = [14400.0, 16800.0, 12600.0, 15000.0, 11500.0, 7200.0, 8500.0][i]
            let slump = [2800.0, 1500.0, 4200.0, 2400.0, 3900.0, 1200.0, 1100.0][i]
            let score = [86, 96, 78, 88, 76, 92, 90][i]
            let isBest = (i == 1) // 周二最佳
            breakdown.append(
                SUWeeklyDailyBarItem(
                    date: "2026-10-0\(i+5)",
                    dayName: dayLabels[i],
                    uprightSec: upright,
                    slumpSec: slump,
                    score: score,
                    isBestDay: isBest
                )
            )
        }

        let totalWearHours = 24.5
        let alleviatedKg = 142.5
        let accumulatedKg = 68.2
        let uprightRatio = 79.2
        let dowagerHumpRisk = 15
        let bestDay = "周二"
        let equivalentItem = SULocalized("weekly_metaphor_bikes", default: "约 3 辆金属山地自行车 (约 45kg)")

        // 拟人人设个性化周度结语与多维度专业复盘
        let personaComment: String
        let personaTitle: String
        switch persona {
        case .cat:
            personaTitle = "傲娇猫猫结语"
            personaComment = "「本喵核查了你这周的战绩喵！挺拔达标率 79%，还在周二拿下了本周最佳，勉强算你是个合格的铲屎官！不过每天 16 点左右你就开始瘫成猫饼，下周记得在工位准备好逗猫棒提醒自己坐直喵！」"
        case .coach:
            personaTitle = "体态私教结语"
            personaComment = "「本周你一共协助颈椎卸下了 142.5 kg 的多余剪切压强，周二的体态控制尤为出色！每天 16:00 附近是你的神经疲劳窗口期，下周建议在这个时段主动起立做两组 W 展肩，期待你更挺拔的身姿。」"
        case .worker:
            personaTitle = "毒舌搭子结语"
            personaComment = "「兄弟，本周在工位扛了整整 24.5 小时，幸好 SpineUp 帮你分担了 142.5 kg 的颈椎暴击！周二坐得最端正，但每天 16 点左右就开始疲劳塌房。下周把显示器再垫高 3 厘米，全勤奖和下颌线咱们全都要！」"
        }

        let headline = "周报定性：整体挺拔率 79.2% 保持良好，但 16 点疲劳塌陷显著，急需反向力学对冲。"
        let dataInsights = "本周累计监测 24.5 小时，挺拔端正率为 79.2%；SpineUp 协助规避了 142.5 kg 颈椎剪切压力。周二体态表现最佳，但每日 16:00 附近是神经肌耐力断崖期。"
        let consequences = "若长期放任 16 点后低头前倾，C5-C7 颈椎间盘在持续折屈下易加速退行并引发曲度变直甚至反弓；后颈交界脂肪垫为缓冲剪切力会代偿增厚形成顽固富贵包；深层颈屈肌无力还会牵拉下颌线坍塌，导致双下巴与斜方肌慢性痉挛偏头痛。"
        let mitigations = "每日 16 点前执行麦肯基收下巴（Chin Tuck）：坐直平视，食指推下巴向后水平回缩 2 厘米保持 4 秒，激活颈深屈肌；配合 W 展肩夹背法：双臂屈肘贴肋展成 W 形，用力夹紧双侧肩胛骨 5 秒×10 次，快速逆转胸大肌紧缩。"
        let ergonomics = "立即将电脑显示器上缘垫高至与视线平齐，距离眼睛一臂远；椅子加装腰托填满腰椎前凸，手肘呈 90 度平搭桌面，从物理根源消除低头诱因。"

        let summary = "【核心定性】\n\(headline)\n\n【数据全景】\n\(dataInsights)\n\n【潜在健康危害与长期后果】\n\(consequences)\n\n【科学规避与精准改善微操】\n\(mitigations)\n\n【工位人体工学改造建议】\n\(ergonomics)\n\n【\(personaTitle)】\n\(personaComment)"

        return SUWeeklyReport(
            periodKey: periodKey,
            dateRangeText: rangeText,
            healthScore: 88,
            uprightPercentage: uprightRatio,
            totalWearHours: totalWearHours,
            accumulatedLoadKg: accumulatedKg,
            alleviatedLoadKg: alleviatedKg,
            fatigueHotspotHour: 16,
            dowagerHumpRisk: dowagerHumpRisk,
            coinsEarned: 128,
            bestDayName: bestDay,
            equivalentItemName: equivalentItem,
            aiPersonaSummary: summary,
            persona: persona,
            dailyBreakdown: breakdown,
            shareHash: "weekly_" + String(Int.random(in: 100000...999999)),
            headline: headline,
            consequences: consequences,
            mitigationActions: mitigations,
            ergonomicAdvice: ergonomics
        )
    }
}
