//
//  SUOfflineCorpus.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 离线高频台词语料库 —— 在无网络或云端请求超时时提供智能匹配的拟人台词，支持 7 种语言多语言适配
enum SUOfflineCorpus {

    enum CorpusScenario {
        case slight
        case severe
        case lateNight
        case repeated
        case recovery
    }

    // MARK: - 智能匹配与模版渲染
    static func pickLine(
        for context: SUPostureContext,
        language: SULanguage = SULocalizationManager.shared.currentLanguage
    ) -> String {
        let scenario: CorpusScenario
        switch context.state {
        case .upright:
            scenario = .recovery
        case .severeSlump:
            if context.isLateNight && Bool.random() {
                scenario = .lateNight
            } else if context.isRepeatedViolation && Bool.random() {
                scenario = .repeated
            } else {
                scenario = .severe
            }
        case .slightSlump:
            if context.isRepeatedViolation && context.violationCountToday >= 3 && Bool.random() {
                scenario = .repeated
            } else if context.isLateNight && Bool.random() {
                scenario = .lateNight
            } else {
                scenario = .slight
            }
        default:
            scenario = .recovery
        }

        let candidates = getCorpus(for: language, persona: context.persona, scenario: scenario)
        let rawLine = candidates.randomElement() ?? getDefaultFallback(for: language)

        // 替换动态宏模版变量
        return rawLine
            .replacingOccurrences(of: "{count}", with: "\(context.violationCountToday)")
            .replacingOccurrences(of: "{angle}", with: String(format: "%.0f°", context.angleDeg))
            .replacingOccurrences(of: "{kg}", with: String(format: "%.1f", context.extraLoadKg))
    }

    // MARK: - 语料分发路由器
    private static func getCorpus(for language: SULanguage, persona: SUPetPersona, scenario: CorpusScenario) -> [String] {
        let lines: [String]
        switch language {
        case .zhHans:
            lines = getZhHansCorpus(persona: persona, scenario: scenario)
        case .zhHant:
            lines = getZhHantCorpus(persona: persona, scenario: scenario)
        case .en:
            lines = getEnCorpus(persona: persona, scenario: scenario)
        case .ja:
            lines = getJaCorpus(persona: persona, scenario: scenario)
        case .ko:
            lines = getKoCorpus(persona: persona, scenario: scenario)
        case .fr:
            lines = getFrCorpus(persona: persona, scenario: scenario)
        case .ar:
            lines = getArCorpus(persona: persona, scenario: scenario)
        }

        if lines.isEmpty {
            return getEnCorpus(persona: persona, scenario: scenario)
        }
        return lines
    }

    private static func getDefaultFallback(for language: SULanguage) -> String {
        switch language {
        case .zhHans: return "做人要有骨气，挺直脊椎，继续加油！"
        case .zhHant: return "做人要有骨氣，挺直脊椎，繼續加油！"
        case .en: return "Stay proud and upright! Straighten your spine and keep going!"
        case .ja: return "胸を張って、背筋を伸ばして、今日も頑張りましょう！"
        case .ko: return "기운 내세요! 척추를 곧게 펴고 계속 화이팅!"
        case .fr: return "Tenez-vous droit avec fierté ! Redressez votre colonne et continuez !"
        case .ar: return "ابقَ فخوراً ومستقيماً! افرد ظهرك وواصل العمل بجد!"
        }
    }

