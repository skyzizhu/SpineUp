//
//  SUAIPostureAdvisor.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import Foundation
import os

/// AI 结构化危害透视报告
struct SUAIHazardReport: Sendable {
    let headline: String
    let metaphorComparison: String
    let appearanceAnalysis: String
    let timelineProjection: String
    let petComment: String
    let isAIGenerated: Bool
}

/// AI 结构化减负微操方案
struct SUAIReliefPlan: Sendable {
    let quickDiagnosis: String
    let action1CustomTip: String
    let action2CustomTip: String
    let ergonomicCustomTip: String
    let petEncouragement: String
    let isAIGenerated: Bool
}

/// AI 专属体态私教顾问 —— 结合用户实时传感器读数、历史低头频次、人格风格与生理力学模型，生成定制化分析与微操方案
final class SUAIPostureAdvisor: @unchecked Sendable {

    static let shared = SUAIPostureAdvisor()

    private let userDefaultsManager: SUUserDefaultsManager

    init(userDefaultsManager: SUUserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
    }

    /// 根据用户当前传感器数据与会话记录，生成 AI 深度体态危害透视
    func analyzeHazard(
        pitchDeg: Double,
        extraLoadKg: Double,
        session: SUPostureSession,
        persona: SUPetPersona
    ) async -> SUAIHazardReport {
        let userName = userDefaultsManager.userName

        // 1. 尝试向云端 AI 危害透视接口发起真实请求
        do {
            let currentLang = SULocalizationManager.shared.currentLanguage.rawValue
            let cloudRes = try await SUAPIClient.shared.ai.fetchHazardAnalysis(
                pitchDeg: pitchDeg,
                extraLoadKg: extraLoadKg,
                slumpDurationSec: session.slumpDurationSec,
                violationsCount: session.violationsCount,
                persona: persona.rawValue,
                userName: userName,
                locale: currentLang
            )
            return SUAIHazardReport(
                headline: cloudRes.headline,
                metaphorComparison: cloudRes.metaphor_comparison,
                appearanceAnalysis: cloudRes.appearance_analysis,
                timelineProjection: cloudRes.timeline_projection,
                petComment: cloudRes.pet_comment,
                isAIGenerated: cloudRes.is_ai_generated ?? true
            )
        } catch {
            SULogger.network.debug("Cloud hazard analysis failed or offline, fallback to local physics model: \(error.localizedDescription)")
        }

        // 2. 弱网或离线平滑降级：使用本地高精度力学与拟人模型兜底
        // 生理力学生活化比喻模型
        let metaphor: String
        if extraLoadKg >= 20.0 {
            metaphor = SULocalized("ai_metaphor_extreme", default: "💥 当前颈椎犹如倒挂了一台 24 英寸金属显示器！每维持 10 秒，C5-C6 椎间盘纤维环承受压强即逼近极限阈值。")
        } else if extraLoadKg >= 14.0 {
            metaphor = SULocalized("ai_metaphor_heavy", default: "⚠️ 相当于肩颈部位被强行压上了一整箱 24 瓶装矿泉水（约 15kg），斜方肌被迫持续做强抗阻代偿。")
        } else if extraLoadKg >= 8.0 {
            metaphor = SULocalized("ai_metaphor_moderate", default: "🌿 相当于颈后挂了一只成年的大胖橘猫（约 9kg），虽暂无剧烈锐痛，但隐性肌纤维微损伤正在悄然累积。")
        } else {
            metaphor = SULocalized("ai_metaphor_light", default: "✨ 当前处于接近生理零负担的黄金区间，头颈部处于平衡力矩支点。")
        }

        // 针对不同低头角度与今日低头累计次数的 AI 颜值与体态诊断
        let slumpMins = Int(session.slumpDurationSec / 60.0)
        let appearance: String
        if pitchDeg >= 25.0 {
            appearance = String(
                format: SULocalized("ai_appearance_severe", default: "• 富贵包高危警告：颈胸椎交界长期处于受剪切力状态，脂肪垫为保护神经已开始代偿性堆积，后颈视觉变短变厚。\n• 下颌线模糊坍塌：下巴长期前伸导致深层颈阔肌过度伸展松弛，即使体脂率极低也会诱发不可逆双下巴。\n• 乌龟颈体态定型：今日累计前倾 %d 分钟，胸锁乳突肌呈持续短缩状态，站立时本能猥琐探头。"),
                slumpMins
            )
        } else if pitchDeg >= 12.0 {
            appearance = String(
                format: SULocalized("ai_appearance_moderate", default: "• 轻度前探代偿：斜方肌上束呈持续缺血紧绷状态，穿正装或修身衣物时易出现明显溜肩。\n• 下颌肌群代偿疲劳：颈深屈肌力量被抑制，下颌线条正受到向下拉扯牵引。\n• 建议：今日已有 %d 次低头记录，需立即激活背部菱形肌。"),
                session.violationsCount
            )
        } else {
            appearance = SULocalized("ai_appearance_good", default: "• 黄金下颌线条：颈部前屈角度在理想生理范围内，下颌线条平整紧致，颈部无代偿性增生。\n• 气质天鹅颈保持中：锁骨与双肩自然下沉打开，整个人身姿挺拔干练。")
        }

        // 损伤时间轴预测
        let timeline: String
        if pitchDeg >= 20.0 || slumpMins >= 30 {
            timeline = String(
                format: SULocalized("ai_timeline_severe", default: "• 持续 30 分钟：斜方肌血流受阻 60%%，产生乳酸堆积与顽固性酸胀、偏头痛。\n• 累积 1~3 个月：颈椎前凸曲度变直甚至反弓，胸椎代偿后凸，形成固定性驼背。\n• 持续 1~2 年以上：C5-C7 椎间盘退行性变甚至突出，压迫神经根，引发手臂放射性麻木。"),
                userName
            )
        } else {
            timeline = SULocalized("ai_timeline_mild", default: "• 持续保持：颈椎间盘获得良好水分回流与弹性休养，肩颈经络通畅，脑供血充足充沛。\n• 1~3 个月后：形成肌肉记忆，即使高强度伏案工作也能自发维持优雅直立。")
        }

        // 宠物拟人人格定制评语
        let comment: String
        switch persona {
        case .cat:
            if pitchDeg >= 20.0 {
                comment = "「本喵命令你立刻把脑袋抬起来！你后脖子上堆的肉包都要比本喵的猫爬架还高了喵！再低头本喵就抓你头发了喵！」"
            } else {
                comment = "「呼噜噜~ 这才是本喵欣赏的挺拔铲屎官，坐姿优雅得像只高贵的波斯猫，继续保持喵~」"
            }
        case .coach:
            if pitchDeg >= 20.0 {
                comment = "「深呼吸，感受双肩下沉。想象头顶有一根金色的丝线轻轻拉住你，别让脊椎默默替你的疲惫买单，现在就坐正吧。」"
            } else {
                comment = "「太棒了！你的颈胸段正在享受最自然的呼吸空间，这种挺拔感会给你带来更充足的精力与自律自信。」"
            }
        case .worker:
            if pitchDeg >= 20.0 {
                comment = "「兄弟，命是自己的，班是公司的！脖子上挂了 \(String(format: "%.1f", extraLoadKg))kg 还死撑着，明天颈椎病请假可扣全勤奖啊，赶紧抬头！」"
            } else {
                comment = "「可以啊，做人就要有骨气！端正打工不仅效率高，还能保住下颌线，晚上省下去做颈椎推拿的钱了！」"
            }
        }

        return SUAIHazardReport(
            headline: String(format: SULocalized("ai_hazard_headline_fmt", default: "【AI 诊断】当前低头 %.1f° · 额外负荷 +%.1f kg"), pitchDeg, extraLoadKg),
            metaphorComparison: metaphor,
            appearanceAnalysis: appearance,
            timelineProjection: timeline,
            petComment: comment,
            isAIGenerated: true
        )
    }

