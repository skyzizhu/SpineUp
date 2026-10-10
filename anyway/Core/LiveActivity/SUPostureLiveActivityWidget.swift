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
        case "upright": return "精神挺拔"
        case "slightSlump", "mildSlouch": return "轻微前倾"
        case "severeSlump", "severeSlouch": return "严重驼背"
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
