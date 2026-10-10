//
//  SUBreathingPacerView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 呼吸阶段枚举
enum SUPracticeBreathPhase: String, Sendable {
    case inhale   // 吸气阶段
    case hold     // 屏息/保持发力阶段
    case exhale   // 呼气/放松还原阶段

    var title: String {
        switch self {
        case .inhale:
            return SULocalized("practice_breath_inhale", default: "深吸气 · 挺胸展肩")
        case .hold:
            return SULocalized("practice_breath_hold", default: "屏息保持 · 持续发力")
        case .exhale:
            return SULocalized("practice_breath_exhale", default: "缓慢呼气 · 放松还原")
        }
    }

    var themeColor: UIColor {
        switch self {
        case .inhale:
            return .systemGreen
        case .hold:
            return .systemOrange
        case .exhale:
            return .systemTeal
        }
    }

    var iconSystemName: String {
        switch self {
        case .inhale:
            return "arrow.up.and.down.and.sparkles"
        case .hold:
            return "pause.circle.fill"
        case .exhale:
            return "wind"
        }
    }
}

/// 科学呼吸引导与倒计时一体化节律控制条 —— 结合圆形倒计时进度、动态呼吸波纹、阶段文案与微触觉节拍
final class SUBreathingPacerView: UIView {

    // MARK: - UI 组件容器
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.65)
        view.layer.cornerRadius = 18
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        return view
    }()

    // MARK: - 左侧倒计时环
    private let countdownRingContainerView = UIView()
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let remainingSecondsLabel: UILabel = {
        let label = UILabel()
        if let desc = UIFont.systemFont(ofSize: 18, weight: .heavy).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: desc, size: 0)
        } else {
            label.font = .systemFont(ofSize: 18, weight: .heavy)
        }
        label.textColor = .label
        label.textAlignment = .center
        label.text = "30"
        return label
    }()

    private let remainingUnitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 9, weight: .bold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = SULocalized("practice_seconds_left", default: "秒剩余")
        return label
    }()

    private let verticalDividerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.separator.withAlphaComponent(0.2)
        return view
    }()

    // MARK: - 右侧呼吸节律
    private let breathOrbView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        view.layer.cornerRadius = 15
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let breathIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        iv.image = UIImage(systemName: "lungs.fill", withConfiguration: config)
        iv.tintColor = .systemGreen
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let breathPhaseLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .label
        label.text = SULocalized("practice_breath_inhale", default: "深吸气 · 挺胸展肩")
        return label
    }()

    private let breathProgressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.trackTintColor = UIColor.separator.withAlphaComponent(0.12)
        pv.progressTintColor = .systemGreen
        pv.layer.cornerRadius = 2
        pv.layer.masksToBounds = true
        return pv
    }()

    private let breathCountdownLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 11.5, weight: .bold)
        label.textColor = .secondaryLabel
        label.text = "3.0s"
        return label
    }()

    // MARK: - 内部计时状态
    private(set) var currentPhase: SUPracticeBreathPhase = .inhale
    private var cycleTotalSeconds: Double = 5.0
    private var cycleElapsedSeconds: Double = 0.0

    private var inhaleDuration: Double = 2.0
    private var holdDuration: Double = 2.0
    private var exhaleDuration: Double = 1.0

    private var hapticGenerator = UIImpactFeedbackGenerator(style: .soft)

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(containerView)
        containerView.addSubview(countdownRingContainerView)
        countdownRingContainerView.addSubview(remainingSecondsLabel)
        countdownRingContainerView.addSubview(remainingUnitLabel)

        containerView.addSubview(verticalDividerView)

        containerView.addSubview(breathOrbView)
        breathOrbView.addSubview(breathIconImageView)
        containerView.addSubview(breathPhaseLabel)
        containerView.addSubview(breathProgressView)
        containerView.addSubview(breathCountdownLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 左侧倒计时环
        countdownRingContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }

        remainingSecondsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-4)
        }

        remainingUnitLabel.snp.makeConstraints { make in
            make.top.equalTo(remainingSecondsLabel.snp.bottom).offset(-1)
            make.centerX.equalToSuperview()
        }

        // 分割线
        verticalDividerView.snp.makeConstraints { make in
            make.leading.equalTo(countdownRingContainerView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(0.5)
            make.height.equalTo(34)
        }

        // 右侧呼吸指示
        breathOrbView.snp.makeConstraints { make in
            make.leading.equalTo(verticalDividerView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }

        breathIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(15)
        }

        breathPhaseLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(13)
            make.leading.equalTo(breathOrbView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(breathCountdownLabel.snp.leading).offset(-4)
        }

        breathCountdownLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(breathPhaseLabel.snp.centerY)
        }

        breathProgressView.snp.makeConstraints { make in
            make.top.equalTo(breathPhaseLabel.snp.bottom).offset(7)
            make.leading.equalTo(breathOrbView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(4)
        }

        hapticGenerator.prepare()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupCountdownLayers()
    }

    // MARK: - 倒计时环形图层
    private func setupCountdownLayers() {
        let bounds = countdownRingContainerView.bounds
        guard bounds.width > 0 else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = max(10, (min(bounds.width, bounds.height) - 7) / 2)
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: CGFloat.pi * 1.5,
            clockwise: true
        )

        if trackLayer.superlayer == nil {
            trackLayer.strokeColor = UIColor.separator.withAlphaComponent(0.18).cgColor
            trackLayer.fillColor = UIColor.clear.cgColor
            trackLayer.lineWidth = 3.5
            trackLayer.lineCap = .round
            countdownRingContainerView.layer.addSublayer(trackLayer)
        }
        trackLayer.frame = bounds
        trackLayer.path = path.cgPath

        if progressLayer.superlayer == nil {
            progressLayer.strokeColor = UIColor.systemOrange.cgColor
            progressLayer.fillColor = UIColor.clear.cgColor
            progressLayer.lineWidth = 3.5
            progressLayer.lineCap = .round
            progressLayer.strokeEnd = 1.0
            countdownRingContainerView.layer.addSublayer(progressLayer)
        }
        progressLayer.frame = bounds
        progressLayer.path = path.cgPath
    }

    /// 更新左侧大倒计时
    func updateCountdown(seconds: Int, progress: CGFloat, themeColor: UIColor) {
        remainingSecondsLabel.text = "\(seconds)"
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        progressLayer.strokeEnd = progress
        progressLayer.strokeColor = themeColor.cgColor
        CATransaction.commit()
    }

    // MARK: - 呼吸节奏配置与步进
    func configureCadence(for action: SUPracticeActionType) {
        switch action {
        case .chinTuck:
            self.inhaleDuration = 2.0
            self.holdDuration = 2.0
            self.exhaleDuration = 1.0
            self.cycleTotalSeconds = 5.0
        case .wStretch:
            self.inhaleDuration = 3.0
            self.holdDuration = 3.0
            self.exhaleDuration = 1.5
            self.cycleTotalSeconds = 7.5
        }
        self.cycleElapsedSeconds = 0.0
        updatePhaseDisplay(phase: .inhale, phaseFraction: 0.0, remaining: inhaleDuration)
    }

    func tick(deltaSeconds: Double) {
        cycleElapsedSeconds += deltaSeconds
        if cycleElapsedSeconds >= cycleTotalSeconds {
            cycleElapsedSeconds -= cycleTotalSeconds
        }

        let newPhase: SUPracticeBreathPhase
        let phaseFraction: Double
        let phaseRemaining: Double

        if cycleElapsedSeconds < inhaleDuration {
            newPhase = .inhale
            phaseFraction = cycleElapsedSeconds / inhaleDuration
            phaseRemaining = max(0, inhaleDuration - cycleElapsedSeconds)
        } else if cycleElapsedSeconds < (inhaleDuration + holdDuration) {
            newPhase = .hold
            let holdElapsed = cycleElapsedSeconds - inhaleDuration
            phaseFraction = holdElapsed / holdDuration
            phaseRemaining = max(0, holdDuration - holdElapsed)
        } else {
            newPhase = .exhale
            let exhaleElapsed = cycleElapsedSeconds - (inhaleDuration + holdDuration)
            phaseFraction = exhaleElapsed / exhaleDuration
            phaseRemaining = max(0, exhaleDuration - exhaleElapsed)
        }

        if newPhase != currentPhase {
            currentPhase = newPhase
            triggerPhaseTransitionHaptic(newPhase)
        }

        updatePhaseDisplay(phase: newPhase, phaseFraction: phaseFraction, remaining: phaseRemaining)
    }

    private func updatePhaseDisplay(phase: SUPracticeBreathPhase, phaseFraction: Double, remaining: Double) {
        breathPhaseLabel.text = phase.title
        breathIconImageView.tintColor = phase.themeColor
        breathProgressView.progressTintColor = phase.themeColor
        breathProgressView.setProgress(Float(phaseFraction), animated: true)
        breathCountdownLabel.text = String(format: "%.1fs", remaining)

        let orbScale: CGFloat
        switch phase {
        case .inhale:
            orbScale = 1.0 + CGFloat(phaseFraction) * 0.18
            breathOrbView.backgroundColor = phase.themeColor.withAlphaComponent(0.18 + CGFloat(phaseFraction) * 0.12)
        case .hold:
            orbScale = 1.18
            breathOrbView.backgroundColor = phase.themeColor.withAlphaComponent(0.28)
        case .exhale:
            orbScale = 1.18 - CGFloat(phaseFraction) * 0.18
            breathOrbView.backgroundColor = phase.themeColor.withAlphaComponent(0.28 - CGFloat(phaseFraction) * 0.12)
        }

        UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.breathOrbView.transform = CGAffineTransform(scaleX: orbScale, y: orbScale)
        }
    }

    private func triggerPhaseTransitionHaptic(_ phase: SUPracticeBreathPhase) {
        hapticGenerator.impactOccurred()
    }
}
