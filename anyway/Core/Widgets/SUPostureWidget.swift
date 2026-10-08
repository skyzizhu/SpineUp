//
//  SUPostureWidget.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import WidgetKit
import SwiftUI
import AppIntents

/// 小组件数据实体条目
struct SUPostureWidgetEntry: TimelineEntry {
    let date: Date
    let postureState: String
    let uprightMinutes: Int
    let energyCoins: Int
    let score: Int
    let personaId: String
}

/// 桌面小组件 TimelineProvider
struct SUPostureTimelineProvider: TimelineProvider {
    typealias Entry = SUPostureWidgetEntry

    func placeholder(in context: Context) -> SUPostureWidgetEntry {
        SUPostureWidgetEntry(
            date: Date(),
            postureState: "upright",
            uprightMinutes: 42,
            energyCoins: 128,
            score: 95,
            personaId: "worker"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SUPostureWidgetEntry) -> Void) {
        let entry = SUPostureWidgetEntry(
            date: Date(),
            postureState: "upright",
            uprightMinutes: 42,
            energyCoins: 128,
            score: 95,
            personaId: "worker"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SUPostureWidgetEntry>) -> Void) {
        let session = SUPostureSessionManager.shared.getTodaySession()
        let coins = SUSpineEnergyManager.shared.totalCoins
        let entry = SUPostureWidgetEntry(
            date: Date(),
            postureState: "upright",
            uprightMinutes: Int(session.uprightDurationSec / 60.0),
            energyCoins: coins,
            score: session.score,
            personaId: SUPetPersonaManager.shared.currentPersona.rawValue
        )

        // 每 15 分钟刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

/// 小尺寸小组件视图
struct SUPostureWidgetSmallView: View {
    let entry: SUPostureWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: personaIcon(for: entry.personaId))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.blue)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    Text("\(entry.energyCoins)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Text("骨气评分")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(entry.score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("分")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
    }

    private func personaIcon(for id: String) -> String {
        switch id {
        case "cat": return "cat.fill"
        case "coach": return "figure.mind.and.body"
        default: return "briefcase.fill"
        }
    }
}

/// 中尺寸小组件视图（含一键校准交互按钮）
struct SUPostureWidgetMediumView: View {
    let entry: SUPostureWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.blue)
                    Text("SpineUp 挺拔记录")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("今日挺拔")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(entry.uprightMinutes) 分钟")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("健康评分")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(entry.score) 分")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            VStack {
                Button(intent: SUCalibrationIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: "scope")
                            .font(.system(size: 20, weight: .semibold))
                        Text("校准")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(width: 68, height: 68)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }
}

/// 桌面小组件入口配置
struct SUPostureWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SUPostureWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SUPostureWidgetSmallView(entry: entry)
        default:
            SUPostureWidgetMediumView(entry: entry)
        }
    }
}
