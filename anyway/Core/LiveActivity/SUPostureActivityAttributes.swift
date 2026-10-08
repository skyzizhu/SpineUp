//
//  SUPostureActivityAttributes.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import ActivityKit

/// 灵动岛与锁屏实时活动属性结构体 —— 符合 ActivityKit 现代规范
struct SUPostureActivityAttributes: ActivityAttributes {

    /// 动态更新的状态数据 (ContentState)
    public struct ContentState: Codable, Hashable, Sendable {
        /// 当前体态状态 ("upright", "slightSlump", "severeSlump")
        public var postureState: String
        /// 头部倾斜角度（度数）
        public var pitchDeg: Double
        /// 额外承受力 (kg)
        public var extraLoadKg: Double
        /// 今日已坚持挺拔分钟数
        public var uprightMinutes: Int
        /// 宠物人格标识 ("worker", "cat", "coach")
        public var personaId: String
        /// 宠物最新拟人台词
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

    /// 静态启动属性
    public var sessionTitle: String

    public init(sessionTitle: String = "SpineUp 实时体态守护") {
        self.sessionTitle = sessionTitle
    }
}
