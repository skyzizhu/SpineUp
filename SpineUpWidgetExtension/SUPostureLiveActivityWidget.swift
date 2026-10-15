//
//  SUPostureLiveActivityWidget.swift
//  SpineUpWidgetExtension
//
//  Created by Antigravity on 2026/10/8.
//

import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

/// 灵动岛 (Dynamic Island) 与锁屏实时活动 Widget (支持 7 语言与深色模式自适应)
struct SUPostureLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SUPostureActivityAttributes.self) { context in
            // 锁屏实时常驻面板
            SUPostureLiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.4))
                .activitySystemActionForegroundColor(Color.primary)
        } dynamicIsland: { context in
            // 灵动岛多态配置
            DynamicIsland {
                // 展开态 (长按或大岛展开)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        if isSevereSlouch(context.state.postureState) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                                .symbolEffect(.bounce, options: .repeating)
                        } else {
                            Image(systemName: personaIcon(for: context.state.personaId))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(tintColor(for: context.state.postureState))
                        }
                        Text(SUWidgetLocalization.stateTitle(for: context.state.postureState))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(tintColor(for: context.state.postureState))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 2) {
                        Text(context.state.postureState == "unknown" ? "--°" : "\(String(format: "%.0f", context.state.pitchDeg))°")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(tintColor(for: context.state.postureState))
                            .lineLimit(1)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(SUWidgetLocalization.localizedFormat("label_upright_minutes", default: "挺拔专注 %d 分钟", context.state.uprightMinutes))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Spacer()
                            if context.state.extraLoadKg > 0.5 {
                                Text(SUWidgetLocalization.localizedFormat("label_extra_load", default: "+ %.1f kg 负荷", context.state.extraLoadKg))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                        }
                        HStack(alignment: .center, spacing: 8) {
                            Text("「\(context.state.quote)」")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                            Spacer(minLength: 4)
                            Button(intent: SUCalibrationIntent()) {
                                HStack(spacing: 3) {
                                    Image(systemName: "scope")
                                        .font(.system(size: 9, weight: .bold))
                                    Text(SUWidgetLocalization.localizedString("btn_calibrate", default: "校准"))
                                        .font(.system(size: 10, weight: .semibold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(tintColor(for: context.state.postureState))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                // 紧凑左侧：小桌宠微图标 (严重驼背时变为闪烁警示图标)
                if isSevereSlouch(context.state.postureState) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .symbolEffect(.pulse.byLayer)
                } else {
                    Image(systemName: personaIcon(for: context.state.personaId))
                        .foregroundColor(tintColor(for: context.state.postureState))
                }
            } compactTrailing: {
                // 紧凑右侧：倾斜度与状态色
                Text(context.state.postureState == "unknown" ? "--°" : "\(String(format: "%.0f", context.state.pitchDeg))°")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(tintColor(for: context.state.postureState))
                    .lineLimit(1)
            } minimal: {
                // 极简单点态：严重驼背时展示脉冲感叹号
                if isSevereSlouch(context.state.postureState) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .symbolEffect(.pulse.byLayer)
                } else {
                    Image(systemName: personaIcon(for: context.state.personaId))
                        .foregroundColor(tintColor(for: context.state.postureState))
                }
            }
        }
    }

    private func isSevereSlouch(_ state: String) -> Bool {
        return state == "severeSlump" || state == "severeSlouch"
    }

    private func personaIcon(for id: String) -> String {
        switch id {
        case "cat": return "cat.fill"
        case "coach": return "figure.mind.and.body"
        case "zen": return "sparkles"
        case "rebel": return "bolt.fill"
        case "medic": return "cross.case.fill"
        default: return "briefcase.fill"
        }
    }

    private func tintColor(for state: String) -> Color {
        SUWidgetTheme.tintColor(for: state)
    }
}

/// 锁屏实时常驻面板视图 (深色模式与 Liquid Glass 原生半透)
struct SUPostureLiveActivityLockScreenView: View {
    let context: ActivityViewContext<SUPostureActivityAttributes>

    var body: some View {
        let state = context.state
        let tint = SUWidgetTheme.tintColor(for: state.postureState)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: personaIcon(for: state.personaId))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(tint)

                Text(SUWidgetLocalization.localizedString("live_activity_title", default: "SpineUp 实时守护"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(SUWidgetLocalization.localizedFormat("label_focus_minutes", default: "%d 分钟", state.uprightMinutes))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }

            HStack {
                HStack(spacing: 4) {
                    Text(SUWidgetLocalization.stateTitle(for: state.postureState))
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tint.opacity(0.18))
                        .foregroundColor(tint)
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(state.postureState == "unknown" ? "--°" : "\(String(format: "%.0f", state.pitchDeg))°")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                if state.extraLoadKg > 0.5 {
                    Text(SUWidgetLocalization.localizedFormat("label_extra_load", default: "+ %.1f kg 负荷", state.extraLoadKg))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Button(intent: SUCalibrationIntent()) {
                    HStack(spacing: 3) {
                        Image(systemName: "scope")
                            .font(.system(size: 10, weight: .bold))
                        Text(SUWidgetLocalization.localizedString("btn_calibrate", default: "校准"))
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Text("「\(state.quote)」")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .opacity(0.92)
        }
    }

    private func personaIcon(for id: String) -> String {
        switch id {
        case "cat": return "cat.fill"
        case "coach": return "figure.mind.and.body"
        case "zen": return "sparkles"
        case "rebel": return "bolt.fill"
        case "medic": return "cross.case.fill"
        default: return "briefcase.fill"
        }
    }
}
