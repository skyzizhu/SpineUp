//
//  SULiveServerIntegrationTests.swift
//  anywayTests
//
//  Created by Antigravity on 2026/10/8.
//

import XCTest
import Alamofire
@testable import anyway

/// 前后端真实环境端到端 (End-to-End) 联调测试用例
/// 验证 iOS 前端核心网络层、认证会话管理器、SUCloudAIEngine 与真实本地 Apache + MySQL + DeepSeek 后端的全链路通信
final class SULiveServerIntegrationTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // 确保使用配置的本地联调服务器地址
        XCTAssertEqual(SUAppConfig.currentEnvironment, .local)
        XCTAssertEqual(SUAppConfig.localServerRootURL, "http://192.168.31.101/spineup")
    }

    // MARK: - 1. 远程配置联调测试
    func test01_FetchRemoteConfigLive() async throws {
        let config = try await SUAPIClient.shared.config.fetchRemoteConfig()
        XCTAssertEqual(config.appName, "SpineUp")
        XCTAssertEqual(config.latestVersion, "1.0.0")
        XCTAssertEqual(config.slightSlumpThreshold, 15.0)
        XCTAssertEqual(config.severeSlumpThreshold, 30.0)
        XCTAssertGreaterThan(config.aiGenerationTimeoutSec, 0)
    }

    // MARK: - 2. 访客无感免密登录联调测试
    func test02_GuestAuthSilentLoginLive() async throws {
        let token = try await SUAuthSessionManager.shared.loginAsGuestSilently()
        XCTAssertFalse(token.isEmpty)
        XCTAssertTrue(SUAuthSessionManager.shared.isAuthenticated)
        XCTAssertEqual(SUAuthSessionManager.shared.currentToken, token)
    }

    // MARK: - 3. 用户主页与偏好拉取联调测试
    func test03_FetchUserProfileLive() async throws {
        _ = try await SUAuthSessionManager.shared.ensureAuthenticated()
        let profile = try await SUAPIClient.shared.user.fetchProfile()
        XCTAssertGreaterThan(profile.id, 0)
        XCTAssertFalse(profile.user_uuid.isEmpty)
        XCTAssertEqual(profile.is_guest, 1)
        XCTAssertFalse(profile.nickname.isEmpty)
    }

    // MARK: - 4. 坐姿校准零点云端同步联调测试
    func test04_UpdateUserSettingsLive() async throws {
        _ = try await SUAuthSessionManager.shared.ensureAuthenticated()
        let success = try await SUAPIClient.shared.user.syncSettings(
            pitch: -15.8,
            roll: 3.6,
            persona: "coach",
            slightThreshold: 18.0,
            severeThreshold: 35.0
        )
        XCTAssertTrue(success)

        // 重新获取验证是否已落盘至 MySQL
        let updatedProfile = try await SUAPIClient.shared.user.fetchProfile()
        XCTAssertEqual(updatedProfile.active_persona_id, "coach")
        if let pitch = updatedProfile.calibration_base_pitch {
            XCTAssertEqual(pitch, -15.8, accuracy: 0.01)
        }
    }

    // MARK: - 5. 每日体态监测会话云端同步联调测试
    func test05_SyncPostureSessionLive() async throws {
        _ = try await SUAuthSessionManager.shared.ensureAuthenticated()

        var testSession = SUPostureSession(dateString: "2026-10-08")
        testSession.uprightDurationSec = 3600.0
        testSession.slumpDurationSec = 450.0
        testSession.longestUprightStreakSec = 1800.0
        testSession.accumulatedExtraLoadKg = 15.4
        testSession.violationsCount = 6

        let result = try await SUAPIClient.shared.session.syncSession(testSession)
        XCTAssertTrue(result.synced)
    }

    // MARK: - 6. SUCloudAIEngine 真实 DeepSeek 大模型实时违规提醒联调 (打工人设)
    func test06_SUCloudAIEngineDeepSeekReminderWorker() async throws {
        let engine = SUCloudAIEngine(timeoutInterval: 8.0)
        let context = SUPostureContext(
            angleDeg: 34.5,
            durationSec: 9.0,
            persona: .worker,
            state: .severeSlump
        )

        let reminderText = try await engine.generateReminder(context: context)
        XCTAssertFalse(reminderText.isEmpty)
        XCTAssertLessThanOrEqual(reminderText.count, 60)
        print(">>> [DeepSeek Worker 实测文本]: \(reminderText)")
    }

    // MARK: - 7. SUCloudAIEngine 真实 DeepSeek 大模型实时违规提醒联调 (猫咪人设)
    func test07_SUCloudAIEngineDeepSeekReminderCat() async throws {
        let engine = SUCloudAIEngine(timeoutInterval: 8.0)
        let context = SUPostureContext(
            angleDeg: 21.0,
            durationSec: 5.0,
            persona: .cat,
            state: .slightSlump
        )

        let reminderText = try await engine.generateReminder(context: context)
        XCTAssertFalse(reminderText.isEmpty)
        XCTAssertLessThanOrEqual(reminderText.count, 60)
        print(">>> [DeepSeek Cat 实测文本]: \(reminderText)")
    }

    // MARK: - 8. SUCloudAIEngine 真实 DeepSeek 大模型实时违规提醒联调 (私教人设)
    func test08_SUCloudAIEngineDeepSeekReminderCoach() async throws {
        let engine = SUCloudAIEngine(timeoutInterval: 8.0)
        let context = SUPostureContext(
            angleDeg: 30.0,
            durationSec: 8.0,
            persona: .coach,
            state: .severeSlump
        )

        let reminderText = try await engine.generateReminder(context: context)
        XCTAssertFalse(reminderText.isEmpty)
        XCTAssertLessThanOrEqual(reminderText.count, 60)
        print(">>> [DeepSeek Coach 实测文本]: \(reminderText)")
    }
}
