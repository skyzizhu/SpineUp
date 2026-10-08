//
//  SUPostureWidget.swift
//  SpineUpWidgetExtension
//
//  Created by Antigravity on 2026/10/8.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry

struct SUPostureEntry: TimelineEntry {
    let date: Date
    let postureState: String
    let pitchDeg: Double
    let extraLoadKg: Double
    let uprightMinutes: Int
    let petName: String
    let petIcon: String
    let quote: String

    static var preview: SUPostureEntry {
        SUPostureEntry(
            date: Date(),
            postureState: "upright",
            pitchDeg: 4.2,
            extraLoadKg: 0.0,
            uprightMinutes: 42,
            petName: "办公打工人",
            petIcon: "figure.walk.motion",
            quote: "做人要有骨气，端正挺拔中！"
        )
    }
}

// MARK: - Timeline Provider

struct SUPostureTimelineProvider: TimelineProvider {
    typealias Entry = SUPostureEntry

    func placeholder(in context: Context) -> SUPostureEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (SUPostureEntry) -> Void) {
        completion(.preview)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SUPostureEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.com.iashes.anyway")
        let pitch = userDefaults?.double(forKey: "currentPitchDeg") ?? 5.0
        let state = userDefaults?.string(forKey: "currentPostureState") ?? "upright"
        let uprightMins = userDefaults?.integer(forKey: "todayUprightMinutes") ?? 38
        let persona = userDefaults?.string(forKey: "currentPersonaId") ?? "worker"

        let extraLoad: Double
        if pitch > 20.0 {
            extraLoad = (pitch - 20.0) * 0.4
        } else {
            extraLoad = 0.0
        }

        let petIcon: String
        let petName: String
        switch persona {
        case "zen":
            petIcon = "sparkles"
            petName = "禅修老道"
        case "rebel":
            petIcon = "bolt.fill"
            petName = "叛逆朋克"
        case "medic":
            petIcon = "cross.case.fill"
            petName = "严厉骨科医"
        default:
            petIcon = "briefcase.fill"
            petName = "办公打工人"
        }

        let quote: String
        switch state {
        case "severeSlouch":
            quote = "你的脊椎在哭泣！快抬起下巴！"
        case "mildSlouch":
            quote = "脖子微倾斜，稍作调整更挺拔哦～"
        default:
            quote = "状态极佳，身姿如松，继续保持！"
        }

        let entry = SUPostureEntry(
            date: Date(),
            postureState: state,
            pitchDeg: pitch,
            extraLoadKg: extraLoad,
            uprightMinutes: uprightMins,
            petName: petName,
            petIcon: petIcon,
            quote: quote
        )

        // 15分钟后刷新小组件
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

struct SUPostureWidgetEntryView: View {
    var entry: SUPostureTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            Color(.secondarySystemBackground)
        }
    }
}

// MARK: - Small View

private struct SmallWidgetView: View {
    let entry: SUPostureEntry

    private var themeColor: Color {
        switch entry.postureState {
        case "severeSlouch":
            return Color.red
        case "mildSlouch":
            return Color.orange
        default:
            return Color(red: 0.18, green: 0.65, blue: 0.45)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Circle()
                        .fill(themeColor.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: entry.petIcon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(themeColor)
                }

                Spacer()

                Text("\(String(format: "%.0f", entry.pitchDeg))°")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(themeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.petName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Text("专注 \(entry.uprightMinutes)m")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(intent: SUCalibrationIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "scope")
                        .font(.system(size: 10, weight: .bold))
                    Text("校准")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(themeColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(4)
    }
}

// MARK: - Medium View

private struct MediumWidgetView: View {
    let entry: SUPostureEntry

    private var themeColor: Color {
        switch entry.postureState {
        case "severeSlouch":
            return Color.red
        case "mildSlouch":
            return Color.orange
        default:
            return Color(red: 0.18, green: 0.65, blue: 0.45)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 左侧宠物与状态
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.18))
                            .frame(width: 38, height: 38)
                        Image(systemName: entry.petIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(themeColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("SpineUp 宠物")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(entry.petName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }

                Text("「\(entry.quote)」")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer()

                HStack(spacing: 8) {
                    Label("\(entry.uprightMinutes) 分钟", systemImage: "clock.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    if entry.extraLoadKg > 0.5 {
                        Label("+\(String(format: "%.1f", entry.extraLoadKg))kg", systemImage: "scalemass.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
            }

            Divider()

            // 右侧指标与一键校准
            VStack(spacing: 10) {
                VStack(spacing: 2) {
                    Text("\(String(format: "%.1f", entry.pitchDeg))°")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(themeColor)
                    Text("当前倾角")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(intent: SUCalibrationIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "scope")
                            .font(.system(size: 12, weight: .bold))
                        Text("一键校准")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(themeColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 88)
        }
        .padding(4)
    }
}

// MARK: - Widget Configuration

struct SUPostureWidget: Widget {
    let kind: String = "com.iashes.anyway.postureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SUPostureTimelineProvider()) { entry in
            SUPostureWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SpineUp 桌面体态宠物")
        .description("实时显示坐姿倾角、颈椎负荷与宠物陪伴，支持一键端正校准。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
