//
//  anywayTests.swift
//  anywayTests
//
//  Created by Skyzizhu on 2026/10/8.
//

import XCTest
import Alamofire
@testable import anyway

/// 测试专属线程安全容器 —— 满足 Swift 6 严格并发检查规范
final class SUTestBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T
    init(_ value: T) { self._value = value }
    var value: T {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}

final class anywayTests: XCTestCase {

    func testAppConfigConstants() {
        XCTAssertEqual(SUAppConfig.appName, "SpineUp")
        XCTAssertEqual(SUAppConfig.bundleDisplayName, "SpineUp")
        XCTAssertFalse(SUAppConfig.appDisplayName.isEmpty)
        XCTAssertGreaterThan(SUAppConfig.voiceReminderCooldownSeconds, 0)
    }

    func testMotionConstants() {
        XCTAssertLessThan(SUMotionConstants.slightSlumpAngleThreshold, SUMotionConstants.severeSlumpAngleThreshold)
        XCTAssertGreaterThan(SUMotionConstants.slumpTriggerBufferDuration, 0)
    }

    func testUserDefaultsManager() {
        let testDefaults = UserDefaults(suiteName: "SUUnitTestSuite") ?? .standard
        testDefaults.removePersistentDomain(forName: "SUUnitTestSuite")
        let manager = SUUserDefaultsManager(defaults: testDefaults)

        XCTAssertFalse(manager.hasCompletedOnboarding)
        manager.hasCompletedOnboarding = true
        XCTAssertTrue(manager.hasCompletedOnboarding)

        XCTAssertFalse(manager.isCalibrated)
        manager.saveCalibrationBaseline(pitch: 0.15, roll: -0.05)
        XCTAssertTrue(manager.isCalibrated)
        XCTAssertEqual(manager.calibrationBasePitch, 0.15, accuracy: 0.001)
        XCTAssertEqual(manager.calibrationBaseRoll, -0.05, accuracy: 0.001)

        manager.clearCalibration()
        XCTAssertFalse(manager.isCalibrated)
    }

    func testCalibrationService() {
        let testDefaults = UserDefaults(suiteName: "SUCalibrationTestSuite") ?? .standard
        testDefaults.removePersistentDomain(forName: "SUCalibrationTestSuite")
        let userDefaultsManager = SUUserDefaultsManager(defaults: testDefaults)
        let calibrationService = SUCalibrationService(userDefaultsManager: userDefaultsManager)

        // 即时校准
        let completedPitch = SUTestBox<Double?>(nil)
        let completedRoll = SUTestBox<Double?>(nil)
        calibrationService.onCalibrationCompleted = { p, r in
            completedPitch.value = p
            completedRoll.value = r
        }

        calibrationService.calibrateImmediately(pitchRad: 0.25, rollRad: 0.10)
        XCTAssertEqual(completedPitch.value, 0.25)
        XCTAssertEqual(completedRoll.value, 0.10)
        XCTAssertEqual(calibrationService.savedBaseline?.pitch, 0.25)
    }

    func testPostureStateEngineFilter() {
        let engine = SUPostureStateEngine()

        // 模拟端坐基准 (0 rad)
        let reading1 = engine.processFrame(
            rawPitchRad: 0.0,
            rawRollRad: 0.0,
            basePitchRad: 0.0,
            baseRollRad: 0.0
        )
        XCTAssertEqual(reading1.relativePitchDeg, 0.0, accuracy: 0.1)
        XCTAssertEqual(reading1.state, .upright)
        XCTAssertEqual(reading1.extraLoadKg, 0.0, accuracy: 0.1)

        // 模拟单帧大幅低头 (例如 30度 = 0.5236 rad)，此时由于 10s 防抖缓冲尚未超时，状态依然为 upright
        let slumpRad = 30.0 * .pi / 180.0
        let reading2 = engine.processFrame(
            rawPitchRad: slumpRad,
            rawRollRad: 0.0,
            basePitchRad: 0.0,
            baseRollRad: 0.0
        )
        // 单帧滑动平均使得角度在平滑上升
        XCTAssertGreaterThan(reading2.relativePitchDeg, 0.0)
        // 瞬时低头不会立刻误判（防抖有效）
        XCTAssertEqual(reading2.state, .upright)
    }

