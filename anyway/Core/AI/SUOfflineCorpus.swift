//
//  SUOfflineCorpus.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 离线高频台词语料库 —— 在无网络或云端请求超时时提供智能匹配的拟人台词
enum SUOfflineCorpus {

    // MARK: - 毒舌打工人语料
    private static let workerSlightSlump: [String] = [
        "老板给你发工资，可没包含换颈椎的医保报销，头抬起来！",
        "又低头了？你那几千块的月薪，配得上脖子上挂这十几斤重担吗？",
        "屏幕里是有金矿还是有年终奖？脖子往前伸得像只愤怒的土拨鼠。",
        "打工人，挺起胸膛！低头看手机不会让代码自己写完，只会让富贵包先长出来。",
        "别把头埋进键盘里，你的脊椎已经在大声报警了！",
        "姿势越卑微，离财富自由越遥远。把下巴收一收！",
        "别驼着了，屏幕上的 bug 不会因为你靠近 5 厘米就自己修复。",
        "看看你的脊椎曲线，比公司的股价走势还要坎坷，赶紧坐正！"
    ]

    private static let workerSevereSlump: [String] = [
        "警告！你现在低头都快趴桌子上了，颈椎额外承重整整 20 公斤！你想被当成折叠屏送修吗？",
        "垮掉了！整个人瘫得像周五下午三点半的咖啡渣！立刻给我挺起来！",
        "你再这么驼下去，下次体检医生直接给你脊椎颁发全勤奖了！抬起头！",
        "重度驼背警告！我这只打工宠都快被你压成二维平面生物了！",
        "你的脊椎在向你索赔精神损失费！立刻深呼吸，把头拔起来！"
    ]

    private static let workerLateNight: [String] = [
        "都几点了还在死磕？命是自己的，脊椎也是自己的，抬头喝口水准备下班吧！",
        "深夜加班就算了，还把自己驼成问号，明天上班打算坐轮椅去吗？抬起头！",
        "加班的尽头是骨科门诊。坐正！至少别让医生嫌弃你的坐姿。"
    ]

    private static let workerRepeated: [String] = [
        "今天第 {count} 次低头犯规了！再驼背，我要以宠物的名义扣你今日能量币了！",
        "反复犯规！你的下巴是有地心引力追踪器吗？给我收回来！",
        "第 {count} 次提醒！你对驼背的执着要是用在搞钱上，早退休了！"
    ]

    private static let workerRecovery: [String] = [
        "这才像个有骨气的人嘛！保持住，精神气直接翻倍！",
        "挺拔了！连周围的空气都变得通透了，继续保持！",
        "这就对了！挺起胸膛，做整条街最优雅的打工人！"
    ]

    // MARK: - 傲娇猫猫语料
    private static let catSlightSlump: [String] = [
        "喂！你头往下倾斜，本喵要在你头顶上滑下去了喵！",
        "不要弯腰驼背啦，本喵的肉垫都快没地方踩了喵！",
        "喵呜！你头低下去 15 度，本喵就少看了一只小飞虫，快坐正喵！",
        "你是不是想把本喵压成猫饼？本喵可不答应，快抬起下巴喵！",
        "笨蛋两脚兽，本喵盯了你半天了，把背挺直一点喵！",
        "再不好好坐，今天晚上本喵就不踩奶了喵！"
    ]

    private static let catSevereSlump: [String] = [
        "喵呜哇！！压扁了！压扁猫了！！快把头抬起来，要窒息了喵！！",
        "超级严重的大驼背！本喵的尾巴都被你挤弯了喵！立刻抬头！",
        "你是猫还是我是猫？怎么整个人瘫软得像一滩液体猫咪一样喵？！坐正！",
        "救命喵！头上承受了快二十公斤！本喵生气了，爪子要亮出来了喵！",
        "快抬起头来喵！再趴着我就直接伸爪子挠你下巴了喵！"
    ]

    private static let catLateNight: [String] = [
        "夜深了喵……本喵都要困扁了，你还低头看发光的屏幕，快坐正然后睡觉喵！",
        "好黑喵，你头低得像个幽灵猫，快抬头伸个懒腰，本喵陪你伸个懒腰喵！"
    ]

    private static let catRepeated: [String] = [
        "今天都第 {count} 次了喵！本喵的耐心是有限的，快收下巴喵！",
        "又是第 {count} 次驼背！本喵要扣掉你的小鱼干份额了喵！"
    ]

    private static let catRecovery: [String] = [
        "呼……这样舒服多了喵，本喵勉强赏你一个赞许的眼神喵~",
        "保持端正挺拔，本喵趴在你肩膀上才安心喵！",
        "对嘛对嘛，这样才是合格的铲屎官姿态喵！"
    ]

