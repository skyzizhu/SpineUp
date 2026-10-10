//
//  SUSceneDelegate.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import os

/// UI 窗口生命周期唯一入口 —— 严格在此处初始化 UIWindow 并绑定根视图控制器
class SUSceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let mainTabBarController = SUMainTabBarController()
        window.rootViewController = mainTabBarController
        window.overrideUserInterfaceStyle = SUThemeManager.shared.currentTheme.userInterfaceStyle
        self.window = window
        window.makeKeyAndVisible()

        // 如果在单元测试环境下运行，则跳过 UI 模态弹出，防止干扰 XCTest 注入与视图层级装载
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        if !isRunningTests && !SUUserDefaultsManager.shared.hasCompletedOnboarding {
            DispatchQueue.main.async {
                let onboardingVC = SUOnboardingViewController()
                onboardingVC.modalPresentationStyle = .fullScreen
                onboardingVC.onOnboardingCompleted = {
                    SULogger.lifecycle.info("User completed onboarding successfully")
                }
                mainTabBarController.present(onboardingVC, animated: true)
            }
        }

        SULogger.lifecycle.info("SUSceneDelegate attached UIWindow with SUMainTabBarController")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneDidDisconnect")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneDidBecomeActive")
        if SUWidgetSyncManager.shared.checkAndConsumePendingCalibration() {
            NotificationCenter.default.post(name: .suRequestCalibrationFromWidget, object: nil)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneWillResignActive")
        SUPostureSessionManager.shared.saveSession()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneWillEnterForeground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneDidEnterBackground")
        SUPostureSessionManager.shared.saveSession()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        SULogger.lifecycle.info("Opened with URL: \(url.absoluteString)")
        if url.scheme?.lowercased() == "spineup" {
            if let tabController = window?.rootViewController as? UITabBarController {
                tabController.selectedIndex = 0
            }
        }
    }
}
