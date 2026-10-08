//
//  SUDailyReportGenerator.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 今日骨气病历单结果实体
struct SUDailyReport: Sendable, Equatable {
    let id: UUID
    let session: SUPostureSession
    let persona: SUPetPersona
    let equivalentItem: SUEquivalentItem
    let diagnosisTitle: String
    let doctorPrescription: String
    let personaComment: String
    let dateFormattedText: String

    init(
        id: UUID = UUID(),
        session: SUPostureSession,
        persona: SUPetPersona,
        equivalentItem: SUEquivalentItem,
        diagnosisTitle: String,
        doctorPrescription: String,
        personaComment: String,
        dateFormattedText: String = ""
    ) {
        self.id = id
        self.session = session
        self.persona = persona
        self.equivalentItem = equivalentItem
        self.diagnosisTitle = diagnosisTitle
        self.doctorPrescription = doctorPrescription
        self.personaComment = personaComment
        self.dateFormattedText = dateFormattedText.isEmpty ? SUPostureSessionManager.todayDateString() : dateFormattedText
    }
}

/// 今日骨气病历单与战报生成器 —— 结合力学换算与拟人人设生成趣味医学诊断书
enum SUDailyReportGenerator {

    static func generateReport(
        session: SUPostureSession,
        persona: SUPetPersona = SUPetPersonaManager.shared.currentPersona
    ) -> SUDailyReport {
        let equivalent = SUErgonomicsCalculator.calculateEquivalentItem(accumulatedKg: session.accumulatedExtraLoadKg)
        let grade = session.grade

        let diagnosisTitle = selectDiagnosisTitle(grade: grade, session: session)
        let prescription = selectPrescription(grade: grade)
        let personaComment = selectPersonaComment(grade: grade, persona: persona, session: session)

        return SUDailyReport(
            session: session,
            persona: persona,
            equivalentItem: equivalent,
            diagnosisTitle: diagnosisTitle,
            doctorPrescription: prescription,
            personaComment: personaComment
        )
    }

    private static func selectDiagnosisTitle(grade: String, session: SUPostureSession) -> String {
        switch grade {
        case "S":
            return SULocalized("diagnosis_s", default: "优秀脊椎自律模范标兵")
        case "A":
            return SULocalized("diagnosis_a", default: "轻度劳损抵抗型体态")
        case "B":
            return SULocalized("diagnosis_b", default: "阶段性打工低头综合征")
        case "C":
            return SULocalized("diagnosis_c", default: "重度地心引力依恋症候群")
        default:
            return SULocalized("diagnosis_d", default: "晚期折叠屏人类蜕变期")
        }
    }

    private static func selectPrescription(grade: String) -> String {
        switch grade {
        case "S":
            return SULocalized("prescription_s", default: "处方：继续保持！骨气傲然，建议每周犒赏自己一杯奶茶以示表彰。")
        case "A":
            return SULocalized("prescription_a", default: "处方：每日远眺 2 次，工作间隙做 3 组抗阻力扩胸拉伸动作。")
        case "B":
            return SULocalized("prescription_b", default: "处方：立即执行深呼吸 3 次，将电脑屏幕垫高 5 厘米，避免下巴前凸。")
        case "C":
            return SULocalized("prescription_c", default: "处方：建议每工作 45 分钟起立活动 2 分钟，仰望天花板 20 秒释放颈椎压力。")
        default:
            return SULocalized("prescription_d", default: "处方：紧急呼叫理疗师！严格遵从宠物提醒，违规一次罚收小鱼干/扣骨气币！")
        }
    }

    private static func selectPersonaComment(grade: String, persona: SUPetPersona, session: SUPostureSession) -> String {
        switch persona {
        case .worker:
            switch grade {
            case "S", "A":
                return SULocalized("comment_worker_s_a", default: "今天脊椎挺得比公司的年终报表还漂亮，下班直接昂首阔步走！")
            case "B":
                return SULocalized("comment_worker_b", default: "今天脖子挂了这么多额外负担，老板是不会给换颈椎报销的，明天坐直点！")
            default:
                return SULocalized("comment_worker_c_d", default: "你这驼背弧度，比周五晚上的下班路还要曲折！赶紧把头拔起来！")
            }

        case .cat:
            switch grade {
            case "S", "A":
                return SULocalized("comment_cat_s_a", default: "今天表现不错喵！本喵趴在你肩膀上睡得很安稳，赏你一声呼噜喵~")
            case "B":
                return SULocalized("comment_cat_b", default: "今天你总是想把本喵压扁成猫饼喵！明天再低头就伸爪子挠你了喵！")
            default:
                return SULocalized("comment_cat_c_d", default: "救命喵！！今天本喵被你压得快喘不过气了喵！快给本喵开十罐罐头赔罪喵！")
            }

        case .coach:
            switch grade {
            case "S", "A":
                return SULocalized("comment_coach_s_a", default: "太棒了！你的肌肉记忆正在逐步形成，端正挺拔是最美好的自我呵护。")
            case "B":
                return SULocalized("comment_coach_b", default: "今天稍微有些疲劳呢，今晚睡前记得做一次颈部热敷与轻柔拉伸。")
            default:
                return SULocalized("comment_coach_c_d", default: "身体在向你发出呼救信号了，别太勉强自己，放下手机，好好呼吸放松吧。")
            }
        }
    }
}
