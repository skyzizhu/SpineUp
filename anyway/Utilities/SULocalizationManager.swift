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
}

/// 全局多语言本地化管理中心 —— 支持实时切换语言、英语底底回退机制与 RTL 判定
final class SULocalizationManager: @unchecked Sendable {

    static let shared = SULocalizationManager()

    private let lock = NSLock()
    private let userDefaultsKey = "SUAppLanguagePreference"
    private var bundleMap: [String: Bundle] = [:]

    private(set) var currentLanguage: SULanguage

    /// 语言切换广播回调
    var onLanguageChanged: (@Sendable (SULanguage) -> Void)?

    private init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let lang = SULanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // 自动推断系统首选语言，若不在支持列表中则回退至 Base (en)
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.hasPrefix("zh-Hans") || preferred.hasPrefix("zh-CN") {
                self.currentLanguage = .zhHans
            } else if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-HK") || preferred.hasPrefix("zh-TW") {
                self.currentLanguage = .zhHant
            } else if preferred.hasPrefix("ja") {
                self.currentLanguage = .ja
            } else if preferred.hasPrefix("ko") {
                self.currentLanguage = .ko
            } else if preferred.hasPrefix("ar") {
                self.currentLanguage = .ar
            } else if preferred.hasPrefix("fr") {
                self.currentLanguage = .fr
            } else {
                self.currentLanguage = .en
            }
        }

        loadBundles()
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

    /// 切换当前应用语言
    func setLanguage(_ language: SULanguage) {
        lock.lock()
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