    // MARK: - 1. 简体中文 (zh-Hans)
    private static func getZhHansCorpus(persona: SUPetPersona, scenario: CorpusScenario) -> [String] {
        switch persona {
        case .worker:
            switch scenario {
            case .slight:
                return [
                    "老板给你发工资，可没包含换颈椎的医保报销，头抬起来！",
                    "又低头了？你那几千块的月薪，配得上脖子上挂这十几斤重担吗？",
                    "屏幕里是有金矿还是有年终奖？脖子往前伸得像只愤怒的土拨鼠。",
                    "打工人，挺起胸膛！低头看手机不会让代码自己写完，只会让富贵包先长出来。",
                    "别把头埋进键盘里，你的脊椎已经在大声报警了！",
                    "姿势越卑微，离财富自由越遥远。把下巴收一收！",
                    "别驼着了，屏幕上的 bug 不会因为你靠近 5 厘米就自己修复。",
                    "看看你的脊椎曲线，比公司的股价走势还要坎坷，赶紧坐正！"
                ]
            case .severe:
                return [
                    "警告！你现在低头都快趴桌子上了，颈椎额外承重整整 20 公斤！你想被当成折叠屏送修吗？",
                    "垮掉了！整个人瘫得像周五下午三点半的咖啡渣！立刻给我挺起来！",
                    "你再这么驼下去，下次体检医生直接给你脊椎颁发全勤奖了！抬起头！",
                    "重度驼背警告！我这只打工宠都快被你压成二维平面生物了！",
                    "你的脊椎在向你索赔精神损失费！立刻深呼吸，把头拔起来！"
                ]
            case .lateNight:
                return [
                    "都几点了还在死磕？命是自己的，脊椎也是自己的，抬头喝口水准备下班吧！",
                    "深夜加班就算了，还把自己驼成问号，明天上班打算坐轮椅去吗？抬起头！",
                    "加班的尽头是骨科门诊。坐正！至少别让医生嫌弃你的坐姿。"
                ]
            case .repeated:
                return [
                    "今天第 {count} 次低头犯规了！再驼背，我要以宠物的名义扣你今日能量币了！",
                    "反复犯规！你的下巴是有地心引力追踪器吗？给我收回来！",
                    "第 {count} 次提醒！你对驼背的执着要是用在搞钱上，早退休了！"
                ]
            case .recovery:
                return [
                    "这才像个有骨气的人嘛！保持住，精神气直接翻倍！",
                    "挺拔了！连周围的空气都变得通透了，继续保持！",
                    "这就对了！挺起胸膛，做整条街最优雅的打工人！"
                ]
            }
        case .cat:
            switch scenario {
            case .slight:
                return [
                    "喂！你头往下倾斜，本喵要在你头顶上滑下去了喵！",
                    "不要弯腰驼背啦，本喵的肉垫都快没地方踩了喵！",
                    "喵呜！你头低下去 15 度，本喵就少看了一只小飞虫，快坐正喵！",
                    "你是不是想把本喵压成猫饼？本喵可不答应，快抬起下巴喵！",
                    "笨蛋两脚兽，本喵盯了你半天了，把背挺直一点喵！",
                    "再不好好坐，今天晚上本喵就不踩奶了喵！"
                ]
            case .severe:
                return [
                    "喵呜哇！！压扁了！压扁猫了！！快把头抬起来，要窒息了喵！！",
                    "超级严重的大驼背！本喵的尾巴都被你挤弯了喵！立刻抬头！",
                    "你是猫还是我是猫？怎么整个人瘫软得像一滩液体猫咪一样喵？！坐正！",
                    "救命喵！头上承受了快二十公斤！本喵生气了，爪子要亮出来了喵！",
                    "快抬起头来喵！再趴着我就直接伸爪子挠你下巴了喵！"
                ]
            case .lateNight:
                return [
                    "夜深了喵……本喵都要困扁了，你还低头看发光的屏幕，快坐正然后睡觉喵！",
                    "好黑喵，你头低得像个幽灵猫，快抬头伸个懒腰，本喵陪你伸个懒腰喵！"
                ]
            case .repeated:
                return [
                    "今天都第 {count} 次了喵！本喵的耐心是有限的，快收下巴喵！",
                    "又是第 {count} 次驼背！本喵要扣掉你的小鱼干份额了喵！"
                ]
            case .recovery:
                return [
                    "呼……这样舒服多了喵，本喵勉强赏你一个赞许的眼神喵~",
                    "保持端正挺拔，本喵趴在你肩膀上才安心喵！",
                    "对嘛对嘛，这样才是合格的铲屎官姿态喵！"
                ]
            }
        case .coach:
            switch scenario {
            case .slight:
                return [
                    "来，深吸一口气，轻轻收紧核心，把头顶向上延展。",
                    "注意一下颈椎哦，想象头顶有一根线在轻轻拉着你向上拔高。",
                    "稍微有些前倾了呢，把双肩向后展开，让胸腔自然打开。",
                    "很好，现在放松斜方肌，下巴微收，让颈部回归中立位。",
                    "久坐容易疲劳，跟着我做一次缓慢深呼吸，把背部轻轻挺直。",
                    "感觉到了吗？头部回正时，整个脊椎的压力瞬间减轻了。"
                ]
            case .severe:
                return [
                    "停一下手中的动作，现在前倾角度已经比较大了，颈椎正在承受沉重负担哦。",
                    "深呼吸，慢慢抬起头，双肩下沉，感受脊椎由下至上的舒展延展。",
                    "现在的坐姿对颈椎压迫很明显呢，让我们一起挺胸抬头，做三次缓慢深呼吸。",
                    "请轻缓地将颈部回正，感受胸椎的挺拔与放松，你做得很棒，慢慢来。",
                    "身体在向你发出疲劳信号了，把视线平移抬高，给自己脊椎一个拥抱吧。"
                ]
            case .lateNight:
                return [
                    "夜深了，专注的同时别忘了善待身体。轻轻做个肩颈环绕，抬头望向远方吧。",
                    "这么晚还在坚持，真为你骄傲。但也要给颈椎放松的空间，收收下巴，保持舒展。"
                ]
            case .repeated:
                return [
                    "今天身体似乎有些疲劳了呢，这是第 {count} 次提醒，不如站起来活动 30 秒？",
                    "反复低头说明肌肉在呼救哦，配合一次深呼吸，重新建立挺拔记忆吧。"
                ]
            case .recovery:
                return [
                    "非常完美的中立位！感受这股挺拔舒畅的呼吸流动吧。",
                    "姿态保持得真棒！你的脊椎正在感谢你的细心呵护。",
                    "就是这个节奏，端正挺拔，专注与健康同在。"
                ]
            }
        }
    }

