//
//  SUHealthKitManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import HealthKit
import os

/// Apple HealthKit 健康数据管理器 —— 专注时长写入正念，读取步数用于综合体态评估
final class SUHealthKitManager: @unchecked Sendable {

    static let shared = SUHealthKitManager()

    private let healthStore = HKHealthStore()
    private let isAvailable: Bool

    private init() {
        self.isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    /// 请求 HealthKit 读写权限
    func requestAuthorization() async -> Bool {
        guard isAvailable else {
            SULogger.lifecycle.info("HealthKit is not available on this device")
            return false
        }

        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return false
        }

        let writeTypes: Set<HKSampleType> = [mindfulType]
        let readTypes: Set<HKObjectType> = [stepType]

        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                if let error = error {
                    SULogger.lifecycle.warning("HealthKit authorization failed: \(error.localizedDescription, privacy: .public)")
                }
                continuation.resume(returning: success)
            }
        }
    }

    /// 将挺拔专注时长保存为 Apple Health 正念分钟数
    /// - Parameters:
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    func saveMindfulSession(startDate: Date, endDate: Date) async -> Bool {
        guard isAvailable, endDate > startDate else { return false }
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return false }

        let sample = HKCategorySample(
            type: mindfulType,
            value: 0,
            start: startDate,
            end: endDate,
            metadata: [HKMetadataKeyTimeZone: TimeZone.current.identifier]
        )

        return await withCheckedContinuation { continuation in
            healthStore.save(sample) { success, error in
                if let error = error {
                    SULogger.lifecycle.warning("Failed to save mindful session to HealthKit: \(error.localizedDescription, privacy: .public)")
                } else {
                    SULogger.lifecycle.info("Successfully recorded mindful session to HealthKit")
                }
                continuation.resume(returning: success)
            }
        }
    }

    /// 读取今日步数，辅助 AI 生成更精准的活动/久坐健康处方
    func fetchTodayStepCount() async -> Int {
        guard isAvailable else { return 0 }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let sum = result?.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    continuation.resume(returning: steps)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }
}