    func testPostureMonitorViewModel() {
        let mockManager = SUMockMotionManager()
        let vm = SUPostureMonitorViewModel(motionService: mockManager)

        let lastReading = SUTestBox<SUPostureReading?>(nil)
        let exp = expectation(description: "ViewModel received reading")
        vm.onReadingUpdated = { reading in
            lastReading.value = reading
            exp.fulfill()
        }

        vm.startMonitoring()
        vm.injectSimulatedAngles(pitchDeg: 5.0, rollDeg: 0.0)
        waitForExpectations(timeout: 1.0)

        XCTAssertNotNil(lastReading.value)
        XCTAssertEqual(vm.currentPostureState, .upright)
    }

    // MARK: - Phase 2 专属单元测试
    func testPetPersonaAttributes() {
        for persona in SUPetPersona.allCases {
            XCTAssertFalse(persona.displayName.isEmpty)
            XCTAssertFalse(persona.iconSystemName.isEmpty)
            XCTAssertGreaterThan(persona.speechRate, 0.0)
            XCTAssertGreaterThan(persona.speechPitchMultiplier, 0.0)
        }
        XCTAssertEqual(SUPetPersona.from(id: "invalid_id"), .worker)
    }

    func testPetPersonaManager() {
        let testDefaults = UserDefaults(suiteName: "SUPersonaTestSuite") ?? .standard
        testDefaults.removePersistentDomain(forName: "SUPersonaTestSuite")
        let defaultsManager = SUUserDefaultsManager(defaults: testDefaults)
        let personaManager = SUPetPersonaManager(userDefaultsManager: defaultsManager)

        XCTAssertEqual(personaManager.currentPersona, .worker)

        let changedPersona = SUTestBox<SUPetPersona?>(nil)
        personaManager.onPersonaChanged = { p in
            changedPersona.value = p
        }

        personaManager.selectPersona(.cat)
        XCTAssertEqual(personaManager.currentPersona, .cat)
        XCTAssertEqual(changedPersona.value, .cat)
        XCTAssertEqual(defaultsManager.activePetPersonaId, "cat")
    }

    func testPromptBuilder() {
        let context = SUPostureContext(
            angleDeg: 28.0,
            durationSec: 12.0,
            violationCountToday: 3,
            currentTime: Date(),
            persona: .worker,
            streakDays: 5,
            state: .severeSlump,
            extraLoadKg: 18.0
        )

        let systemPrompt = SUPromptBuilder.buildSystemPrompt(for: .worker)
        let userPrompt = SUPromptBuilder.buildUserPrompt(from: context)

        XCTAssertTrue(systemPrompt.contains("SpineUp"))
        XCTAssertTrue(systemPrompt.contains("毒舌打工人"))
        XCTAssertTrue(userPrompt.contains("28"))
        XCTAssertTrue(userPrompt.contains("3"))
    }

    func testOfflineCorpusGeneration() {
        for persona in SUPetPersona.allCases {
            let context = SUPostureContext(
                angleDeg: 20.0,
                durationSec: 15.0,
                violationCountToday: 2,
                currentTime: Date(),
                persona: persona,
                streakDays: 3,
                state: .slightSlump,
                extraLoadKg: 12.0
            )
            let line = SUOfflineCorpus.pickLine(for: context)
            XCTAssertFalse(line.isEmpty)
            XCTAssertFalse(line.contains("{count}"))
            XCTAssertFalse(line.contains("{angle}"))
        }
    }

    func testSpineEnergyManager() {
        let testDefaults = UserDefaults(suiteName: "SUEnergyTestSuite") ?? .standard
        testDefaults.removePersistentDomain(forName: "SUEnergyTestSuite")
        let defaultsManager = SUUserDefaultsManager(defaults: testDefaults)
        let energyManager = SUSpineEnergyManager(userDefaultsManager: defaultsManager)

        let initialCoins = energyManager.totalCoins
        // 累积 65 秒挺拔时间，触发铸造 1 枚骨气币
        energyManager.trackUprightFrame(deltaSeconds: 65.0)
        XCTAssertGreaterThan(energyManager.totalCoins, initialCoins)
        XCTAssertGreaterThanOrEqual(energyManager.streakDays, 1)
    }

