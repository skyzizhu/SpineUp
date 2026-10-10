//
//  SUMainTabBarController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit

/// 主框架 TabBar 控制器 —— 组装监测、战报与设置三大核心功能 Tab
final class SUMainTabBarController: SUBaseTabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        observeLanguageChanges()
    }

    private func setupTabs() {
        // Tab 1: 监测
        let monitorVC = SUPostureMonitorViewController()
        let monitorNav = SUBaseNavigationController(rootViewController: monitorVC)
        monitorNav.tabBarItem = UITabBarItem(
            title: SULocalized("tab_monitor", default: "姿态守护"),
            image: UIImage(systemName: "figure.stand"),
            selectedImage: UIImage(systemName: "figure.stand")
        )

        // Tab 2: 战报
        let reportVC = SUDailyReportViewController()
        let reportNav = SUBaseNavigationController(rootViewController: reportVC)
        reportNav.tabBarItem = UITabBarItem(
            title: SULocalized("tab_report", default: "骨气战报"),
            image: UIImage(systemName: "chart.bar.doc.horizontal"),
            selectedImage: UIImage(systemName: "chart.bar.doc.horizontal.fill")
        )

        // Tab 3: 骨气榜
        let leaderboardVC = SULeaderboardViewController()
        let leaderboardNav = SUBaseNavigationController(rootViewController: leaderboardVC)
        leaderboardNav.tabBarItem = UITabBarItem(
            title: SULocalized("tab_leaderboard", default: "骨气榜"),
            image: UIImage(systemName: "trophy"),
            selectedImage: UIImage(systemName: "trophy.fill")
        )

        // Tab 4: 设置
        let settingsVC = SUSettingsViewController()
        let settingsNav = SUBaseNavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: SULocalized("tab_settings", default: "偏好设置"),
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        viewControllers = [monitorNav, reportNav, leaderboardNav, settingsNav]

        if CommandLine.arguments.contains("-selectSettingsTab") {
            selectedIndex = 3
        } else {
            selectedIndex = 0
        }

        if CommandLine.arguments.contains("-openLegalList") {
            selectedIndex = 3
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let legalVC = SULegalListViewController()
                settingsNav.pushViewController(legalVC, animated: false)
            }
        } else if CommandLine.arguments.contains("-openMedicalDetail") {
            selectedIndex = 3
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let legalVC = SULegalListViewController()
                let webVC = SUWebViewController(
                    url: URL(string: SUAppConfig.medicalDisclaimerURL),
                    pageTitle: SULocalized("legal_item_medical_title", default: "健康与医疗免责声明"),
                    fallbackResourceName: "medical"
                )
                settingsNav.setViewControllers([settingsVC, legalVC, webVC], animated: false)
            }
        } else if CommandLine.arguments.contains("-openPrivacyDetail") {
            selectedIndex = 3
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let legalVC = SULegalListViewController()
                let webVC = SUWebViewController(
                    url: URL(string: SUAppConfig.privacyPolicyURL),
                    pageTitle: SULocalized("legal_item_privacy_title", default: "隐私政策"),
                    fallbackResourceName: "privacy"
                )
                settingsNav.setViewControllers([settingsVC, legalVC, webVC], animated: false)
            }
        }

        // 主线程空闲时静默预热战报等后续 Tab 视图，彻底消除 TabBar 初次切换时的冷启动卡顿
        DispatchQueue.main.async { [weak reportVC, weak leaderboardVC, weak settingsVC] in
            reportVC?.loadViewIfNeeded()
            leaderboardVC?.loadViewIfNeeded()
            settingsVC?.loadViewIfNeeded()
        }
    }

    private func observeLanguageChanges() {
        NotificationCenter.default.addObserver(
            forName: SULocalizationManager.languageDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, let vcs = self.viewControllers, vcs.count >= 4 else { return }
            vcs[0].tabBarItem.title = SULocalized("tab_monitor", default: "姿态守护")
            vcs[1].tabBarItem.title = SULocalized("tab_report", default: "骨气战报")
            vcs[2].tabBarItem.title = SULocalized("tab_leaderboard", default: "骨气榜")
            vcs[3].tabBarItem.title = SULocalized("tab_settings", default: "偏好设置")
        }
    }
}
