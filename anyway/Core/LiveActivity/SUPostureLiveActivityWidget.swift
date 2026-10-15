//
//  SUPostureLiveActivityWidget.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import SwiftUI
import WidgetKit
import ActivityKit

/// 灵动岛与锁屏实时活动视图展示组件
struct SUPostureLiveActivityView: View {
    let context: ActivityViewContext<SUPostureActivityAttributes>

    var body: some View {
        let state = context.state
        let tint = tintColor(for: state.postureState)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: personaIcon(for: state.personaId))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(tint)

                Text(SULocalized("live_activity_title", default: "SpineUp 实时守护"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("\(state.uprightMinutes) " + SULocalized("unit_minutes", default: "分钟"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(state.postureState == "unknown" ? "--°" : "\(String(format: "%.0f", state.pitchDeg))°")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                if state.extraLoadKg > 0.5 {
                    Text("+ \(String(format: "%.1f", state.extraLoadKg)) kg " + SULocalized("load_unit", default: "负荷"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }

            Text("「\(state.quote)」")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
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
        case "upright": return SULocalized("state_upright", default: "精神挺拔")
        case "slightSlump", "mildSlouch": return SULocalized("state_mild_slouch", default: "轻微前倾")
        case "severeSlump", "severeSlouch": return SULocalized("state_severe_slouch", default: "严重驼背")
        default: return SULocalized("state_monitoring", default: "监测中")
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