    // MARK: - 2. 繁體中文 (zh-Hant)
    private static func getZhHantCorpus(persona: SUPetPersona, scenario: CorpusScenario) -> [String] {
        switch persona {
        case .worker:
            switch scenario {
            case .slight:
                return [
                    "老闆給你發工資，可沒包含換頸椎的健保報銷，頭抬起來！",
                    "又低頭了？你那幾千塊的月薪，配得上脖子上掛這十幾斤重擔嗎？",
                    "螢幕裡是有金礦還是有年終獎？脖子往前伸得像隻憤怒的土撥鼠。",
                    "打工人，挺起胸膛！低頭看手機不會讓程式碼自己寫完，只會讓富貴包先長出來。",
                    "別把頭埋進鍵盤裡，你的脊椎已經在大聲報警了！",
                    "別駝著了，螢幕上的 bug 不會因為你靠近 5 公分就自己修復。"
                ]
            case .severe:
                return [
                    "警告！你現在低頭都快趴桌子上了，頸椎額外承重整整 20 公斤！你想被當成摺疊螢幕送修嗎？",
                    "垮掉了！整個人癱得像週五下午三點半的咖啡渣！立刻給我挺起來！",
                    "你再這麼駝下去，下次體檢醫生直接給你脊椎頒發全勤獎了！抬起頭！",
                    "重度駝背警告！我這隻打工寵都快被你壓成二維平面生物了！"
                ]
            case .lateNight:
                return [
                    "都幾點了還在死磕？命是自己的，脊椎也是自己的，抬頭喝口水準備下班吧！",
                    "深夜加班就算了，還把自己駝成問號，明天上班打算坐輪椅去嗎？抬起頭！"
                ]
            case .repeated:
                return [
                    "今天第 {count} 次低頭犯規了！再駝背，我要以寵物的名義扣你今日能量幣了！",
                    "反覆犯規！你的下巴是有地心引力追蹤器嗎？給我收回來！"
                ]
            case .recovery:
                return [
                    "這才像個有骨氣的人嘛！保持住，精神氣直接翻倍！",
                    "挺拔了！連周圍的空氣都變得通透了，繼續保持！"
                ]
            }
        case .cat:
            switch scenario {
            case .slight:
                return [
                    "喂！你頭往下傾斜，本喵要在你頭頂上滑下去了喵！",
                    "不要彎腰駝背啦，本喵的肉墊都快沒地方踩了喵！",
                    "喵嗚！你頭低下去 15 度，本喵就少看了一隻小飛蟲，快坐正喵！",
                    "笨蛋兩腳獸，本喵盯了你半天了，把背挺直一點喵！"
                ]
            case .severe:
                return [
                    "喵嗚哇！！壓扁了！壓扁貓了！！快把頭抬起來，要窒息了喵！！",
                    "超級嚴重的大駝背！本喵的尾巴都被你擠彎了喵！立刻抬頭！",
                    "救命喵！頭上承受了快二十公斤！本喵生氣了，爪子要亮出來了喵！"
                ]
            case .lateNight:
                return [
                    "夜深了喵……本喵都要困扁了，你還低頭看發光的螢幕，快坐正然後睡覺喵！"
                ]
            case .repeated:
                return [
                    "今天都第 {count} 次了喵！本喵的耐心是有限的，快收下巴喵！"
                ]
            case .recovery:
                return [
                    "呼……這樣舒服多了喵，本喵勉強賞你一個讚許的眼神喵~",
                    "保持端正挺拔，本喵趴在你肩膀上才安心喵！"
                ]
            }
        case .coach:
            switch scenario {
            case .slight:
                return [
                    "來，深吸一口氣，輕輕收緊核心，把頭頂向上延展。",
                    "注意一下頸椎哦，想像頭頂有一根線在輕輕拉著你向上拔高。",
                    "稍微有些前傾了呢，把雙肩向後展開，讓胸腔自然打開。"
                ]
            case .severe:
                return [
                    "停一下手中的動作，現在前傾角度已經比較大了，頸椎正在承受沉重負擔哦。",
                    "深呼吸，慢慢抬起頭，雙肩下沉，感受脊椎由下至上的舒展延展。"
                ]
            case .lateNight:
                return [
                    "夜深了，專注的同時別忘了善待身體。輕輕做個肩頸環繞，抬頭望向遠方吧。"
                ]
            case .repeated:
                return [
                    "今天身體似乎有些疲勞了呢，這是第 {count} 次提醒，不如站起來活動 30 秒？"
                ]
            case .recovery:
                return [
                    "非常完美的中立位！感受這股挺拔舒暢的呼吸流動吧。",
                    "姿態保持得真棒！你的脊椎正在感謝你的細心呵護。"
                ]
            }
        }
    }

