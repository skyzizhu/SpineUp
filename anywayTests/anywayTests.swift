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
        XCTAssertFalse(SUAppConfig.appDisplayName.isEmpty)
        XCTAssertGreaterThan(SUAppConfig.voiceReminderCooldownSeconds, 0)
    }

    func testMotionConstants() {
        XCTAssertLessThan(SUMotionConstants.slightSlumpAngleThreshold, SUMotionConstants.severeSlumpAngleThreshold)
        XCTAssertGreaterThan(SUMotionConstants.slumpTriggerBufferDuration, 0)
    }

    func testMockMotionManagerAngles() {
        let mockManager = SUMockMotionManager()
        var lastReading: SUPostureReading?

        let expectation = self.expectation(description: "Reading emitted")
        mockManager.onReadingUpdated = { reading in
            lastReading = reading
            expectation.fulfill()
        }

        mockManager.injectSimulatedAngles(pitchDeg: 30.0, rollDeg: 0.0)
        waitForExpectations(timeout: 1.0)

        XCTAssertNotNil(lastReading)
        XCTAssertEqual(lastReading?.state, .severeSlump)
        XCTAssertGreaterThan(lastReading?.extraLoadKg ?? 0, 0)
    }
}
