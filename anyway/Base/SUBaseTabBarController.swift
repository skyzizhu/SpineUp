//
//  SUBaseTabBarController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit

/// 基础标签栏控制器基类 —— 严格使用系统原生 UITabBarController 并通过现代 UITabBarAppearance 配置
class SUBaseTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .systemBlue
    }
}
