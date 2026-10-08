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
    }

    private func setupTabs() {
        // Tab 1: 监测
        let monitorVC = SUPostureMonitorViewController()
        let monitorNav = SUBaseNavigationController(rootViewController: monitorVC)
        monitorNav.tabBarItem = UITabBarItem(
            title: "监测",
            image: UIImage(systemName: "figure.stand"),
            selectedImage: UIImage(systemName: "figure.stand.line.dotted.figure.stand")
        )

        // Tab 2: 战报
        let reportVC = SUDailyReportViewController()
        let reportNav = SUBaseNavigationController(rootViewController: reportVC)
        reportNav.tabBarItem = UITabBarItem(
            title: "战报",
            image: UIImage(systemName: "chart.bar.doc.horizontal"),
            selectedImage: UIImage(systemName: "chart.bar.doc.horizontal.fill")
        )

        // Tab 3: 设置
        let settingsVC = SUSettingsViewController()
        let settingsNav = SUBaseNavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "设置",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        viewControllers = [monitorNav, reportNav, settingsNav]
    }
}