    // MARK: - 温柔私教语料
    private static let coachSlightSlump: [String] = [
        "来，深吸一口气，轻轻收紧核心，把头顶向上延展。",
        "注意一下颈椎哦，想象头顶有一根线在轻轻拉着你向上拔高。",
        "稍微有些前倾了呢，把双肩向后展开，让胸腔自然打开。",
        "很好，现在放松斜方肌，下巴微收，让颈部回归中立位。",
        "久坐容易疲劳，跟着我做一次缓慢深呼吸，把背部轻轻挺直。",
        "感觉到了吗？头部回正时，整个脊椎的压力瞬间减轻了。"
    ]

    private static let coachSevereSlump: [String] = [
        "停一下手中的动作，现在前倾角度已经比较大了，颈椎正在承受沉重负担哦。",
        "深呼吸，慢慢抬起头，双肩下沉，感受脊椎由下至上的舒展延展。",
        "现在的坐姿对颈椎压迫很明显呢，让我们一起挺胸抬头，做三次缓慢深呼吸。",
        "请轻缓地将颈部回正，感受胸椎的挺拔与放松，你做得很棒，慢慢来。",
        "身体在向你发出疲劳信号了，把视线平移抬高，给自己脊椎一个拥抱吧。"
    ]

    private static let coachLateNight: [String] = [
        "夜深了，专注的同时别忘了善待身体。轻轻做个肩颈环绕，抬头望向远方吧。",
        "这么晚还在坚持，真为你骄傲。但也要给颈椎放松的空间，收收下巴，保持舒展。"
    ]

    private static let coachRepeated: [String] = [
        "今天身体似乎有些疲劳了呢，这是第 {count} 次提醒，不如站起来活动 30 秒？",
        "反复低头说明肌肉在呼救哦，配合一次深呼吸，重新建立挺拔记忆吧。"
    ]

    private static let coachRecovery: [String] = [
        "非常完美的中立位！感受这股挺拔舒畅的呼吸流动吧。",
        "姿态保持得真棒！你的脊椎正在感谢你的细心呵护。",
        "就是这个节奏，端正挺拔，专注与健康同在。"
    ]

    // MARK: - 智能匹配与模版渲染
    static func pickLine(for context: SUPostureContext) -> String {
        let rawLine: String
        let persona = context.persona

        switch context.state {
        case .upright:
            rawLine = pickRandomRecovery(for: persona)
        case .severeSlump:
            if context.isLateNight && Bool.random() {
                rawLine = pickRandomLateNight(for: persona)
            } else if context.isRepeatedViolation && Bool.random() {
                rawLine = pickRandomRepeated(for: persona)
            } else {
                rawLine = pickRandomSevere(for: persona)
            }
        case .slightSlump:
            if context.isRepeatedViolation && context.violationCountToday >= 3 && Bool.random() {
                rawLine = pickRandomRepeated(for: persona)
            } else if context.isLateNight && Bool.random() {
                rawLine = pickRandomLateNight(for: persona)
            } else {
                rawLine = pickRandomSlight(for: persona)
            }
        default:
            rawLine = pickRandomRecovery(for: persona)
        }

        // 替换动态宏模版变量
        return rawLine
            .replacingOccurrences(of: "{count}", with: "\(context.violationCountToday)")
            .replacingOccurrences(of: "{angle}", with: String(format: "%.0f°", context.angleDeg))
            .replacingOccurrences(of: "{kg}", with: String(format: "%.1f", context.extraLoadKg))
    }

    private static func pickRandomSlight(for persona: SUPetPersona) -> String {
        switch persona {
        case .worker: return workerSlightSlump.randomElement() ?? workerSlightSlump[0]
        case .cat: return catSlightSlump.randomElement() ?? catSlightSlump[0]
        case .coach: return coachSlightSlump.randomElement() ?? coachSlightSlump[0]
        }
    }

    private static func pickRandomSevere(for persona: SUPetPersona) -> String {
        switch persona {
        case .worker: return workerSevereSlump.randomElement() ?? workerSevereSlump[0]
        case .cat: return catSevereSlump.randomElement() ?? catSevereSlump[0]
        case .coach: return coachSevereSlump.randomElement() ?? coachSevereSlump[0]
        }
    }

    private static func pickRandomLateNight(for persona: SUPetPersona) -> String {
        switch persona {
        case .worker: return workerLateNight.randomElement() ?? workerLateNight[0]
        case .cat: return catLateNight.randomElement() ?? catLateNight[0]
        case .coach: return coachLateNight.randomElement() ?? coachLateNight[0]
        }
    }

    private static func pickRandomRepeated(for persona: SUPetPersona) -> String {
        switch persona {
        case .worker: return workerRepeated.randomElement() ?? workerRepeated[0]
        case .cat: return catRepeated.randomElement() ?? catRepeated[0]
        case .coach: return coachRepeated.randomElement() ?? coachRepeated[0]
        }
    }

    private static func pickRandomRecovery(for persona: SUPetPersona) -> String {
        switch persona {
        case .worker: return workerRecovery.randomElement() ?? workerRecovery[0]
        case .cat: return catRecovery.randomElement() ?? catRecovery[0]
        case .coach: return coachRecovery.randomElement() ?? coachRecovery[0]
        }
    }
}
