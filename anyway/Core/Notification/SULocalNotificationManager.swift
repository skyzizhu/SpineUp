//
//  SULocalNotificationManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/15.
//

import Foundation
import UserNotifications
import os

/// 本地定时提醒与久坐推送管理器 —— 提供早间佩戴提醒、傍晚战报生成通知与久坐站立提醒
final class SULocalNotificationManager: @unchecked Sendable {

    static let shared = SULocalNotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let userDefaultsManager: SUUserDefaultsManager

    init(userDefaultsManager: SUUserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
    }

    /// 请求系统通知授权
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                scheduleDailyReminders()
            }
            return granted
        } catch {
            SULogger.lifecycle.warning("Failed to request notification auth: \(error.localizedDescription)")
            return false
        }
    }

    /// 调度工作日早晚定时推送提醒
    func scheduleDailyReminders() {
        center.removePendingNotificationRequests(withIdentifiers: ["su_morning_reminder", "su_evening_reminder"])
        guard userDefaultsManager.isDailyNotificationEnabled else { return }

        // 1. 早间 09:30 佩戴提醒
        var morningComponents = DateComponents()
        morningComponents.hour = 9
        morningComponents.minute = 30
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)

        let morningContent = UNMutableNotificationContent()
        morningContent.title = SULocalized("notif_morning_title", default: "早安！开启今天的骨气守护")
        morningContent.body = SULocalized("notif_morning_body", default: "戴上耳机，让挺拔身姿陪伴高效专注的一天。")
        morningContent.sound = .default

        let morningReq = UNNotificationRequest(identifier: "su_morning_reminder", content: morningContent, trigger: morningTrigger)
        center.add(morningReq)

        // 2. 傍晚 18:30 战报提醒
        var eveningComponents = DateComponents()
        eveningComponents.hour = 18
        eveningComponents.minute = 30
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)

        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = SULocalized("notif_evening_title", default: "今日骨气战报已生成")
        eveningContent.body = SULocalized("notif_evening_body", default: "快来看看今天的颈椎减负成果，为挺拔的自己点赞！")
        eveningContent.sound = .default

        let eveningReq = UNNotificationRequest(identifier: "su_evening_reminder", content: eveningContent, trigger: eveningTrigger)
        center.add(eveningReq)

        SULogger.lifecycle.info("Scheduled morning & evening posture notifications")
    }

    /// 取消所有每日提醒
    func cancelDailyReminders() {
        center.removePendingNotificationRequests(withIdentifiers: ["su_morning_reminder", "su_evening_reminder"])
    }

    /// 触发久坐站立提醒本地通知
    func sendSedentaryNotification(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = SULocalized("notif_sedentary_title", default: "久坐提醒：起来活动一下吧")
        content.body = String(format: SULocalized("notif_sedentary_body", default: "您已连续久坐 %d 分钟，站起来喝杯水，做做护颈舒展操吧！"), minutes)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "su_sedentary_\(UUID().uuidString)", content: content, trigger: trigger)
        center.add(req)
        SULogger.lifecycle.info("Dispatched sedentary local notification for \(minutes) mins")
    }
}
