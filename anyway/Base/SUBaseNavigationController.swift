//
//  SUBaseNavigationController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit

/// 基础导航控制器基类 —— 严格使用系统原生 UINavigationController 并通过现代 UINavigationBarAppearance 配置
final class SUBaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
    }

    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.prefersLargeTitles = false
        navigationBar.tintColor = .systemBlue
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? [.portrait, .landscapeLeft, .landscapeRight]
    }
}
