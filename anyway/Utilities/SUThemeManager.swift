//
//  SUThemeManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit

/// 应用外观主题枚举 —— 支持跟随系统、浅色模式与深色模式
enum SUAppTheme: String, CaseIterable, Sendable {
    case system = "system"  // 跟随系统 (默认)
    case light = "light"    // 浅色模式
    case dark = "dark"      // 深色模式

    var displayName: String {
        switch self {
        case .system: return SULocalized("theme_system", default: "跟随系统")
        case .light:  return SULocalized("theme_light", default: "浅色模式")
        case .dark:   return SULocalized("theme_dark", default: "深色模式")
        }
    }

    var subtitle: String {
        switch self {
        case .system: return SULocalized("theme_system_desc", default: "与系统外观设置保持同步")
        case .light:  return SULocalized("theme_light_desc", default: "始终以浅色明亮风格展示")
        case .dark:   return SULocalized("theme_dark_desc", default: "始终以深色暗调风格展示")
        }
    }

    var iconSystemName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// 全局外观主题管理中心 —— 统一控制深浅色主题切换与实时生效
final class SUThemeManager: @unchecked Sendable {

    static let shared = SUThemeManager()
    static let themeDidChangeNotification = Notification.Name("SUThemeDidChangeNotification")

    private let userDefaultsKey = "SUAppThemePreference"
    private let lock = NSLock()

    private(set) var currentTheme: SUAppTheme

    private init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let theme = SUAppTheme(rawValue: saved) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
    }

    /// 切换外观主题并即时刷新全屏幕窗口
    func setTheme(_ theme: SUAppTheme) {
        lock.lock()
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: userDefaultsKey)
        lock.unlock()

        DispatchQueue.main.async {
            self.applyTheme(theme)
            NotificationCenter.default.post(name: SUThemeManager.themeDidChangeNotification, object: theme)
        }
    }

    /// 将指定主题应用至全应用场景的所有窗口
    func applyTheme(_ theme: SUAppTheme) {
        let style = theme.userInterfaceStyle
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }
}