    // MARK: - 3. English (en)
    private static func getEnCorpus(persona: SUPetPersona, scenario: CorpusScenario) -> [String] {
        switch persona {
        case .worker:
            switch scenario {
            case .slight:
                return [
                    "Your boss pays for code, not spine surgery. Chin up!",
                    "Head down again? That paycheck isn't worth 20 lbs of neck strain.",
                    "Is there a gold mine in your screen? Straighten that neck!",
                    "Straighten up! Looking closer won't fix the bugs any faster.",
                    "Your posture screams overworked. Sit tall and reclaim your dignity!"
                ]
            case .severe:
                return [
                    "Warning! Extreme slump detected. Your spine is bearing an extra 20 kg!",
                    "Collapsing like a bad pull request! Straighten up immediately!",
                    "Keep slouching and the clinic will give you a VIP badge. Head up!",
                    "Severe slump alert! You're crushing me into a flat pancake!",
                    "Your spine is demanding compensation for overtime damage! Breathe and sit up!"
                ]
            case .lateNight:
                return [
                    "Working late? Your spine is begging for mercy. Stretch and sit tall!",
                    "Overtime won't heal your neck. Straighten up before calling it a night!"
                ]
            case .repeated:
                return [
                    "Slump violation #{count} today! Straighten up or I'll fine your Energy Coins!",
                    "Repeated violation! Does your chin have gravity tracking? Pull it back!"
                ]
            case .recovery:
                return [
                    "Now that's dignified! Keep it up!",
                    "Upright and sharp! Your energy just doubled."
                ]
            }
        case .cat:
            switch scenario {
            case .slight:
                return [
                    "Hey! You're slumping, I'm sliding right off your head, meow!",
                    "Don't hunch! There's no room for my paws, meow!",
                    "Head tilted down means I missed a flying bug. Sit up straight, meow!",
                    "Silly human, I've been watching you. Straighten your back, meow!"
                ]
            case .severe:
                return [
                    "Meow!! Squished! You're flattening me into a pancake!! Head up!",
                    "Severe slouch alert! My tail is all squished. Sit up now, meow!",
                    "Help meow! Twenty kilos on your neck! I'm bringing out the claws!"
                ]
            case .lateNight:
                return [
                    "It's so late, meow... Time to sit straight and go to sleep!",
                    "Stretching time! Sit up straight and stretch with me, meow!"
                ]
            case .repeated:
                return [
                    "That's #{count} times today! My feline patience is running out, chin up!",
                    "Another slouch (#{count})! Less treats for you, meow!"
                ]
            case .recovery:
                return [
                    "Purr... Much better! Here's an approving glance, meow~",
                    "Stay upright so I can nap on your shoulders comfortably, meow!"
                ]
            }
        case .coach:
            switch scenario {
            case .slight:
                return [
                    "Take a deep breath, engage your core, and lengthen through the crown of your head.",
                    "Notice your neck: imagine a gentle thread pulling you upwards.",
                    "Slight forward head posture. Roll your shoulders back and open your chest."
                ]
            case .severe:
                return [
                    "Pause for a moment. Your neck is under significant load right now.",
                    "Inhale deeply, gently lift your head, and let your shoulders drop.",
                    "Let's reset together: chin tucked, chest open, take three calm breaths."
                ]
            case .lateNight:
                return [
                    "Late night focus, but be kind to your body. Roll your shoulders and gaze forward.",
                    "Proud of your dedication, but remember to let your spine breathe."
                ]
            case .repeated:
                return [
                    "Your body is signaling fatigue. That's reminder #{count}—how about standing for 30 seconds?",
                    "Repeated slouching means tired muscles. One deep breath to restore alignment."
                ]
            case .recovery:
                return [
                    "Perfect neutral spine! Feel that refreshing, effortless breath.",
                    "Wonderful posture! Your spine is thanking you right now."
                ]
            }
        }
    }

