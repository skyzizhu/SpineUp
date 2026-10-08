//
//  SUPetAnimatedView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import SwiftUI

/// SwiftUI 动态宠物形象组件 —— 支持三态平滑形变、拟人微表情与深浅色模式自适应
struct SUPetAnimatedView: View {

    var petState: SUPostureState
    var personaName: String = "Spiney"

    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing: Bool = false
    @State private var sweatDropOffset: CGFloat = -10

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // 1. 背景能量光晕环 (挺拔状态下微动闪烁)
                if petState == .upright {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.green.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .scaleEffect(isBreathing ? 1.15 : 0.95)
                        .frame(width: 200, height: 200)
                }

                // 2. 宠物身体层 (根据状态发生形变: 挺拔 -> 倾斜 -> 压扁)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(bodyGradient)
                    .frame(width: bodyWidth, height: bodyHeight)
                    .rotationEffect(Angle.degrees(bodyRotationAngle))
                    .scaleEffect(isBreathing ? 1.02 : 0.98)
                    .shadow(
                        color: shadowColor,
                        radius: colorScheme == .dark ? 12 : 8,
                        x: 0,
                        y: 6
                    )
                    .overlay(
                        petFaceView
                    )

                // 3. 额头汗珠 (前倾与重度时冒汗)
                if petState == .slightSlump || petState == .severeSlump {
                    Circle()
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 8, height: 12)
                        .offset(x: 35, y: sweatDropOffset)
                        .opacity(petState == .severeSlump ? 1.0 : 0.7)
                }
            }
            .frame(height: 180)

            // 状态标语胶囊
            statusBadge
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                sweatDropOffset = 10
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: petState)
    }

    // MARK: - 身体形状与几何尺寸
    private var cornerRadius: CGFloat {
        switch petState {
        case .upright: return 48
        case .slightSlump: return 40
        case .severeSlump: return 32
        case .calibrating, .unknown: return 55
        }
    }

    private var bodyWidth: CGFloat {
        switch petState {
        case .upright: return 110
        case .slightSlump: return 125
        case .severeSlump: return 155 // 压扁后横向膨胀
        case .calibrating, .unknown: return 110
        }
    }

    private var bodyHeight: CGFloat {
        switch petState {
        case .upright: return 145
        case .slightSlump: return 120
        case .severeSlump: return 75  // 压扁后纵向坍塌
        case .calibrating, .unknown: return 110
        }
    }

    private var bodyRotationAngle: Double {
        switch petState {
        case .upright: return 0.0
        case .slightSlump: return 12.0 // 前倾偏角
        case .severeSlump: return 5.0
        case .calibrating, .unknown: return 0.0
        }
    }

    // MARK: - 颜色渐变
    private var bodyGradient: LinearGradient {
        switch petState {
        case .upright:
            return LinearGradient(
                colors: [Color.green.opacity(0.9), Color.mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .slightSlump:
            return LinearGradient(
                colors: [Color.orange, Color.yellow.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .severeSlump:
            return LinearGradient(
                colors: [Color.red, Color.pink.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .calibrating, .unknown:
            return LinearGradient(
                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var shadowColor: Color {
        switch petState {
        case .upright: return Color.green.opacity(0.3)
        case .slightSlump: return Color.orange.opacity(0.3)
        case .severeSlump: return Color.red.opacity(0.4)
        case .calibrating, .unknown: return Color.black.opacity(0.1)
        }
    }

    // MARK: - 宠物拟人微表情
    @ViewBuilder
    private var petFaceView: some View {
        VStack(spacing: 8) {
            HStack(spacing: petState == .severeSlump ? 36 : 24) {
                eyeView
                eyeView
            }
            mouthView
        }
        .offset(y: petState == .severeSlump ? -4 : 0)
    }

    @ViewBuilder
    private var eyeView: some View {
        switch petState {
        case .upright:
            // 亮闪闪大眼 (◕‿◕)
            ZStack {
                Circle().fill(Color.white).frame(width: 14, height: 14)
                Circle().fill(Color.black).frame(width: 8, height: 8)
                Circle().fill(Color.white).frame(width: 4, height: 4).offset(x: 2, y: -2)
            }
        case .slightSlump:
            // 困倦半闭眼 (•_•)
            Capsule()
                .fill(Color.white)
                .frame(width: 12, height: 6)
        case .severeSlump:
            // 痛苦眩晕叉叉眼 (X_X)
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
        case .calibrating, .unknown:
            Circle().fill(Color.white.opacity(0.8)).frame(width: 8, height: 8)
        }
    }

    @ViewBuilder
    private var mouthView: some View {
        switch petState {
        case .upright:
            // 开心小嘴
            Capsule()
                .fill(Color.white)
                .frame(width: 14, height: 6)
        case .slightSlump:
            // 平直无语小嘴
            Rectangle()
                .fill(Color.white)
                .frame(width: 12, height: 3)
                .cornerRadius(1.5)
        case .severeSlump:
            // 张嘴惊恐求救波浪
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 12)
        case .calibrating, .unknown:
            Circle().fill(Color.white.opacity(0.8)).frame(width: 6, height: 6)
        }
    }

    // MARK: - 状态标语胶囊
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(badgeDotColor)
                .frame(width: 8, height: 8)
            Text(badgeText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(badgeTextColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 6, x: 0, y: 3)
        )
    }

    private var badgeDotColor: Color {
        switch petState {
        case .upright: return .green
        case .slightSlump: return .orange
        case .severeSlump: return .red
        case .calibrating, .unknown: return .gray
        }
    }

    private var badgeText: String {
        switch petState {
        case .upright: return "精神挺拔 · 脊椎零负担"
        case .slightSlump: return "轻微前倾 · 正在消耗耐力"
        case .severeSlump: return "严重驼背！宠物被压扁了"
        case .calibrating: return "校准基准端坐中..."
        case .unknown: return "等待耳机佩戴..."
        }
    }

    private var badgeTextColor: Color {
        switch petState {
        case .upright: return .green
        case .slightSlump: return .orange
        case .severeSlump: return .red
        case .calibrating, .unknown: return .secondary
        }
    }
}

#Preview("Light Mode - Upright") {
    SUPetAnimatedView(petState: .upright)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode - Severe Slump") {
    SUPetAnimatedView(petState: .severeSlump)
        .preferredColorScheme(.dark)
}
