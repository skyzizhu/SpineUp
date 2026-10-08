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
        self.window = window
        window.makeKeyAndVisible()

        SULogger.lifecycle.info("SUSceneDelegate attached UIWindow with SUMainTabBarController")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneDidDisconnect")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneDidBecomeActive")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneWillResignActive")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneWillEnterForeground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        SULogger.lifecycle.debug("SUSceneDelegate sceneDidEnterBackground")
    }
}