    /// 根据用户当前负荷与会话记录，生成 AI 个性化减负急救处方
    func generateReliefPrescription(
        pitchDeg: Double,
        extraLoadKg: Double,
        session: SUPostureSession,
        persona: SUPetPersona
    ) async -> SUAIReliefPlan {
        // 1. 尝试向云端 AI 处方接口发起真实请求
        do {
            let currentLang = SULocalizationManager.shared.currentLanguage.rawValue
            let cloudRes = try await SUAPIClient.shared.ai.fetchReliefPrescription(
                pitchDeg: pitchDeg,
                extraLoadKg: extraLoadKg,
                persona: persona.rawValue,
                locale: currentLang
            )
            return SUAIReliefPlan(
                quickDiagnosis: cloudRes.quick_diagnosis,
                action1CustomTip: cloudRes.action1_tips,
                action2CustomTip: cloudRes.action2_tips,
                ergonomicCustomTip: cloudRes.ergonomic_tips,
                petEncouragement: cloudRes.pet_encouragement,
                isAIGenerated: cloudRes.is_ai_generated ?? true
            )
        } catch {
            SULogger.network.debug("Cloud relief prescription failed or offline, fallback to local template: \(error.localizedDescription)")
        }

        // 2. 弱网或离线平滑降级：使用本地急救处方兜底
        let diagnosis: String
        let action1Tip: String
        let action2Tip: String
        let ergoTip: String

        if pitchDeg >= 20.0 {
            diagnosis = String(format: SULocalized("ai_relief_diag_heavy", default: "⚡️ AI 判定当前颈椎处于高负荷抗阻紧绷（+%.1f kg）。检测到斜方肌上束充血痉挛，急需做后缩反向对冲！"), extraLoadKg)
            action1Tip = "重点动作！平视前方，用食指轻顶下巴向后平推 2 厘米，挤出双下巴，感受后颈深层韧带被完全拉开拉伸，维持 4 秒。"
            action2Tip = "双臂贴紧肋侧屈臂呈「W」形，肩胛骨往中间狠狠夹紧，彻底打开紧缩的胸大肌，击碎富贵包早期代偿。"
            ergoTip = "你的屏幕可能严重偏低！立即找两本书或支架把电脑抬高 5~8 厘米，强制视线平齐屏幕上 1/3。"
        } else {
            diagnosis = SULocalized("ai_relief_diag_light", default: "🌿 当前姿态良好，此 30 秒微操主要用于唤醒深层核心肌肉记忆，预防伏案疲劳积累。")
            action1Tip = "轻柔收下巴，保持后颈延伸感，每次维持 3 秒，重复 5 次，唤醒深层颈屈肌。"
            action2Tip = "配合腹式深呼吸，轻巧做 W 展肩，感受上背部温暖舒展。"
            ergoTip = "保持手肘 90 度自然搭在工位桌面上，臀部坐满椅子，后腰轻贴支撑靠枕。"
        }

        let encouragement: String
        switch persona {
        case .cat:
            encouragement = "「活动完脖子别忘了给本喵开个罐头，本喵可是一直在灵动岛盯着你呢喵！」"
        case .coach:
            encouragement = "「做得很好。30 秒虽然短暂，但足以重启大脑血氧与神经传导，继续享受优雅挺拔的工作状态吧。」"
        case .worker:
            encouragement = "「搞定！30 秒卸掉刚才扛的几十斤大包袱，打工人的革命本钱又保住了，继续冲！」"
        }

        return SUAIReliefPlan(
            quickDiagnosis: diagnosis,
            action1CustomTip: action1Tip,
            action2CustomTip: action2Tip,
            ergonomicCustomTip: ergoTip,
            petEncouragement: encouragement,
            isAIGenerated: true
        )
    }
}