    func testSettingsViewModel() {
        let testDefaults = UserDefaults(suiteName: "SUSettingsTestSuite") ?? .standard
        testDefaults.removePersistentDomain(forName: "SUSettingsTestSuite")
        let defaultsManager = SUUserDefaultsManager(defaults: testDefaults)
        let personaManager = SUPetPersonaManager(userDefaultsManager: defaultsManager)
        let vm = SUSettingsViewModel(userDefaultsManager: defaultsManager, personaManager: personaManager)

        XCTAssertTrue(vm.isVoiceAlertEnabled)
        vm.setVoiceAlertEnabled(false)
        XCTAssertFalse(vm.isVoiceAlertEnabled)
        XCTAssertFalse(defaultsManager.isVoiceAlertEnabled)

        vm.selectPersona(.coach)
        XCTAssertEqual(vm.activePersona, .coach)
        XCTAssertEqual(defaultsManager.activePetPersonaId, "coach")
    }

    // MARK: - Phase 3 专属单元测试
    func testErgonomicsCalculator() {
        XCTAssertEqual(SUErgonomicsCalculator.calculateInstantLoadKg(pitchDeg: 0.0), 5.0, accuracy: 0.1)
        XCTAssertEqual(SUErgonomicsCalculator.calculateInstantLoadKg(pitchDeg: 15.0), 12.0, accuracy: 0.1)
        XCTAssertEqual(SUErgonomicsCalculator.calculateInstantLoadKg(pitchDeg: 30.0), 18.0, accuracy: 0.1)
        XCTAssertEqual(SUErgonomicsCalculator.calculateInstantLoadKg(pitchDeg: 45.0), 22.0, accuracy: 0.1)

        XCTAssertEqual(SUErgonomicsCalculator.calculateExtraLoadKg(pitchDeg: 0.0), 0.0, accuracy: 0.1)
        XCTAssertGreaterThan(SUErgonomicsCalculator.calculateExtraLoadKg(pitchDeg: 30.0), 10.0)

        // 生活化实体换算
        let milkTea = SUErgonomicsCalculator.calculateEquivalentItem(accumulatedKg: 1.0)
        XCTAssertEqual(milkTea.name, "珍珠奶茶")
        XCTAssertEqual(milkTea.iconSystemName, "cup.and.saucer.fill")

        let brick = SUErgonomicsCalculator.calculateEquivalentItem(accumulatedKg: 5.0)
        XCTAssertEqual(brick.name, "建筑红砖")
        XCTAssertEqual(brick.iconSystemName, "square.stack.3d.down.forward.fill")

        let cat = SUErgonomicsCalculator.calculateEquivalentItem(accumulatedKg: 8.0)
        XCTAssertEqual(cat.name, "成年胖橘猫")
        XCTAssertEqual(cat.iconSystemName, "cat.fill")
    }

    func testPostureSessionModel() {
        let session = SUPostureSession(
            dateString: "2026-10-08",
            uprightDurationSec: 3600, // 1小时
            slumpDurationSec: 300,    // 5分钟
            longestUprightStreakSec: 1800,
            violationsCount: 2,
            accumulatedExtraLoadKg: 4.5
        )

        XCTAssertEqual(session.totalDurationSec, 3900)
        XCTAssertGreaterThan(session.uprightRatio, 0.9)
        XCTAssertGreaterThanOrEqual(session.score, 80)
        XCTAssertEqual(session.grade, "A")
        XCTAssertEqual(session.gradeTitle, "傲然挺立")
        XCTAssertFalse(session.formattedUprightTime.isEmpty)
    }

