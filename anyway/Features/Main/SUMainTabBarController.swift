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
            selectedImage: UIImage(systemName: "figure.stand.line.dotted.figure.stand")
        )

        // Tab 2: 战报
        let reportVC = SUDailyReportViewController()
        let reportNav = SUBaseNavigationController(rootViewController: reportVC)
        reportNav.tabBarItem = UITabBarItem(
            title: SULocalized("tab_report", default: "今日战报"),
            image: UIImage(systemName: "chart.bar.doc.horizontal"),
            selectedImage: UIImage(systemName: "chart.bar.doc.horizontal.fill")
        )

        // Tab 3: 设置
        let settingsVC = SUSettingsViewController()
        let settingsNav = SUBaseNavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: SULocalized("tab_settings", default: "偏好设置"),
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        viewControllers = [monitorNav, reportNav, settingsNav]
    }

    private func observeLanguageChanges() {
        NotificationCenter.default.addObserver(
            forName: SULocalizationManager.languageDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, let vcs = self.viewControllers, vcs.count >= 3 else { return }
            vcs[0].tabBarItem.title = SULocalized("tab_monitor", default: "姿态守护")
            vcs[1].tabBarItem.title = SULocalized("tab_report", default: "今日战报")
            vcs[2].tabBarItem.title = SULocalized("tab_settings", default: "偏好设置")
        }
    }
}
