//
//  SUNeckPomodoroCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/15.
//

import UIKit
import SnapKit

/// 无耳机/未佩戴场景下的优雅降级 —— 护颈专注番茄钟卡片
final class SUNeckPomodoroCardView: UIView {

    private let containerView: SULiquidGlassView = {
        let view = SULiquidGlassView(
            cornerRadius: SULayoutConstants.cornerRadiusLarge,
            tintColor: UIColor.systemBlue.withAlphaComponent(0.08)
        )
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        iv.image = UIImage(systemName: "timer", withConfiguration: config)
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("pomodoro_card_title", default: "护颈番茄钟 (无耳机模式)")
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let stateBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("pomodoro_state_idle", default: "待开启")
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        label.layer.cornerRadius = 9
        label.layer.masksToBounds = true
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let timerLabel: UILabel = {
        let label = UILabel()
        label.text = "25:00"
        if let descriptor = UIFont.monospacedDigitSystemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 34)
        } else {
            label.font = .monospacedDigitSystemFont(ofSize: 34, weight: .bold)
        }
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("pomodoro_card_desc", default: "挺拔工作 25 分钟 · 颈椎舒展 5 分钟 · 保持自律与骨气")
        label.font = .systemFont(ofSize: 11.5, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let cycleLabel: UILabel = {
        let label = UILabel()
        label.text = String(format: SULocalized("pomodoro_cycles_val", default: "今日已完成 %d 轮"), 0)
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    private let controlButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
        let btn = UIButton(configuration: config)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.minimumScaleFactor = 0.85
        return btn
    }()

    private let resetButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemGray5
        config.baseForegroundColor = .secondaryLabel
        config.title = SULocalized("pomodoro_btn_reset", default: "重置")
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        let btn = UIButton(configuration: config)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.minimumScaleFactor = 0.85
        return btn
    }()

    private let pomodoroManager = SUNeckPomodoroManager.shared

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bindManager()
        updateUI(state: pomodoroManager.state, remainingSeconds: pomodoroManager.remainingSeconds)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 180)
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let content = containerView.contentView
        content.addSubview(iconImageView)
        content.addSubview(titleLabel)
        content.addSubview(stateBadgeLabel)
        content.addSubview(timerLabel)
        content.addSubview(descriptionLabel)
        content.addSubview(cycleLabel)

        let buttonStack = UIStackView(arrangedSubviews: [resetButton, controlButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 10
        buttonStack.distribution = .fillProportionally
        content.addSubview(buttonStack)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(iconImageView)
        }

        stateBadgeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(iconImageView)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(52)
        }

        timerLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(timerLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        cycleLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }

        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(cycleLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
            make.height.equalTo(34)
        }

        controlButton.addTarget(self, action: #selector(didTapControl), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
    }

    private func bindManager() {
        pomodoroManager.onTick = { [weak self] state, seconds in
            DispatchQueue.main.async {
                self?.updateUI(state: state, remainingSeconds: seconds)
            }
        }

        pomodoroManager.onStateChanged = { [weak self] oldState, newState in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updateUI(state: newState, remainingSeconds: self.pomodoroManager.remainingSeconds)
            }
        }
    }

    private func updateUI(state: SUNeckPomodoroState, remainingSeconds: Int) {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", mins, secs)

        cycleLabel.text = String(format: SULocalized("pomodoro_cycles_val", default: "今日已完成 %d 轮"), pomodoroManager.completedCycles)

        var config = controlButton.configuration ?? UIButton.Configuration.filled()
        switch state {
        case .idle:
            stateBadgeLabel.text = SULocalized("pomodoro_state_idle", default: "待开启")
            stateBadgeLabel.textColor = .systemBlue
            stateBadgeLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
            config.title = SULocalized("pomodoro_btn_start", default: "开始专注")
            config.baseBackgroundColor = .systemBlue
            resetButton.isHidden = true

        case .working:
            stateBadgeLabel.text = SULocalized("pomodoro_state_working", default: "挺拔专注中")
            stateBadgeLabel.textColor = .systemGreen
            stateBadgeLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
            config.title = SULocalized("pomodoro_btn_pause", default: "暂停")
            config.baseBackgroundColor = .systemOrange
            resetButton.isHidden = false

        case .resting:
            stateBadgeLabel.text = SULocalized("pomodoro_state_resting", default: "颈椎舒展中")
            stateBadgeLabel.textColor = .systemPurple
            stateBadgeLabel.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
            config.title = SULocalized("pomodoro_btn_pause", default: "暂停")
            config.baseBackgroundColor = .systemPurple
            resetButton.isHidden = false
        }
        controlButton.configuration = config
    }

    @objc private func didTapControl() {
        SUAudioFeedbackManager.shared.triggerHapticLightTap()
        if pomodoroManager.state == .idle {
            pomodoroManager.startWorkSession()
            SUSpeechManager.shared.speak(
                text: SULocalized("pomodoro_start_speech", default: "无耳机护颈番茄钟已开启！保持挺拔，25分钟后本喵提醒你舒展颈椎。"),
                persona: SUPetPersonaManager.shared.currentPersona,
                force: true
            )
        } else {
            pomodoroManager.stopSession()
        }
    }

    @objc private func didTapReset() {
        SUAudioFeedbackManager.shared.triggerHapticLightTap()
        pomodoroManager.stopSession()
    }
}