    // MARK: - 4. Japanese (ja)
    private static func getJaCorpus(persona: SUPetPersona, scenario: CorpusScenario) -> [String] {
        switch persona {
        case .worker:
            switch scenario {
            case .slight:
                return [
                    "社長は給料を払ってくれても、頸椎の治療費は出してくれませんよ！顔を上げて！",
                    "また猫背？その月給で首に重い負担をかける価値ありますか？",
                    "画面に近づいてもバグは勝手に直りませんよ。背筋を伸ばして！"
                ]
            case .severe:
                return [
                    "警告！極端な前傾姿勢です。首に20キロの余計な負荷がかかっています！",
                    "完全に崩れてますよ！今すぐ背筋をピンと伸ばしてください！"
                ]
            case .lateNight:
                return [
                    "こんな時間まで残業ですか？首のためにも一息入れて、背筋を伸ばしましょう！"
                ]
            case .repeated:
                return [
                    "本日{count}回目の猫背警告です！エナジーコインを没収しますよ！"
                ]
            case .recovery:
                return [
                    "そう、その姿勢！シャキッとして素晴らしいです！"
                ]
            }
        case .cat:
            switch scenario {
            case .slight:
                return [
                    "ニャー！頭が下がってて、頭の上から滑り落ちちゃうニャ！",
                    "背中を丸めないでニャ、お肉球が乗っかる場所がないニャ！"
                ]
            case .severe:
                return [
                    "ニャー！！潰れちゃう！猫せんべいになっちゃうニャ！頭を上げて！",
                    "大猫背警報ニャ！私のしっぽが挟まれちゃう、早く起きてニャ！"
                ]
            case .lateNight:
                return [
                    "もう夜遅いニャ……画面ばかり見てないで、背筋を伸ばして寝るニャ！"
                ]
            case .repeated:
                return [
                    "今日もう{count}回目ニャ！私の我慢も限界ニャ、顎を引いてニャ！"
                ]
            case .recovery:
                return [
                    "ふぅ……これで落ち着いたニャ。褒めてあげるニャ~"
                ]
            }
        case .coach:
            switch scenario {
            case .slight:
                return [
                    "深呼吸して、頭頂部を優しく上へ引き上げるイメージを持ちましょう。",
                    "少し前傾していますね。肩をリラックスさせて胸を開きましょう。"
                ]
            case .severe:
                return [
                    "一度手を止めて、首の負担を解放しましょう。ゆっくりと顔を上げてください。",
                    "大きく息を吸って、肩を下ろし、背骨の伸びを感じてみましょう。"
                ]
            case .lateNight:
                return [
                    "遅くまでお疲れ様です。首と肩を回して、優しくリフレッシュしましょう。"
                ]
            case .repeated:
                return [
                    "お疲れが出ていますね。本日{count}回目のリマインドです。少し立ち上がってみませんか？"
                ]
            case .recovery:
                return [
                    "完璧なニュートラルポジションです！深い呼吸を味わいましょう。"
                ]
            }
        }
    }

