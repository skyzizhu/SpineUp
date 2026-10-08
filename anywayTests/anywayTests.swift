//
//  anywayTests.swift
//  anywayTests
//
//  Created by Skyzizhu on 2026/10/8.
//

import XCTest
@testable import anyway

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
        var completedPitch: Double?
        var completedRoll: Double?
        calibrationService.onCalibrationCompleted = { p, r in
            completedPitch = p
            completedRoll = r
        }

        calibrationService.calibrateImmediately(pitchRad: 0.25, rollRad: 0.10)
        XCTAssertEqual(completedPitch, 0.25)
        XCTAssertEqual(completedRoll, 0.10)
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

        var lastReading: SUPostureReading?
        let exp = expectation(description: "ViewModel received reading")
        vm.onReadingUpdated = { reading in
            lastReading = reading
            exp.fulfill()
        }

        vm.startMonitoring()
        vm.injectSimulatedAngles(pitchDeg: 5.0, rollDeg: 0.0)
        waitForExpectations(timeout: 1.0)

        XCTAssertNotNil(lastReading)
        XCTAssertEqual(vm.currentPostureState, .upright)
    }
}
