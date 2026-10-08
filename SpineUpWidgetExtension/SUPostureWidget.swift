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
            petName: SUWidgetLocalization.petName(for: "worker"),
            petIcon: "figure.walk.motion",
            quote: SUWidgetLocalization.quote(for: "upright")
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
        switch persona {
        case "zen":
            petIcon = "sparkles"
        case "rebel":
            petIcon = "bolt.fill"
        case "medic":
            petIcon = "cross.case.fill"
        case "cat":
            petIcon = "cat.fill"
        case "coach":
            petIcon = "figure.mind.and.body"
        default:
            petIcon = "briefcase.fill"
        }

        let petName = SUWidgetLocalization.petName(for: persona)
        let quote = SUWidgetLocalization.quote(for: state)

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

// MARK: - Dynamic Theme Colors (Light & Dark Mode)

enum SUWidgetTheme {
    static func tintColor(for state: String) -> Color {
        switch state {
        case "severeSlouch", "severeSlump":
            return Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
                    : UIColor(red: 0.88, green: 0.22, blue: 0.22, alpha: 1.0)
            })
        case "mildSlouch", "slightSlump":
            return Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 0.65, blue: 0.20, alpha: 1.0)
                    : UIColor(red: 0.92, green: 0.52, blue: 0.12, alpha: 1.0)
            })
        default:
            return Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.25, green: 0.82, blue: 0.52, alpha: 1.0)
                    : UIColor(red: 0.15, green: 0.65, blue: 0.42, alpha: 1.0)
            })
        }
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
        SUWidgetTheme.tintColor(for: entry.postureState)
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
                    .lineLimit(1)
                Text(SUWidgetLocalization.localizedFormat("label_focus_minutes", default: "专注 %d 分钟", entry.uprightMinutes))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(intent: SUCalibrationIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "scope")
                        .font(.system(size: 10, weight: .bold))
                    Text(SUWidgetLocalization.localizedString("btn_calibrate", default: "校准"))
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
        SUWidgetTheme.tintColor(for: entry.postureState)
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
                        Text(SUWidgetLocalization.localizedString("label_pet_companion", default: "SpineUp 桌面宠物"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(entry.petName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }

                Text("「\(entry.quote)」")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer()

                HStack(spacing: 8) {
                    Label(
                        SUWidgetLocalization.localizedFormat("label_focus_minutes", default: "%d 分钟", entry.uprightMinutes),
                        systemImage: "clock.fill"
                    )
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                    if entry.extraLoadKg > 0.5 {
                        Label(
                            SUWidgetLocalization.localizedFormat("label_extra_load", default: "+%.1f kg 负荷", entry.extraLoadKg),
                            systemImage: "scalemass.fill"
                        )
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
                    Text(SUWidgetLocalization.localizedString("label_current_angle", default: "当前倾角"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(intent: SUCalibrationIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "scope")
                            .font(.system(size: 12, weight: .bold))
                        Text(SUWidgetLocalization.localizedString("btn_one_tap_calibrate", default: "一键校准"))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(themeColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 92)
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
        .configurationDisplayName(LocalizedStringResource("widget_display_name", defaultValue: "SpineUp 桌面体态宠物"))
        .description(LocalizedStringResource("widget_description", defaultValue: "实时显示坐姿倾角、颈椎负荷与宠物陪伴，支持一键端正校准。"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
