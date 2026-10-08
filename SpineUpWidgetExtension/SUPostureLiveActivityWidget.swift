//
//  SUPostureLiveActivityWidget.swift
//  SpineUpWidgetExtension
//
//  Created by Antigravity on 2026/10/8.
//

import SwiftUI
import WidgetKit
import ActivityKit

/// 灵动岛 (Dynamic Island) 与锁屏实时活动 Widget (iOS 26+)
struct SUPostureLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SUPostureActivityAttributes.self) { context in
            // 锁屏实时常驻面板
            SUPostureLiveActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            // 灵动岛多态配置
            DynamicIsland {
                // 展开态 (长按或大岛展开)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: personaIcon(for: context.state.personaId))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(tintColor(for: context.state.postureState))
                        Text(stateTitle(for: context.state.postureState))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(tintColor(for: context.state.postureState))
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 2) {
                        Text("\(String(format: "%.0f", context.state.pitchDeg))°")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(tintColor(for: context.state.postureState))
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("挺拔专注 \(context.state.uprightMinutes) 分钟")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            if context.state.extraLoadKg > 0.5 {
                                Text("+ \(String(format: "%.1f", context.state.extraLoadKg)) kg 负荷")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                        }
                        Text("「\(context.state.quote)」")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                // 紧凑左侧：小桌宠微图标
                Image(systemName: personaIcon(for: context.state.personaId))
                    .foregroundColor(tintColor(for: context.state.postureState))
            } compactTrailing: {
                // 紧凑右侧：倾斜度与状态色
                Text("\(String(format: "%.0f", context.state.pitchDeg))°")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(tintColor(for: context.state.postureState))
            } minimal: {
                // 极简单点态：小桌宠图标
                Image(systemName: personaIcon(for: context.state.personaId))
                    .foregroundColor(tintColor(for: context.state.postureState))
            }
        }
    }

    private func personaIcon(for id: String) -> String {
        switch id {
        case "cat": return "cat.fill"
        case "coach": return "figure.mind.and.body"
        default: return "briefcase.fill"
        }
    }

    private func tintColor(for state: String) -> Color {
        switch state {
        case "upright": return .green
        case "slightSlump": return .orange
        case "severeSlump": return .red
        default: return .blue
        }
    }

    private func stateTitle(for state: String) -> String {
        switch state {
        case "upright": return "挺拔"
        case "slightSlump": return "前倾"
        case "severeSlump": return "驼背"
        default: return "监测中"
        }
    }
}

/// 锁屏实时常驻面板视图
struct SUPostureLiveActivityLockScreenView: View {
    let context: ActivityViewContext<SUPostureActivityAttributes>

    var body: some View {
        let state = context.state
        let tint = tintColor(for: state.postureState)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: personaIcon(for: state.personaId))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(tint)

                Text("SpineUp 实时守护")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("\(state.uprightMinutes) 分钟")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                HStack(spacing: 4) {
                    Text(stateTitle(for: state.postureState))
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tint.opacity(0.18))
                        .foregroundColor(tint)
                        .clipShape(Capsule())

                    Text("\(String(format: "%.0f", state.pitchDeg))°")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                if state.extraLoadKg > 0.5 {
                    Text("+ \(String(format: "%.1f", state.extraLoadKg)) kg 负荷")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }
            }

            Text("「\(state.quote)」")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(14)
    }

    private func tintColor(for state: String) -> Color {
        switch state {
        case "upright": return .green
        case "slightSlump": return .orange
        case "severeSlump": return .red
        default: return .blue
        }
    }

    private func stateTitle(for state: String) -> String {
        switch state {
        case "upright": return "挺拔端正"
        case "slightSlump": return "轻微前倾"
        case "severeSlump": return "严重驼背"
        default: return "监测中"
        }
    }

    private func personaIcon(for id: String) -> String {
        switch id {
        case "cat": return "cat.fill"
        case "coach": return "figure.mind.and.body"
        default: return "briefcase.fill"
        }
    }
}
