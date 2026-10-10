//
//  SUPracticeActionType.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SwiftUI

/// 30 秒办公室减负微操动作定义
enum SUPracticeActionType: Int, CaseIterable, Sendable {
    case chinTuck = 0  // 动作 1：麦肯基收下巴 (15s)
    case wStretch = 1  // 动作 2：W 展肩夹背 (15s)

    var title: String {
        switch self {
        case .chinTuck:
            return SULocalized("practice_action1_title", default: "麦肯基收下巴")
        case .wStretch:
            return SULocalized("practice_action2_title", default: "W 展肩夹背")
        }
    }

    var stepIndicatorText: String {
        switch self {
        case .chinTuck:
            return SULocalized("practice_step_1", default: "动作 1/2 (15s)")
        case .wStretch:
            return SULocalized("practice_step_2", default: "动作 2/2 (15s)")
        }
    }

    var tagText: String {
        switch self {
        case .chinTuck:
            return SULocalized("practice_action1_tag", default: "告别乌龟颈 · 激活颈深肌")
        case .wStretch:
            return SULocalized("practice_action2_tag", default: "打开胸椎 · 击碎富贵包")
        }
    }

    var themeColor: UIColor {
        switch self {
        case .chinTuck:
            return .systemOrange
        case .wStretch:
            return .systemBlue
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .chinTuck:
            return Color.orange
        case .wStretch:
            return Color.blue
        }
    }

    var iconSystemName: String {
        switch self {
        case .chinTuck:
            return "figure.mind.and.body"
        case .wStretch:
            return "figure.flexibility"
        }
    }

    var instructions: [String] {
        switch self {
        case .chinTuck:
            return [
                SULocalized("practice_action1_step1", default: "坐正平视正前方，背部放松微靠"),
                SULocalized("practice_action1_step2", default: "食指轻触下巴，水平向后平行推送（挤出双下巴感）"),
                SULocalized("practice_action1_step3", default: "感受后颈温和拉伸，保持 3 秒后还原放松")
            ]
        case .wStretch:
            return [
                SULocalized("practice_action2_step1", default: "双臂大臂贴紧肋侧，小臂向上屈起呈「W」形"),
                SULocalized("practice_action2_step2", default: "双肩自然下沉，缓慢将两块肩胛骨往中间夹紧"),
                SULocalized("practice_action2_step3", default: "配合深吸气停留 5 秒后呼气放松还原")
            ]
        }
    }

    /// 获取对应性格特征在当前动作下的台词
    func dialogue(for persona: SUPetPersona) -> String {
        switch (self, persona) {
        case (.chinTuck, .worker):
            return SULocalized("practice_dialogue_chin_worker", default: "坐正平视！把头向后缩，把今天低头看老板微信的窝囊气全收回去！")
        case (.chinTuck, .cat):
            return SULocalized("practice_dialogue_chin_cat", default: "喵呜~ 平视前方，用小肉垫把下巴水平往后推，挤出可爱的双下巴喵！")
        case (.chinTuck, .coach):
            return SULocalized("practice_dialogue_chin_coach", default: "坐直身体，食指轻推下巴水平后移，感受后颈深层肌肉被轻柔拉伸~")

        case (.wStretch, .worker):
            return SULocalized("practice_dialogue_w_worker", default: "大臂贴肋骨，双肩向后死命夹！狠狠粉碎工位长出来的富贵包！")
        case (.wStretch, .cat):
            return SULocalized("practice_dialogue_w_cat", default: "换姿势啦喵！双爪举成 W 字形，把两只小翅膀在后背用力夹紧！")
        case (.wStretch, .coach):
            return SULocalized("practice_dialogue_w_coach", default: "做得很好！双臂弯曲呈 W 形，肩胛骨向中线收拢，深吸气保持住~")
        }
    }

    /// 动作即将完成（最后 3 秒冲刺）台词
    static func sprintDialogue(for persona: SUPetPersona) -> String {
        switch persona {
        case .worker:
            return SULocalized("practice_sprint_worker", default: "最后 3 秒撑住！脊椎挺直了，下班才有力气跑路！")
        case .cat:
            return SULocalized("practice_sprint_cat", default: "最后 3 秒冲刺喵！挺拔起来，本喵马上要坐在你头顶啦！")
        case .coach:
            return SULocalized("practice_sprint_coach", default: "最后 3 秒保持深呼吸，马上卸下颈椎所有的额外承重啦~")
        }
    }

    /// 完成结算时的热烈鼓励台词
    static func completionDialogue(for persona: SUPetPersona) -> String {
        switch persona {
        case .worker:
            return SULocalized("practice_completed_worker", default: "大功告成！颈椎额外承重清空，+5 骨气能量到账，干得漂亮！")
        case .cat:
            return SULocalized("practice_completed_cat", default: "太棒啦喵！颈椎变轻盈啦，赏你 +5 骨气能量，记得每天都要跟本喵练哦！")
        case .coach:
            return SULocalized("practice_completed_coach", default: "非常完美！颈椎压力已被成功卸载，恭喜获得 +5 骨气能量奖励！")
        }
    }
}