    // MARK: - 5. Korean (ko)
    private static func getKoCorpus(persona: SUPetPersona, scenario: CorpusScenario) -> [String] {
        switch persona {
        case .worker:
            switch scenario {
            case .slight:
                return [
                    "사장님이 월급은 줘도 목 디스크 수술비는 안 대줍니다. 고개 드세요!",
                    "또 거북목인가요? 그 월급으로 목에 십수 킬로 짐을 질 가치가 있나요?",
                    "화면에 바짝 다가간다고 버그가 저절로 고쳐지지 않습니다. 허리 펴세요!"
                ]
            case .severe:
                return [
                    "경고! 완전히 엎드려 있잖아요! 목에 20kg의 하중이 실리고 있어요!",
                    "축 늘어져 있네요! 지금 당장 척추를 똑바로 펴세요!"
                ]
            case .lateNight:
                return [
                    "이 시간까지 야근인가요? 몸도 척추도 소중합니다. 스트레칭하고 허리 펴세요!"
                ]
            case .repeated:
                return [
                    "오늘 벌써 {count}번째 거북목 위반입니다! 에너지 코인 차감할 거예요!"
                ]
            case .recovery:
                return [
                    "그렇죠! 이제야 당당하고 멋진 자세네요. 계속 유지하세요!"
                ]
            }
        case .cat:
            switch scenario {
            case .slight:
                return [
                    "야옹! 머리가 기울어서 네 머리 위에서 미끄러지겠다옹!",
                    "등 구부리지 마라옹, 내 젤리 발바닥 둘 곳이 없다옹!"
                ]
            case .severe:
                return [
                    "야옹!! 납작해진다옹! 고양이 호떡 만들 셈이냐옹! 고개 들어라옹!!",
                    "엄청난 거북목이다옹! 꼬리 끼었다옹, 당장 일어나라옹!"
                ]
            case .lateNight:
                return [
                    "밤이 깊었다옹... 화면만 보지 말고 허리 펴고 자러 가라옹!"
                ]
            case .repeated:
                return [
                    "오늘 벌써 {count}번째다옹! 내 인내심도 한계다옹, 턱 당겨라옹!"
                ]
            case .recovery:
                return [
                    "휴... 이제 살 것 같다옹. 칭찬해 주겠다옹~"
                ]
            }
        case .coach:
            switch scenario {
            case .slight:
                return [
                    "깊게 숨을 들이쉬고, 코어를 부드럽게 조이며 정수리를 위로 뻗어보세요.",
                    "약간 앞쪽으로 기울어졌네요. 어깨를 뒤로 젖히고 가슴을 활짝 열어보세요."
                ]
            case .severe:
                return [
                    "잠시 손을 멈추고 목의 부담을 덜어주세요. 천천히 고개를 들어주세요.",
                    "크게 숨을 들이쉬며 어깨를 내리고 척추가 부드럽게 펴지는 것을 느껴보세요."
                ]
            case .lateNight:
                return [
                    "늦은 시간까지 수고 많으세요. 목과 어깨를 돌려 부드럽게 긴장을 풀어주세요."
                ]
            case .repeated:
                return [
                    "몸이 피로 신호를 보내고 있네요. {count}번째 알림입니다. 30초만 서서 스트레칭해 볼까요?"
                ]
            case .recovery:
                return [
                    "완벽한 중립 자세입니다! 시원하고 편안한 호흡을 느껴보세요."
                ]
            }
        }
    }

