//
//  SUPetAnimatedView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import SwiftUI

/// SwiftUI 动态宠物形象组件 —— 高级质感、流体形变、拟人微表情与深浅色自适应
struct SUPetAnimatedView: View {

    var petState: SUPostureState
    var pitchDeg: Double = 0.0
    var personaName: String = "Spiney"

    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing: Bool = false
    @State private var sweatDropOffset: CGFloat = -8
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                // 1. 背景能量光晕环 (柔和放大)
                if petState == .upright {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(colorScheme == .dark ? 0.3 : 0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 35,
                                endRadius: 130
                            )
                        )
                        .scaleEffect(isBreathing ? 1.08 : 0.92)
                        .frame(width: 250, height: 250)
                }

                // 2. 宠物身体层 (流体质感 + 高光)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(bodyGradient)
                    .frame(width: bodyWidth, height: bodyHeight)
                    .rotationEffect(Angle.degrees(bodyRotationAngle))
                    .scaleEffect(isBreathing ? 1.015 : 0.985)
                    .shadow(
                        color: shadowColor,
                        radius: colorScheme == .dark ? 20 : 16,
                        x: 0,
                        y: 12
                    )
                    // 高光反射层，增加晶莹剔透感
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.6), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.0
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    )
                    .overlay(petFaceView)

                // 3. 额头汗珠 (高级半透明水滴效果)
                if petState == .slightSlump || petState == .severeSlump {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 8, height: 18)
                        .offset(x: 46, y: sweatDropOffset)
                        .opacity(petState == .severeSlump ? 1.0 : 0.6)
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 210)
            .offset(dragOffset)
            .rotation3DEffect(
                .degrees(Double(dragOffset.width / 6)),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(Double(-dragOffset.height / 6)),
                axis: (x: 1, y: 0, z: 0)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2)) {
                            // 添加阻尼感，让拖拽像液态玻璃一样有弹性
                            dragOffset = CGSize(width: value.translation.width * 0.6, height: value.translation.height * 0.6)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.3, blendDuration: 0.5)) {
                            dragOffset = .zero
                        }
                    }
            )

            // 状态标语胶囊 (更扁平精致)
            statusBadge
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                sweatDropOffset = 12
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: petState)
    }

    // MARK: - 身体形状与几何尺寸
    private var cornerRadius: CGFloat {
        switch petState {
        case .upright: return 68
        case .slightSlump: return 56
        case .severeSlump: return 42
        case .calibrating, .unknown: return 68
        }
    }

    private var bodyWidth: CGFloat {
        switch petState {
        case .upright: return 135
        case .slightSlump: return 150
        case .severeSlump: return 185 // 压扁后横向膨胀
        case .calibrating, .unknown: return 135
        }
    }

    private var bodyHeight: CGFloat {
        switch petState {
        case .upright: return 175
        case .slightSlump: return 145
        case .severeSlump: return 95  // 压扁后纵向坍塌
        case .calibrating, .unknown: return 135
        }
    }

    private var bodyRotationAngle: Double {
        switch petState {
        case .upright: return 0.0
        case .slightSlump: return 14.0 // 前倾偏角
        case .severeSlump: return 6.0
        case .calibrating, .unknown: return 0.0
        }
    }

    // MARK: - 颜色渐变 (更柔和高级的色彩搭配)
    private var bodyGradient: LinearGradient {
        switch petState {
        case .upright:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.85, blue: 0.5), Color(red: 0.1, green: 0.7, blue: 0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .slightSlump:
            return LinearGradient(
                colors: [Color.orange.opacity(0.9), Color.yellow.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .severeSlump:
            return LinearGradient(
                colors: [Color.red.opacity(0.85), Color.pink.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .calibrating, .unknown:
            return LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var shadowColor: Color {
        switch petState {
        case .upright: return Color(red: 0.1, green: 0.7, blue: 0.5).opacity(0.25)
        case .slightSlump: return Color.orange.opacity(0.25)
        case .severeSlump: return Color.red.opacity(0.3)
        case .calibrating, .unknown: return Color.black.opacity(0.08)
        }
    }

    // MARK: - 宠物拟人微表情 (大尺寸、去AI味)
    @ViewBuilder
    private var petFaceView: some View {
        VStack(spacing: 22) {
            HStack(spacing: petState == .severeSlump ? 64 : 46) {
                eyeView
                eyeView
            }
            mouthView
        }
        .offset(y: petState == .severeSlump ? -12 : -6)
    }

    @ViewBuilder
    private var eyeView: some View {
        switch petState {
        case .upright:
            // 极简深色椭圆眼
            Capsule()
                .fill(Color.black.opacity(0.8))
                .frame(width: 16, height: 28)
        case .slightSlump:
            // 半闭眼线条
            Capsule()
                .fill(Color.black.opacity(0.7))
                .frame(width: 22, height: 8)
        case .severeSlump:
            // 晕厥线条眼
            Image(systemName: "minus")
                .font(.system(size: 30, weight: .black))
                .foregroundColor(Color.black.opacity(0.8))
                .rotationEffect(.degrees(45))
        case .calibrating, .unknown:
            Circle().fill(Color.black.opacity(0.4)).frame(width: 16, height: 16)
        }
    }

    @ViewBuilder
    private var mouthView: some View {
        switch petState {
        case .upright:
            // 细微微笑曲线
            Image(systemName: "mouth")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.black.opacity(0.7))
                .scaleEffect(x: 1.4, y: 0.8)
        case .slightSlump:
            // 扁平嘴
            Capsule()
                .fill(Color.black.opacity(0.6))
                .frame(width: 16, height: 6)
        case .severeSlump:
            // 叹气小圆孔
            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 20, height: 28)
        case .calibrating, .unknown:
            Circle().fill(Color.black.opacity(0.3)).frame(width: 8, height: 8)
        }
    }

    // MARK: - 状态标语胶囊 (更扁平精致)
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(badgeDotColor)
                .frame(width: 6, height: 6)
            Text(badgeText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(badgeTextColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : .white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 4)
        )
    }

    private var badgeDotColor: Color {
        petState.swiftUIColor
    }

    private var badgeText: String {
        let angleStr = String(format: "%.1f°", max(0.0, pitchDeg))
        switch petState {
        case .upright:
            let fmt = SULocalized("pet_status_upright_fmt", default: "精神挺拔 · 低头 %@")
            return String(format: fmt, angleStr)
        case .slightSlump:
            let fmt = SULocalized("pet_status_slight_fmt", default: "轻微前倾 · 低头 %@")
            return String(format: fmt, angleStr)
        case .severeSlump:
            let fmt = SULocalized("pet_status_severe_fmt", default: "严重驼背 · 低头 %@")
            return String(format: fmt, angleStr)
        case .calibrating:
            return SULocalized("pet_status_calibrating", default: "校准基准端坐中...")
        case .unknown:
            return SULocalized("pet_status_unknown", default: "等待耳机佩戴...")
        }
    }

    private var badgeTextColor: Color {
        switch petState {
        case .upright: return Color.primary
        case .slightSlump: return Color.primary
        case .severeSlump: return Color.primary
        case .calibrating, .unknown: return Color.secondary
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
