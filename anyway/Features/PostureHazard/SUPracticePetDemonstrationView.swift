//
//  SUPracticePetDemonstrationView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import SwiftUI
import UIKit
import SnapKit

/// 拟人桌宠动作带练示范核心组件 —— 专为 30 秒微操打造的生动拟人动作动效与流体质感
struct SUPracticePetDemonstrationView: View {

    var action: SUPracticeActionType
    var persona: SUPetPersona
    var breathPhase: SUPracticeBreathPhase = .inhale
    var isMatchingPose: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathingCycle: Bool = false
    @State private var chinTuckPhase: CGFloat = 0.0
    @State private var wStretchAngle: Double = 0.0
    @State private var auraScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 1. 背景能量光波 / 减负涟漪环
            backgroundEnergyAura

            // 2. 拟人桌宠身体主体 (视觉重心补偿，确保全人设绝对居中)
            petMainBody
                .offset(y: petVerticalCorrectionOffset)

            // 3. 当姿态达标时的科技感高光与星星反馈
            if isMatchingPose {
                matchingPoseEffect
                    .offset(y: petVerticalCorrectionOffset)
            }
        }
        .frame(width: 260, height: 250)
        .onAppear {
            syncWithBreathPhase(breathPhase)
        }
        .onChange(of: action) {
            syncWithBreathPhase(breathPhase)
        }
        .onChange(of: breathPhase) {
            syncWithBreathPhase(breathPhase)
        }
    }

    // MARK: - 背景能量光波
    private var backgroundEnergyAura: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            auraColor.opacity(colorScheme == .dark ? 0.35 : 0.22),
                            auraColor.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 135
                    )
                )
                .scaleEffect(auraScale)
                .frame(width: 260, height: 260)

            // 夹背/拉伸能量涟漪环 (外层呼吸光圈，适度放大不再紧贴宠物)
            Circle()
                .stroke(auraColor.opacity(isBreathingCycle ? 0.45 : 0.12), lineWidth: 2.5)
                .scaleEffect(isBreathingCycle ? 1.08 : 0.94)
                .frame(width: 232, height: 232)
        }
    }

    private var auraColor: Color {
        if isMatchingPose {
            return Color.green
        }
        switch action {
        case .chinTuck: return Color.orange
        case .wStretch: return Color.blue
        }
    }

    // MARK: - 拟人桌宠主体
    private var petMainBody: some View {
        ZStack {
            // 宠物背部 / 躯干
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(bodyGradient)
                .frame(width: bodyWidth, height: bodyHeight)
                .rotationEffect(.degrees(bodyRotationAngle))
                .scaleEffect(isBreathingCycle ? 1.02 : 0.98)
                .shadow(
                    color: auraColor.opacity(0.28),
                    radius: colorScheme == .dark ? 18 : 14,
                    x: 0,
                    y: 10
                )
                // 高光与晶莹液态玻璃边缘
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.65), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.0
                        )
                )

            // 耳朵 / 人设饰品
            personaAccessories

            // 双臂/前爪（关键动作骨骼）
            armsAndPawsView

            // 脸部五官与微表情
            petFaceView
        }
    }

    // MARK: - 人格专属配饰
    @ViewBuilder
    private var personaAccessories: some View {
        switch persona {
        case .cat:
            // 猫猫小耳朵
            HStack(spacing: bodyWidth - 52) {
                catEar(isLeft: true)
                catEar(isLeft: false)
            }
            .offset(y: -bodyHeight / 2 - 8)
        case .worker:
            // 打工人领带
            Capsule()
                .fill(Color.orange.opacity(0.95))
                .frame(width: 8, height: 26)
                .offset(y: 42)
        case .coach:
            // 保持头部自然圆润清爽，不再添加突兀的白色横线发带
            EmptyView()
        }
    }

    private func catEar(isLeft: Bool) -> some View {
        Triangle()
            .fill(
                LinearGradient(
                    colors: [Color.purple.opacity(0.9), Color.pink.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 24, height: 22)
            .rotationEffect(.degrees(isLeft ? -15 : 15))
    }

    // MARK: - 手臂/前爪（动作核心表现）
    @ViewBuilder
    private var armsAndPawsView: some View {
        if action == .chinTuck {
            // 收下巴：小肉垫/手指在下巴前微推
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 22, height: 22)
                    .shadow(color: Color.black.opacity(0.12), radius: 3)
                Circle()
                    .fill(persona == .cat ? Color.pink.opacity(0.85) : Color.orange.opacity(0.85))
                    .frame(width: 12, height: 12)
            }
            .offset(x: -chinTuckPhase * 10 + 16, y: 18)
        } else {
            // W 展肩夹背：双臂弯曲向上展开呈标准「W」字形！
            HStack(spacing: bodyWidth + 8) {
                armSegment(isLeft: true)
                armSegment(isLeft: false)
            }
            .offset(y: -10)
        }
    }

    private func armSegment(isLeft: Bool) -> some View {
        ZStack {
            // 弯曲大臂与小臂呈 W 形状
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), bodyBaseColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 14, height: 48)
                .rotationEffect(.degrees(isLeft ? (-45 + wStretchAngle) : (45 - wStretchAngle)))
                .shadow(color: Color.black.opacity(0.12), radius: 4)

            // 小肉垫爪心
            Circle()
                .fill(persona == .cat ? Color.pink.opacity(0.8) : Color.blue.opacity(0.8))
                .frame(width: 11, height: 11)
                .offset(y: isLeft ? -22 : -22)
        }
    }

    // MARK: - 脸部表情
    @ViewBuilder
    private var petFaceView: some View {
        VStack(spacing: 14) {
            // 眼睛
            HStack(spacing: 36) {
                eyeShape
                eyeShape
            }

            // 嘴巴 & 收下巴时的萌萌双下巴弧线
            VStack(spacing: 3) {
                mouthShape

                if action == .chinTuck && chinTuckPhase > 0.4 {
                    // 挤出双下巴的微弧线！
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 22, height: 3.5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        // 当做收下巴动作时，头部与五官水平向后推移
        .offset(x: action == .chinTuck ? (-chinTuckPhase * 16) : 0, y: -4)
    }

    @ViewBuilder
    private var eyeShape: some View {
        if isMatchingPose {
            // 达标时弯弯的开心笑眼
            Image(systemName: "face.smiling.inverse")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.black.opacity(0.8))
        } else {
            Capsule()
                .fill(Color.black.opacity(0.82))
                .frame(width: 13, height: 22)
                .scaleEffect(isBreathingCycle ? 1.05 : 0.95)
        }
    }

    @ViewBuilder
    private var mouthShape: some View {
        if action == .chinTuck {
            // 嘟起嘴巴用力缩下巴的感觉
            Circle()
                .fill(Color.black.opacity(0.75))
                .frame(width: 8, height: 8)
        } else {
            // 展肩时舒畅深呼吸的微凹笑容
            Capsule()
                .fill(Color.black.opacity(0.75))
                .frame(width: 16, height: 5)
        }
    }

    // MARK: - 姿态达标时的特效
    private var matchingPoseEffect: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius + 6, style: .continuous)
                .stroke(Color.green.opacity(0.8), lineWidth: 3)
                .frame(width: bodyWidth + 12, height: bodyHeight + 12)
                .scaleEffect(isBreathingCycle ? 1.05 : 0.98)

            // 四周漂浮小星星
            HStack {
                Text("✨").font(.system(size: 18))
                    .offset(x: -30, y: -70)
                Spacer()
                Text("🌟").font(.system(size: 18))
                    .offset(x: 30, y: -65)
            }
            .frame(width: bodyWidth + 80)
        }
    }

    // MARK: - 身体几何与色彩
    private var petVerticalCorrectionOffset: CGFloat {
        switch persona {
        case .cat:
            return 8.0 // 补偿猫猫耳朵向上延展的高度，使整体视觉重心精准落于绝对几何中心
        case .worker, .coach:
            return 0.0
        }
    }

    private var cornerRadius: CGFloat {
        return action == .chinTuck ? 54 : 60
    }

    private var bodyWidth: CGFloat {
        switch action {
        case .chinTuck: return 128
        case .wStretch: return 142 // 夹背时胸膛舒展略宽
        }
    }

    private var bodyHeight: CGFloat {
        switch action {
        case .chinTuck: return 165 // 收下巴时挺直拔高
        case .wStretch: return 155
        }
    }

    private var bodyRotationAngle: Double {
        return action == .chinTuck ? -2.0 : 0.0
    }

    private var bodyBaseColor: Color {
        switch persona {
        case .cat:    return Color(red: 0.68, green: 0.38, blue: 0.88)
        case .worker: return Color(red: 1.0, green: 0.58, blue: 0.15)
        case .coach:  return Color(red: 0.2, green: 0.78, blue: 0.45)
        }
    }

    private var bodyGradient: LinearGradient {
        switch persona {
        case .cat:
            return LinearGradient(
                colors: [Color(red: 0.75, green: 0.48, blue: 0.95), Color(red: 0.55, green: 0.28, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .worker:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.65, blue: 0.22), Color(red: 0.92, green: 0.45, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .coach:
            return LinearGradient(
                colors: [Color(red: 0.25, green: 0.86, blue: 0.52), Color(red: 0.12, green: 0.68, blue: 0.38)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - 与呼吸阶段精准同步动作
    private func syncWithBreathPhase(_ phase: SUPracticeBreathPhase) {
        switch phase {
        case .inhale:
            let duration = (action == .chinTuck ? 2.0 : 3.0)
            withAnimation(.easeInOut(duration: duration)) {
                isBreathingCycle = true
                auraScale = 1.24
                if action == .chinTuck {
                    chinTuckPhase = 1.0
                } else {
                    wStretchAngle = 22.0
                }
            }
        case .hold:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                auraScale = 1.28
            }
        case .exhale:
            let duration = (action == .chinTuck ? 1.0 : 1.5)
            withAnimation(.easeInOut(duration: duration)) {
                isBreathingCycle = false
                auraScale = 1.0
                if action == .chinTuck {
                    chinTuckPhase = 0.0
                } else {
                    wStretchAngle = 0.0
                }
            }
        }
    }
}

// MARK: - 辅助三角形图形（用于猫耳）
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - UIKit 容器封装组件（方便直接嵌入 UIViewController）
final class SUPracticePetContainerView: UIView {

    private var hostingController: UIHostingController<SUPracticePetDemonstrationView>?
    private var currentAction: SUPracticeActionType = .chinTuck
    private var currentPersona: SUPetPersona = .coach
    private var currentBreathPhase: SUPracticeBreathPhase = .inhale
    private var isMatchingPose: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContainer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupContainer()
    }

    private func setupContainer() {
        backgroundColor = .clear

        let swiftUIView = SUPracticePetDemonstrationView(
            action: currentAction,
            persona: currentPersona,
            breathPhase: currentBreathPhase,
            isMatchingPose: isMatchingPose
        )
        let hc = UIHostingController(rootView: swiftUIView)
        hc.view.backgroundColor = .clear

        addSubview(hc.view)
        hc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.hostingController = hc
    }

    func attach(to parent: UIViewController) {
        guard let hc = hostingController else { return }
        parent.addChild(hc)
        hc.didMove(toParent: parent)
    }

    func configure(
        action: SUPracticeActionType,
        persona: SUPetPersona,
        breathPhase: SUPracticeBreathPhase = .inhale,
        isMatchingPose: Bool = false
    ) {
        self.currentAction = action
        self.currentPersona = persona
        self.currentBreathPhase = breathPhase
        self.isMatchingPose = isMatchingPose

        hostingController?.rootView = SUPracticePetDemonstrationView(
            action: action,
            persona: persona,
            breathPhase: breathPhase,
            isMatchingPose: isMatchingPose
        )
    }
}