    // MARK: - 6. French (fr)
    private static func getFrCorpus(persona: SUPetPersona, scenario: CorpusScenario) -> [String] {
        switch persona {
        case .worker:
            switch scenario {
            case .slight:
                return [
                    "Votre patron paie pour du travail, pas pour votre opération du cou. Levez la tête !",
                    "Encore la tête baissée ? Ce salaire ne vaut pas 15 kg de pression sur vos cervicales.",
                    "Regarder l'écran de plus près ne résoudra pas vos bugs. Redressez-vous !"
                ]
            case .severe:
                return [
                    "Alerte ! Affaissement sévère détecté. Votre colonne supporte 20 kg de trop !",
                    "Effondré comme un café du vendredi après-midi ! Redressez-vous sur-le-champ !"
                ]
            case .lateNight:
                return [
                    "Encore au travail si tard ? Votre colonne crie grâce. Étirez-vous et tenez-vous droit !"
                ]
            case .repeated:
                return [
                    "Violation #{count} aujourd'hui ! Redressez-vous ou je confisque vos Pièces d'Énergie !"
                ]
            case .recovery:
                return [
                    "Voilà qui a fière allure ! Gardez cette belle posture !"
                ]
            }
        case .cat:
            switch scenario {
            case .slight:
                return [
                    "Hé ! Tu penches la tête, je vais glisser de là-haut, miaou !",
                    "Ne te voûte pas, je n'ai plus de place pour mes coussinets, miaou !"
                ]
            case .severe:
                return [
                    "Miaou !! Tu m'écrases comme une crêpe !! Lève la tête tout de suite !",
                    "Alerte gros dos rond ! Tu me coinces la queue, redresse-toi, miaou !"
                ]
            case .lateNight:
                return [
                    "Il se fait tard, miaou... Arrête de fixer l'écran, tiens-toi droit et va dormir !"
                ]
            case .repeated:
                return [
                    "C'est déjà la {count}e fois aujourd'hui ! Ma patience a des limites, miaou !"
                ]
            case .recovery:
                return [
                    "Ouf... C'est bien plus confortable comme ça, miaou~"
                ]
            }
        case .coach:
            switch scenario {
            case .slight:
                return [
                    "Prenez une profonde inspiration, engagez le centre et étirez le sommet du crâne vers le haut.",
                    "Légère projection vers l'avant. Roulez les épaules vers l'arrière et ouvrez la poitrine."
                ]
            case .severe:
                return [
                    "Faites une pause. Votre nuque supporte une charge importante en ce moment.",
                    "Inspirez profondément, levez doucement la tête et laissez retomber les épaules."
                ]
            case .lateNight:
                return [
                    "Concentré si tard, mais prenez soin de votre corps. Relâchez les tensions du cou."
                ]
            case .repeated:
                return [
                    "Votre corps fatigue, c'est le {count}e rappel. Que diriez-vous de vous lever 30 secondes ?"
                ]
            case .recovery:
                return [
                    "Posture neutre parfaite ! Ressentez cette respiration fluide et vivifiante."
                ]
            }
        }
    }

