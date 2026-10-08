//
//  SUAppDelegate.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import os

@main
class SUAppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        SULogger.lifecycle.info("\(SUAppConfig.appDisplayName) launching (Process Init)")
        return true
    }

    // MARK: - UISceneSession Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SUSceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        SULogger.lifecycle.info("Discarded scene sessions: \(sceneSessions.count)")
    }
}
