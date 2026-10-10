//
//  SULeaderboardService.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import Foundation

/// 排行榜数据服务 —— 提供正向排行榜动态合成与云端对接扩展
final class SULeaderboardService: @unchecked Sendable {

    static let shared = SULeaderboardService()

    private let userDefaultsManager: SUUserDefaultsManager
    private let energyManager: SUSpineEnergyManager
    private let personaManager: SUPetPersonaManager

    private let lock = NSLock()
    private var cachedRemoteEntries: [SULeaderboardCategory: [SULeaderboardEntry]] = [:]
    private var cachedMyRank: [SULeaderboardCategory: SULeaderboardEntry] = [:]
    private var cachedTotalUsers: [SULeaderboardCategory: Int] = [:]

    init(
        userDefaultsManager: SUUserDefaultsManager = .shared,
        energyManager: SUSpineEnergyManager = .shared,
        personaManager: SUPetPersonaManager = .shared
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.energyManager = energyManager
        self.personaManager = personaManager
    }

    /// 从云端真实数据库拉取排行榜列表
    func fetchRemoteLeaderboard(for category: SULeaderboardCategory) async throws -> [SULeaderboardEntry] {
        let typeStr: String
        switch category {
        case .energyCoins:
            typeStr = "energy"
        case .postureQuality:
            typeStr = "quality"
        case .streakDays:
            typeStr = "streak"
        }

        let response = try await SUAPIClient.shared.leaderboard.fetchLeaderboard(type: typeStr, page: 1, pageSize: 50)
        let currentUserName = userDefaultsManager.userName
        let currentUserId = response.my_rank?.user_id

        let remoteEntries: [SULeaderboardEntry] = response.top_list.map { item in
            let isMe = (currentUserId != nil && item.user_id == currentUserId) || (item.user_name == currentUserName)
            let tag: String?
            if item.rank == 1 {
                tag = SULocalized("leaderboard_tag_top1", default: "榜首领跑")
            } else if item.streak_days >= 21 {
                tag = SULocalized("leaderboard_tag_master", default: "体态大师")
            } else if item.energy_coins >= 1000 {
                tag = SULocalized("leaderboard_tag_champion", default: "能量先锋")
            } else {
                tag = nil
            }

            return SULeaderboardEntry(
                id: "\(item.user_id)",
                rank: item.rank,
                userName: item.user_name,
                personaId: item.avatar_id.isEmpty ? "worker" : item.avatar_id,
                energyCoins: item.energy_coins,
                uprightRatioPercent: Int(round(item.quality_ratio)),
                streakDays: item.streak_days,
                isCurrentUser: isMe,
                tag: tag
            )
        }

        storeRemoteLeaderboardCache(
            category: category,
            remoteEntries: remoteEntries,
            totalParticipants: response.total_participants,
            myRank: response.my_rank
        )

        return remoteEntries
    }

    private func storeRemoteLeaderboardCache(
        category: SULeaderboardCategory,
        remoteEntries: [SULeaderboardEntry],
        totalParticipants: Int,
        myRank: SULeaderboardItemData?
    ) {
        lock.withLock {
            cachedRemoteEntries[category] = remoteEntries
            cachedTotalUsers[category] = totalParticipants
            if let mr = myRank {
                let myTag: String?
                if mr.rank == 1 {
                    myTag = SULocalized("leaderboard_tag_top1", default: "榜首领跑")
                } else if mr.streak_days >= 21 {
                    myTag = SULocalized("leaderboard_tag_master", default: "体态大师")
                } else if mr.energy_coins >= 1000 {
                    myTag = SULocalized("leaderboard_tag_champion", default: "能量先锋")
                } else {
                    myTag = nil
                }
                cachedMyRank[category] = SULeaderboardEntry(
                    id: "\(mr.user_id)",
                    rank: mr.rank,
                    userName: mr.user_name,
                    personaId: mr.avatar_id.isEmpty ? personaManager.currentPersona.rawValue : mr.avatar_id,
                    energyCoins: mr.energy_coins,
                    uprightRatioPercent: Int(round(mr.quality_ratio)),
                    streakDays: mr.streak_days,
                    isCurrentUser: true,
                    tag: myTag
                )
            }
        }
    }