    // MARK: - 7. Arabic (ar)
    private static func getArCorpus(persona: SUPetPersona, scenario: CorpusScenario) -> [String] {
        switch persona {
        case .worker:
            switch scenario {
            case .slight:
                return [
                    "راتبك لا يشمل تكاليف علاج العمود الفقري، ارفع رأسك فوراً!",
                    "انحنيت مجدداً؟ ذلك الراتب لا يستحق كل هذا الحمل الثقيل على رقبتك.",
                    "الاقتراب من الشاشة لن يحل مشاكلك أسرع. افرد ظهرك!"
                ]
            case .severe:
                return [
                    "تحذير! انحناء شديد جداً، رقبتك تتحمل 20 كغ إضافية! اعتدل فوراً!",
                    "منهار تماماً كفنجان قهوة مسكوب! افرد قامتك الآن!"
                ]
            case .lateNight:
                return [
                    "عمل متأخر؟ رقبتك تستغيث، تمدد قليلاً واجلس باعتدال!"
                ]
            case .repeated:
                return [
                    "المخالفة رقم {count} اليوم! اعتدل وإلا خصمت منك عملات الطاقة!"
                ]
            case .recovery:
                return [
                    "هكذا يكون الوقار والشهامة! حافظ على هذه الاستقامة الرائعة!"
                ]
            }
        case .cat:
            switch scenario {
            case .slight:
                return [
                    "مهلاً! رأسك ينحدر للأسفل وسأنزلق من فوقك، مياو!",
                    "لا تقوس ظهرك، لم يعد هناك متسع لكفوفي، مياو!"
                ]
            case .severe:
                return [
                    "مياو!! لقد سحقتني كالفطيرة!! ارفع رأسك سريعاً!",
                    "انحناء فظيع! لقد حشرت ذيلي، اعتدل حالاً، مياو!"
                ]
            case .lateNight:
                return [
                    "الوقت متأخر جداً، مياو... كفاك نظراً للشاشة وافرد ظهرك لتنام!"
                ]
            case .repeated:
                return [
                    "هذه المرة رقم {count} اليوم! صبري بدأ ينفد، ارفع ذقنك، مياو!"
                ]
            case .recovery:
                return [
                    "أوه... هكذا أفضل بكثير، نظرة إعجاب لك مني، مياو~"
                ]
            }
        case .coach:
            switch scenario {
            case .slight:
                return [
                    "خذ نفساً عميقاً، شد عضلات الجذع برفق وارفع قمة رأسك للأعلى.",
                    "انحناء طفيف للأمام. أرجع كتفيك للخلف وافتح القفص الصدري بلطف."
                ]
            case .severe:
                return [
                    "توقف لحظة. رقبتك تتحمل عبئاً كبيراً في هذا الوضع.",
                    "تنفس بعمق، ارفع رأسك بهدوء ودع كتفيك يسترخيان لأسفل."
                ]
            case .lateNight:
                return [
                    "العمل في وقت متأخر يرهق الجسد. حرّك رقبتك بلطف وامنح ظهرك متنفساً."
                ]
            case .repeated:
                return [
                    "جسدك يرسل إشارات إرهاق، هذا التنبيه رقم {count}. ما رأيك بالوقوف لثوانٍ؟"
                ]
            case .recovery:
                return [
                    "استقامة متوازنة ومثالية! استمتع بهذا التنفس المريح والصحي."
                ]
            }
        }
    }
}
