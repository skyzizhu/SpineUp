//
//  SULocalizationManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 支持的 7 种语言枚举（基准语言为英语 en）
enum SULanguage: String, CaseIterable, Sendable {
    case en = "en"               // English (Base)
    case zhHans = "zh-Hans"     // 简体中文
    case zhHant = "zh-Hant"     // 繁體中文
    case ja = "ja"               // 日本語
    case ko = "ko"               // 한국어
    case ar = "ar"               // العربية (RTL 从右向左)
    case fr = "fr"               // Français

    var displayName: String {
        switch self {
        case .en: return "English"
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .ar: return "العربية"
        case .fr: return "Français"
        }
    }

    /// 是否为 RTL 从右向左排版语言
    var isRTL: Bool {
        return self == .ar
    }

    /// 匹配 AVSpeechSynthesisVoice 的 BCP 47 语言代号
    var ttsLanguageCode: String {
        switch self {
        case .en: return "en-US"
        case .zhHans: return "zh-CN"
        case .zhHant: return "zh-TW"
        case .ja: return "ja-JP"
        case .ko: return "ko-KR"
        case .ar: return "ar-SA"
        case .fr: return "fr-FR"
        }
    }

    /// LLM 生成台词时指定的输出语言要求指令
    var promptLanguageInstruction: String {
        switch self {
        case .en: return "Please output the quote strictly in English."
        case .zhHans: return "请务必使用简体中文输出台词。"
        case .zhHant: return "請務必使用繁體中文輸出台詞。"
        case .ja: return "必ず日本語で台詞を出力してください。"
        case .ko: return "반드시 한국어로 대사를 출력해 주세요."
        case .ar: return "يرجى إخراج الرد باللغة العربية حصراً."
        case .fr: return "Veuillez formuler la réplique obligatoirement en français."
        }
    }
}

/// 全局多语言本地化管理中心 —— 支持实时切换语言、英语底底回退机制与 RTL 判定
final class SULocalizationManager: @unchecked Sendable {

    static let shared = SULocalizationManager()

    private let lock = NSLock()
    private let userDefaultsKey = "SUAppLanguagePreference"
    private var bundleMap: [String: Bundle] = [:]

    private(set) var isFollowSystem: Bool
    private(set) var currentLanguage: SULanguage

    /// 语言切换广播回调
    var onLanguageChanged: (@Sendable (SULanguage) -> Void)?

    private init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey), saved != "system" {
            if let lang = SULanguage(rawValue: saved) {
                self.isFollowSystem = false
                self.currentLanguage = lang
            } else {
                self.isFollowSystem = true
                self.currentLanguage = Self.resolveSystemLanguage()
            }
        } else {
            // 默认跟随系统
            self.isFollowSystem = true
            self.currentLanguage = Self.resolveSystemLanguage()
        }

        loadBundles()
    }

    /// 自动推断系统首选语言，若不在支持列表中则安全回退至 Base (en)
    static func resolveSystemLanguage() -> SULanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh-Hans") || preferred.hasPrefix("zh-CN") {
            return .zhHans
        } else if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-HK") || preferred.hasPrefix("zh-TW") {
            return .zhHant
        } else if preferred.hasPrefix("ja") {
            return .ja
        } else if preferred.hasPrefix("ko") {
            return .ko
        } else if preferred.hasPrefix("ar") {
            return .ar
        } else if preferred.hasPrefix("fr") {
            return .fr
        } else {
            return .en
        }
    }

    private func loadBundles() {
        for lang in SULanguage.allCases {
            if let path = Bundle.main.path(forResource: lang.rawValue, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                bundleMap[lang.rawValue] = bundle
            }
        }
    }

    static let languageDidChangeNotification = Notification.Name("SULanguageDidChangeNotification")

    /// 切换为手动指定的应用语言
    func setLanguage(_ language: SULanguage) {
        lock.lock()
        isFollowSystem = false
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: userDefaultsKey)
        lock.unlock()

        onLanguageChanged?(language)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: SULocalizationManager.languageDidChangeNotification,
                object: language
            )
        }
    }

    /// 切换为跟随系统语言
    func setFollowSystem() {
        let resolved = Self.resolveSystemLanguage()
        lock.lock()
        isFollowSystem = true
        currentLanguage = resolved
        UserDefaults.standard.set("system", forKey: userDefaultsKey)
        lock.unlock()

        onLanguageChanged?(resolved)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: SULocalizationManager.languageDidChangeNotification,
                object: resolved
            )
        }
    }

    /// 当前语言是否为从右向左 (RTL)
    var isRightToLeft: Bool {
        lock.lock()
        defer { lock.unlock() }
        return currentLanguage.isRTL
    }

    /// 获取本地化文案，未命中时回退到英文或提供的默认值
    func localizedString(for key: String, defaultValue: String? = nil) -> String {
        lock.lock()
        let lang = currentLanguage
        let currentBundle = bundleMap[lang.rawValue]
        let baseBundle = bundleMap[SULanguage.en.rawValue]
        lock.unlock()

        // 1. 尝试从当前语言 bundle 获取
        if let currentBundle = currentBundle {
            let str = currentBundle.localizedString(forKey: key, value: nil, table: nil)
            if str != key {
                return str
            }
        }

        // 2. 尝试从英文 Base bundle 获取
        if let baseBundle = baseBundle {
            let str = baseBundle.localizedString(forKey: key, value: nil, table: nil)
            if str != key {
                return str
            }
        }

        // 3. 回退到提供的默认文案或 key 本身
        return defaultValue ?? key
    }
}

/// 便捷全局本地化查找方法
func SULocalized(_ key: String, default defaultVal: String? = nil) -> String {
    return SULocalizationManager.shared.localizedString(for: key, defaultValue: defaultVal)
}