    /// 更新用户个性昵称 (本地与真实后端同步)
    func updateUserName(_ newName: String) async throws {
        userDefaultsManager.userName = newName
        do {
            _ = try await SUAPIClient.shared.leaderboard.updateProfile(nickname: newName)
        } catch {
            // 离线状态下本地已保存，不阻塞用户
        }
    }

    /// 获取特定维度的排行榜列表 (优先返回已拉取的远端数据，无缓存时回退至本地合成算法)
    func fetchLeaderboard(for category: SULeaderboardCategory) -> [SULeaderboardEntry] {
        if let cached = lock.withLock({ cachedRemoteEntries[category] }), !cached.isEmpty {
            return cached
        }

        let currentUserName = userDefaultsManager.userName
        let currentCoins = energyManager.totalCoins
        let currentPersona = personaManager.currentPersona.rawValue
        let currentStreak = userDefaultsManager.streakDays

        // 模拟同城与社群挺拔伙伴样本 (正向积极打工人画像)
        var peers: [(id: String, name: String, persona: String, coins: Int, quality: Int, streak: Int, tag: String?)] = [
            ("user_101", "云端天鹅颈·米娅", "cat", 480, 98, 28, "天鹅颈榜首"),
            ("user_102", "不低头的极客阿飞", "worker", 420, 95, 21, "代码挺拔王"),
            ("user_103", "瑜伽课代表林老师", "coach", 390, 94, 19, "体态大师"),
            ("user_104", "告别富贵包的大明", "worker", 350, 92, 14, nil),
            ("user_105", "专注备考的糯米", "cat", 310, 89, 12, nil),
            ("user_106", "晨跑挺拔达人小凯", "coach", 280, 88, 10, nil),
            ("user_107", "端坐写报告的安安", "worker", 240, 85, 7, nil),
            ("user_108", "AirPods 守护者浩子", "cat", 210, 83, 5, nil),
            ("user_109", "拒绝圆肩的茜茜", "coach", 180, 80, 4, nil)
        ]

        // 用户的个人数据 (根据当前实际数据合成)
        let myCoins = max(currentCoins, 50)
        let myQuality = min(99, max(75, 85 + (myCoins % 13)))
        let myStreak = max(1, currentStreak)
        let myTag = myCoins >= 300 ? "挺拔先锋" : nil

        let myTuple = (
            id: "current_user",
            name: currentUserName,
            persona: currentPersona,
            coins: myCoins,
            quality: myQuality,
            streak: myStreak,
            tag: myTag
        )
        peers.append(myTuple)

        // 根据维度排序
        switch category {
        case .energyCoins:
            peers.sort { $0.coins > $1.coins }
        case .postureQuality:
            peers.sort { $0.quality > $1.quality }
        case .streakDays:
            peers.sort { $0.streak > $1.streak }
        }

        // 映射为带排名的实体条目
        return peers.enumerated().map { index, item in
            SULeaderboardEntry(
                id: item.id,
                rank: index + 1,
                userName: item.name,
                personaId: item.persona,
                energyCoins: item.coins,
                uprightRatioPercent: item.quality,
                streakDays: item.streak,
                isCurrentUser: (item.id == "current_user"),
                tag: item.tag
            )
        }
    }

    /// 获取当前用户在某维度的排位卡片信息
    func getCurrentUserRankInfo(for category: SULeaderboardCategory) -> (rank: Int, totalUsers: Int, entry: SULeaderboardEntry)? {
        let cachedInfo = lock.withLock { () -> (rank: Int, totalUsers: Int, entry: SULeaderboardEntry)? in
            if let myEntry = cachedMyRank[category] {
                let total = cachedTotalUsers[category] ?? cachedRemoteEntries[category]?.count ?? 1
                return (rank: myEntry.rank, totalUsers: total, entry: myEntry)
            }
            return nil
        }
        if let cachedInfo = cachedInfo {
            return cachedInfo
        }

        let list = fetchLeaderboard(for: category)
        if let userIndex = list.firstIndex(where: { $0.isCurrentUser }) {
            return (rank: userIndex + 1, totalUsers: list.count, entry: list[userIndex])
        }
        return nil
    }
}
