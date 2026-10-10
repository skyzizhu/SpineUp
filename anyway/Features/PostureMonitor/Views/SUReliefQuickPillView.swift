//
//  SUReliefQuickPillView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 首页 30 秒急救减负智能胶囊视图 —— 支持疲劳态自适应变色、微脉冲呼吸光效、一键唤起微操与回血奖励反馈
final class SUReliefQuickPillView: UIView {

    enum PillState: Equatable {
        case hidden
        case normal
        case fatigued(extraLoadKg: Double)
        case recovered(alleviatedKg: Double)
    }

    var onTapped: (() -> Void)?
    var onDismissRequested: (() -> Void)?

    private(set) var currentState: PillState = .hidden
    private(set) var isShowingRecovered: Bool = false

    private let containerButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 23
        btn.layer.cornerCurve = .continuous
        btn.layer.borderWidth = 0.8
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.05
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 8
        return btn
    }()

    private let iconContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        if let descriptor = UIFont.systemFont(ofSize: 13.5, weight: .bold).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 13.5)
        } else {
            label.font = .systemFont(ofSize: 13.5, weight: .bold)
        }
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let badgeContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 11
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.font = .systemFont(ofSize: 11, weight: .bold)
        return label
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = false
        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        iv.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let badgeStackView: UIStackView = {
        let stack = UIStackView()
        stack.isUserInteractionEnabled = false
        stack.axis = .horizontal
        stack.spacing = 3
        stack.alignment = .center
        return stack
    }()

    private var recoveryResetWorkItem: DispatchWorkItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupInteractions()
        self.alpha = 0.0
        self.isHidden = true
        updateState(.hidden, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.height > 0 && containerButton.bounds.width > 0 && containerButton.bounds.height > 0 {
            containerButton.layer.shadowPath = UIBezierPath(
                roundedRect: containerButton.bounds,
                cornerRadius: 23
            ).cgPath
        }
    }

    private func setupViews() {
        addSubview(containerButton)
        containerButton.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        containerButton.addSubview(titleLabel)

        badgeStackView.addArrangedSubview(badgeLabel)
        badgeStackView.addArrangedSubview(chevronImageView)
        badgeContainer.addSubview(badgeStackView)
        containerButton.addSubview(badgeContainer)
    }

    private func setupConstraints() {
        containerButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(15)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(badgeContainer.snp.leading).offset(-8)
        }

        badgeContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }

        badgeStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
    }

    private func setupInteractions() {
        containerButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        containerButton.addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        containerButton.addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    // MARK: - 状态更新
    func updateState(_ state: PillState, animated: Bool = true) {
        if case .recovered = state {
            isShowingRecovered = true
            recoveryResetWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.isShowingRecovered = false
                self.updateState(.hidden, animated: true)
                self.onDismissRequested?()
            }
            recoveryResetWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
        } else if isShowingRecovered {
            return
        }

        // 如果只是在 fatigued 状态下微调承重数值且紧急程度未跃迁，直接平滑更新文字，不触发全局 crossDissolve 避免闪烁
        if case .fatigued(let newKg) = state, case .fatigued(let oldKg) = currentState {
            let oldSevere = oldKg >= 13.0
            let newSevere = newKg >= 13.0
            if oldSevere == newSevere {
                self.currentState = state
                let fmt = SULocalized("relief_pill_fatigue_title", default: "颈椎承重 %.1f kg · 立即微操回血")
                self.titleLabel.text = String(format: fmt, newKg)
                return
            }
        }

        guard currentState != state || !animated else { return }
        self.currentState = state

        let applyUI = {
            switch state {
            case .hidden:
                self.stopPulseAnimation()
                self.alpha = 0.0
                self.isHidden = true

            case .normal:
                self.stopPulseAnimation()
                self.alpha = 1.0
                self.isHidden = false
                self.containerButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.08)
                self.containerButton.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.22).cgColor

                let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
                self.iconImageView.image = UIImage(systemName: "shield.lefthalf.filled", withConfiguration: config)
                self.iconImageView.tintColor = .systemGreen
                self.iconContainer.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.14)

                self.titleLabel.text = SULocalized("relief_pill_normal_title", default: "急救减负 · 麦肯基微操回血")
                self.titleLabel.textColor = .systemGreen

                self.badgeContainer.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
                self.badgeLabel.text = SULocalized("relief_pill_normal_badge", default: "即刻舒缓")
                self.badgeLabel.textColor = .systemGreen
                self.chevronImageView.tintColor = UIColor.systemGreen.withAlphaComponent(0.8)

            case .fatigued(let extraLoadKg):
                self.startPulseAnimation()
                let isSevere = extraLoadKg >= 13.0
                let stateColor = isSevere ? UIColor.systemRed : UIColor.systemOrange
                let iconName = isSevere ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill"
                let badgeText = isSevere
                    ? SULocalized("relief_pill_severe_badge", default: "高危报警")
                    : SULocalized("relief_pill_fatigue_badge", default: "急救对冲")

                self.containerButton.backgroundColor = stateColor.withAlphaComponent(0.12)
                self.containerButton.layer.borderColor = stateColor.withAlphaComponent(0.40).cgColor

                let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
                self.iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
                self.iconImageView.tintColor = stateColor
                self.iconContainer.backgroundColor = stateColor.withAlphaComponent(0.18)

                let fmt = SULocalized("relief_pill_fatigue_title", default: "颈椎承重 %.1f kg · 立即微操回血")
                self.titleLabel.text = String(format: fmt, extraLoadKg)
                self.titleLabel.textColor = stateColor

                self.badgeContainer.backgroundColor = stateColor.withAlphaComponent(0.20)
                self.badgeLabel.text = badgeText
                self.badgeLabel.textColor = stateColor
                self.chevronImageView.tintColor = stateColor.withAlphaComponent(0.9)

            case .recovered(let alleviatedKg):
                self.stopPulseAnimation()
                self.containerButton.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.12)
                self.containerButton.layer.borderColor = UIColor.systemTeal.withAlphaComponent(0.38).cgColor

                let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
                self.iconImageView.image = UIImage(systemName: "checkmark.seal.fill", withConfiguration: config)
                self.iconImageView.tintColor = .systemTeal
                self.iconContainer.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.18)

                let fmt = SULocalized("relief_pill_recovered_title", default: "🎉 颈椎已卸负 %.1f kg · 骨气币 +10")
                self.titleLabel.text = String(format: fmt, alleviatedKg)
                self.titleLabel.textColor = .systemTeal

                self.badgeContainer.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.20)
                self.badgeLabel.text = SULocalized("relief_pill_recovered_badge", default: "回血成功")
                self.badgeLabel.textColor = .systemTeal
                self.chevronImageView.tintColor = UIColor.systemTeal.withAlphaComponent(0.9)
            }
        }

        if animated {
            UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve]) {
                applyUI()
            }
        } else {
            applyUI()
        }
    }

    // MARK: - 微脉冲呼吸光效
    private func startPulseAnimation() {
        guard containerButton.layer.animation(forKey: "pulse_relief_anim") == nil else { return }
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 1.0
        anim.toValue = 1.025
        anim.duration = 0.85
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        containerButton.layer.add(anim, forKey: "pulse_relief_anim")
    }

    private func stopPulseAnimation() {
        containerButton.layer.removeAnimation(forKey: "pulse_relief_anim")
        containerButton.transform = .identity
    }

    // MARK: - 交互事件
    @objc private func didTapButton() {
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        onTapped?()
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.containerButton.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.containerButton.alpha = 0.9
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction]) {
            self.containerButton.transform = .identity
            self.containerButton.alpha = 1.0
        }
    }
}
