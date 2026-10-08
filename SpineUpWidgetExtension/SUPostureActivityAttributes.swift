//
//  SUPostureActivityAttributes.swift
//  SpineUpWidgetExtension
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import ActivityKit

/// 灵动岛与锁屏实时活动属性契约 —— 供 Widget Extension 与主 App 跨进程通信使用 (iOS 26+)
struct SUPostureActivityAttributes: ActivityAttributes {

    /// 动态更新的状态数据 (ContentState)
    public struct ContentState: Codable, Hashable, Sendable {
        public var postureState: String
        public var pitchDeg: Double
        public var extraLoadKg: Double
        public var uprightMinutes: Int
        public var personaId: String
        public var quote: String

        public init(
            postureState: String = "upright",
            pitchDeg: Double = 0.0,
            extraLoadKg: Double = 0.0,
            uprightMinutes: Int = 0,
            personaId: String = "worker",
            quote: String = "做人要有骨气，端正挺拔中！"
        ) {
            self.postureState = postureState
            self.pitchDeg = pitchDeg
            self.extraLoadKg = extraLoadKg
            self.uprightMinutes = uprightMinutes
            self.personaId = personaId
            self.quote = quote
        }
    }

    /// 静态会话标题
    public var sessionTitle: String

    public init(sessionTitle: String = "SpineUp 实时体态守护") {
        self.sessionTitle = sessionTitle
    }
}