    func testPostureSessionManager() {
        let manager = SUPostureSessionManager.shared
        let initial = manager.getTodaySession()

        // 模拟 10 秒端正
        manager.recordFrame(state: .upright, pitchDeg: 0.0, deltaSeconds: 10.0)
        let afterUpright = manager.getTodaySession()
        XCTAssertGreaterThanOrEqual(afterUpright.uprightDurationSec, initial.uprightDurationSec)

        // 模拟违规
        manager.recordViolation()
        let afterViolation = manager.getTodaySession()
        XCTAssertGreaterThanOrEqual(afterViolation.violationsCount, 1)
    }

    func testDailyReportGenerator() {
        let session = SUPostureSession(
            dateString: "2026-10-08",
            uprightDurationSec: 1800,
            slumpDurationSec: 600,
            longestUprightStreakSec: 900,
            violationsCount: 3,
            accumulatedExtraLoadKg: 7.2
        )

        let report = SUDailyReportGenerator.generateReport(session: session, persona: .worker)
        XCTAssertFalse(report.diagnosisTitle.isEmpty)
        XCTAssertFalse(report.doctorPrescription.isEmpty)
        XCTAssertFalse(report.personaComment.isEmpty)
        XCTAssertEqual(report.persona, .worker)
        XCTAssertEqual(report.equivalentItem.iconSystemName, "cat.fill")
    }

    func testDailyReportViewModel() {
        let vm = SUDailyReportViewModel()
        XCTAssertFalse(vm.currentReport.diagnosisTitle.isEmpty)
        XCTAssertFalse(vm.currentReport.doctorPrescription.isEmpty)

        vm.refreshReport()
        XCTAssertNotNil(vm.currentReport)
    }

