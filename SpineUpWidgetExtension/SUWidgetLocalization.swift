//
//  SUWidgetLocalization.swift
//  SpineUpWidgetExtension
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import SwiftUI

/// 桌面小组件与实时活动轻量国际化助手 —— 覆盖 7 种语言 (en, zh-Hans, zh-Hant, ja, ko, ar, fr)
enum SUWidgetLocalization {

    private static var bundleForCurrentLanguage: Bundle {
        let userDefaults = UserDefaults(suiteName: "group.com.iashes.anyway")
        if let langCode = userDefaults?.string(forKey: "su_appLanguageCode"),
           let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }

    private static var currentLocale: Locale {
        let userDefaults = UserDefaults(suiteName: "group.com.iashes.anyway")
        if let langCode = userDefaults?.string(forKey: "su_appLanguageCode") {
            return Locale(identifier: langCode)
        }
        return Locale.current
    }

    static func localizedString(_ key: String, default defaultString: String) -> String {
        let localized = bundleForCurrentLanguage.localizedString(forKey: key, value: defaultString, table: nil)
        return localized
    }

    static func localizedFormat(_ key: String, default defaultString: String, _ arguments: CVarArg...) -> String {
        let format = localizedString(key, default: defaultString)
        return String(format: format, locale: currentLocale, arguments: arguments)
    }

    static func petName(for personaId: String) -> String {
        switch personaId {
        case "zen":
            return localizedString("persona_zen", default: "禅修老道")
        case "rebel":
            return localizedString("persona_rebel", default: "叛逆朋克")
        case "medic":
            return localizedString("persona_medic", default: "严厉骨科医")
        case "cat":
            return localizedString("persona_cat", default: "傲娇猫咪")
        case "coach":
            return localizedString("persona_coach", default: "温和教练")
        default:
            return localizedString("persona_worker", default: "办公打工人")
        }
    }

    static func stateTitle(for state: String) -> String {
        switch state {
        case "upright":
            return localizedString("state_upright", default: "精神挺拔")
        case "mildSlouch", "slightSlump":
            return localizedString("state_mild_slouch", default: "轻微前倾")
        case "severeSlouch", "severeSlump":
            return localizedString("state_severe_slouch", default: "严重驼背")
        default:
            return localizedString("state_monitoring", default: "监测中")
        }
    }

    static func quote(for state: String) -> String {
        switch state {
        case "severeSlouch", "severeSlump":
            return localizedString("quote_severe_slouch", default: "你的脊椎在哭泣！快抬起下巴！")
        case "mildSlouch", "slightSlump":
            return localizedString("quote_mild_slouch", default: "脖子微倾斜，稍作调整更挺拔哦～")
        case "upright":
            return localizedString("quote_upright", default: "状态极佳，身姿如松，继续保持！")
        default:
            return localizedString("quote_default", default: "做人要有骨气，端正挺拔中！")
        }
    }
}