    func testShareCardImageRendering() {
        let session = SUPostureSession(
            dateString: "2026-10-08",
            uprightDurationSec: 2400,
            slumpDurationSec: 400,
            longestUprightStreakSec: 1200,
            violationsCount: 1,
            accumulatedExtraLoadKg: 3.5
        )
        let report = SUDailyReportGenerator.generateReport(session: session, persona: .cat)

        let shareCard = SUShareCardView()
        shareCard.configure(with: report)
        let image = shareCard.renderAsImage()

        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 100)
        XCTAssertGreaterThan(image.size.height, 100)
    }

    // MARK: - Phase 4 核心单元测试

    func testLiveActivityAttributesAndContentState() throws {
        let attributes = SUPostureActivityAttributes(sessionTitle: "测试守护")
        XCTAssertEqual(attributes.sessionTitle, "测试守护")

        let state = SUPostureActivityAttributes.ContentState(
            postureState: "upright",
            pitchDeg: 12.5,
            extraLoadKg: 2.3,
            uprightMinutes: 30,
            personaId: "worker",
            quote: "保持脊椎挺拔！"
        )
        XCTAssertEqual(state.postureState, "upright")
        XCTAssertEqual(state.pitchDeg, 12.5)
        XCTAssertEqual(state.extraLoadKg, 2.3)
        XCTAssertEqual(state.uprightMinutes, 30)
        XCTAssertEqual(state.personaId, "worker")
        XCTAssertEqual(state.quote, "保持脊椎挺拔！")

        // 验证 Codable 序列化与反序列化
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        let decoder = JSONDecoder()
        let decodedState = try decoder.decode(SUPostureActivityAttributes.ContentState.self, from: data)
        XCTAssertEqual(decodedState, state)
    }

    func testLocalizationManagerAndRTL() {
        let manager = SULocalizationManager.shared

        // 验证支持的 7 种语言完整性
        XCTAssertEqual(SULanguage.allCases.count, 7)
        let expectedCodes: Set<String> = ["en", "zh-Hans", "zh-Hant", "ja", "ko", "ar", "fr"]
        let actualCodes = Set(SULanguage.allCases.map { $0.rawValue })
        XCTAssertEqual(actualCodes, expectedCodes)

        // 验证 RTL 排版语言判定（阿拉伯语必须为 true，其他为 false）
        XCTAssertTrue(SULanguage.ar.isRTL)
        XCTAssertFalse(SULanguage.en.isRTL)
        XCTAssertFalse(SULanguage.zhHans.isRTL)
        XCTAssertFalse(SULanguage.zhHant.isRTL)
        XCTAssertFalse(SULanguage.ja.isRTL)
        XCTAssertFalse(SULanguage.ko.isRTL)
        XCTAssertFalse(SULanguage.fr.isRTL)

        // 验证动态语言切换
        manager.setLanguage(.ar)
        XCTAssertEqual(manager.currentLanguage, .ar)
        XCTAssertTrue(manager.isRightToLeft)

        manager.setLanguage(.en)
        XCTAssertEqual(manager.currentLanguage, .en)
        XCTAssertFalse(manager.isRightToLeft)

        // 验证默认兜底查找
        let fallbackResult = manager.localizedString(for: "non_existent_key_123", defaultValue: "FallbackText")
        XCTAssertEqual(fallbackResult, "FallbackText")
    }

    func testDuoLayoutHelper() {
        // 1. Compact 尺寸类
        let compactTraits = UITraitCollection(horizontalSizeClass: .compact)
        let compactSize = CGSize(width: 393, height: 852)
        let compactMode = SUDuoLayoutHelper.currentDisplayMode(size: compactSize, traitCollection: compactTraits)
        XCTAssertEqual(compactMode, .compact)

        // 2. Regular 尺寸类 (展开双屏态)
        let regularTraits = UITraitCollection(horizontalSizeClass: .regular)
        let regularSize = CGSize(width: 800, height: 600)
        let regularMode = SUDuoLayoutHelper.currentDisplayMode(size: regularSize, traitCollection: regularTraits)
        XCTAssertEqual(regularMode, .regularDual)

        // 3. Tabletop 桌面半折叠悬停态
        let tabletopSize = CGSize(width: 700, height: 950)
        let tabletopMode = SUDuoLayoutHelper.currentDisplayMode(size: tabletopSize, traitCollection: regularTraits)
        XCTAssertEqual(tabletopMode, .tabletop)

        // 4. 双栏分割与中缝避让计算
        let split = SUDuoLayoutHelper.splitColumnLayout(totalWidth: 800)
        XCTAssertGreaterThan(split.leftWidth, 0)
        XCTAssertEqual(split.leftWidth, split.rightWidth)
        XCTAssertEqual(split.hingeSpacing, 20.0)

        // 5. Tabletop 上下屏幕高度计算与避让折痕
        let vertical = SUDuoLayoutHelper.tabletopVerticalLayout(totalHeight: 900)
        XCTAssertGreaterThan(vertical.topHeight, 0)
        XCTAssertGreaterThan(vertical.bottomHeight, 0)
        XCTAssertEqual(vertical.foldSpacing, 24.0)

        // 6. 遮挡矩形计算
        let tabletopFoldRect = SUDuoLayoutHelper.foldOcclusionRect(for: tabletopSize, mode: .tabletop)
        XCTAssertEqual(tabletopFoldRect.height, 20.0)
        XCTAssertGreaterThan(tabletopFoldRect.width, 0)

        let dualFoldRect = SUDuoLayoutHelper.foldOcclusionRect(for: regularSize, mode: .regularDual)
        XCTAssertEqual(dualFoldRect.width, 20.0)
        XCTAssertGreaterThan(dualFoldRect.height, 0)
    }

    func testNeckPomodoroManager() {
        let pomodoro = SUNeckPomodoroManager.shared
        pomodoro.stopSession()
        XCTAssertEqual(pomodoro.state, .idle)
        XCTAssertEqual(pomodoro.remainingSeconds, 25 * 60)

        // 启动专注工作阶段
        pomodoro.startWorkSession()
        XCTAssertEqual(pomodoro.state, .working)

        // 停止重置
        pomodoro.stopSession()
        XCTAssertEqual(pomodoro.state, .idle)
    }

    func testConnectionBannerView() {
        let banner = SUConnectionBannerView()
        XCTAssertNotNil(banner)

        // 切换不同状态不抛出异常
        banner.updateConnectionState(.connected)
        banner.updateConnectionState(.disconnected)
        banner.updateConnectionState(.unsupported)
    }

    @MainActor
    func testLiquidGlassView() {
        let glassView = SULiquidGlassView(cornerRadius: 20.0, isInteractive: true, tintColor: .systemBlue, isCapsule: false)
        XCTAssertNotNil(glassView)
        XCTAssertEqual(glassView.cornerRadius, 20.0)
        XCTAssertTrue(glassView.isInteractive)
        XCTAssertEqual(glassView.glassTintColor, .systemBlue)
        XCTAssertNotNil(glassView.contentView)

        // 胶囊态切换
        glassView.isCapsule = true
        glassView.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
        glassView.layoutSubviews()
        XCTAssertEqual(glassView.layer.cornerRadius, 22.0)
    }

    // MARK: - 网络与 API 接口层测试
    func testNetworkEndpointPathsAndMethods() {
        let guestReq = SUGuestAuthRequest(deviceUuid: "uuid-123", deviceModel: "iPhone", locale: "zh-Hans")
        let epGuest = SUNetworkEndpoint.guestLogin(request: guestReq)
        XCTAssertEqual(epGuest.path, "/auth/guest")
        XCTAssertEqual(epGuest.method, .post)
        XCTAssertFalse(epGuest.requiresAuth)

        let epProfile = SUNetworkEndpoint.fetchUserProfile
        XCTAssertEqual(epProfile.path, "/users/me")
        XCTAssertEqual(epProfile.method, .get)
        XCTAssertTrue(epProfile.requiresAuth)

        let updateReq = SUUpdateSettingsRequest(activePersonaId: "cat", calibrationBasePitch: 0.1, calibrationBaseRoll: -0.1, slightSlumpThreshold: 16.0, severeSlumpThreshold: 32.0)
        let epUpdate = SUNetworkEndpoint.updateUserSettings(request: updateReq)
        XCTAssertEqual(epUpdate.path, "/users/settings")
        XCTAssertEqual(epUpdate.method, .put)
        XCTAssertTrue(epUpdate.requiresAuth)

        let aiReq = SUCloudAIEngine.ReminderRequest(systemPrompt: "sys", userPrompt: "usr", persona: "worker", angleDeg: 25.0, durationSec: 6.0, state: "severeSlump")
        let epAI = SUNetworkEndpoint.aiReminder(request: aiReq)
        XCTAssertEqual(epAI.path, "/ai/reminder")
        XCTAssertEqual(epAI.method, .post)
        XCTAssertFalse(epAI.requiresAuth)

        let syncReq = SUSyncSessionRequest(date: "2026-10-08", uprightDurationSec: 100, slumpDurationSec: 20, longestStreakSec: 80, accumulatedExtraLoadKg: 2.5, violationsCount: 1, score: 95, grade: "S")
        let epSync = SUNetworkEndpoint.syncSession(request: syncReq)
        XCTAssertEqual(epSync.path, "/sessions/sync")
        XCTAssertEqual(epSync.method, .post)
        XCTAssertTrue(epSync.requiresAuth)

        let epConfig = SUNetworkEndpoint.fetchAppConfig
        XCTAssertEqual(epConfig.path, "/config/app")
        XCTAssertEqual(epConfig.method, .get)
        XCTAssertFalse(epConfig.requiresAuth)
    }

    func testNetworkResponseCodable() throws {
        let jsonStr = """
        {
            "code": 200,
            "message": "success",
            "data": {
                "token": "mock.jwt.token",
                "userId": 42,
                "userUuid": "device-uuid-999",
                "isGuest": true
            },
            "timestamp": 1791448000
        }
        """
        let data = jsonStr.data(using: .utf8)!
        let response = try JSONDecoder().decode(SUNetworkResponse<SUAuthResponseData>.self, from: data)

        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.code, 200)
        XCTAssertEqual(response.message, "success")
        XCTAssertEqual(response.data?.token, "mock.jwt.token")
        XCTAssertEqual(response.data?.userId, 42)
        XCTAssertEqual(response.data?.userUuid, "device-uuid-999")
        XCTAssertEqual(response.data?.isGuest, true)
    }

    func testAuthSessionManagerTokenHandling() {
        let testDefaults = UserDefaults(suiteName: "SUAuthSessionTestSuite") ?? .standard
        testDefaults.removePersistentDomain(forName: "SUAuthSessionTestSuite")
        let userDefaultsManager = SUUserDefaultsManager(defaults: testDefaults)
        let authManager = SUAuthSessionManager(userDefaults: userDefaultsManager)

        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentToken)

        authManager.saveToken("sample_token_abc")
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertEqual(authManager.currentToken, "sample_token_abc")

        authManager.clearToken()
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentToken)
    }

    func testAppConfigApiBaseURLSwitching() {
        let original = SUUserDefaultsManager.shared.customApiBaseURL
        defer { SUUserDefaultsManager.shared.customApiBaseURL = original }

        // 默认情况下指向配置的 localServerRootURL + /v1
        SUUserDefaultsManager.shared.customApiBaseURL = nil
        XCTAssertEqual(SUAppConfig.localServerRootURL, "http://192.168.31.101/spineup")
        XCTAssertEqual(SUAppConfig.apiBaseURL, "http://192.168.31.101/spineup/v1")

        // 模拟用户设置自定义本地开发服务器地址覆盖
        SUUserDefaultsManager.shared.customApiBaseURL = "http://192.168.1.100:8080/v1"
        XCTAssertEqual(SUUserDefaultsManager.shared.customApiBaseURL, "http://192.168.1.100:8080/v1")
        XCTAssertEqual(SUAppConfig.apiBaseURL, "http://192.168.1.100:8080/v1")

        SUUserDefaultsManager.shared.customApiBaseURL = nil
        XCTAssertNil(SUUserDefaultsManager.shared.customApiBaseURL)
        XCTAssertEqual(SUAppConfig.apiBaseURL, "http://192.168.31.101/spineup/v1")
    }

    // MARK: - UI 优化测试：首页顶部状态栏解耦与偏好设置多语言二级页
    func testPostureMonitorTopStatusBarDecoupledFromNavigationBar() {
        let monitorVC = SUPostureMonitorViewController()
        monitorVC.loadViewIfNeeded()

        // 验证导航栏左右按钮已被彻底解耦 (为 nil)，完全释放 title 呼吸空间
        XCTAssertNil(monitorVC.navigationItem.leftBarButtonItem)
        XCTAssertNil(monitorVC.navigationItem.rightBarButtonItem)
        XCTAssertFalse(monitorVC.navigationItem.title?.isEmpty ?? true)
    }

    func testLanguageSettingViewControllerInstantiationAndLocalization() {
        let langVC = SULanguageSettingViewController()
        langVC.loadViewIfNeeded()

        XCTAssertFalse(langVC.navigationItem.title?.isEmpty ?? true)
        XCTAssertEqual(langVC.navigationItem.largeTitleDisplayMode, .never)

        // 验证语言切换能够发布广播通知
        let originalLang = SULocalizationManager.shared.currentLanguage
        defer { SULocalizationManager.shared.setLanguage(originalLang) }

        let expectation = expectation(description: "LanguageDidChangeNotification received")
        var receivedNotification = false

        let observer = NotificationCenter.default.addObserver(
            forName: SULocalizationManager.languageDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            receivedNotification = true
            expectation.fulfill()
        }

        let targetLang: SULanguage = (originalLang == .en) ? .zhHans : .en
        SULocalizationManager.shared.setLanguage(targetLang)

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(receivedNotification)
        XCTAssertEqual(SULocalizationManager.shared.currentLanguage, targetLang)
        NotificationCenter.default.removeObserver(observer)
    }

    func testSettingsNavigationRowViewInteraction() {
        var didTap = false
        let rowView = SUSettingsNavigationRowView(
            title: "语言 / Language",
            value: "简体中文",
            iconSystemName: "globe",
            iconBackground: .systemIndigo
        )
        rowView.onTap = {
            didTap = true
        }

        rowView.setValue("English")
        rowView.setTitle("Language")

        // 模拟触发手势事件
        if rowView.gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) == true {
            rowView.onTap?()
        }

        XCTAssertTrue(didTap)
    }
}
