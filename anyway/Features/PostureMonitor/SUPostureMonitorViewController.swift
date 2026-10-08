//
//  SUPostureMonitorViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit
import os

/// Tab 1: 核心姿态监测与桌宠主页 —— 驱动宠物形态微动效、实时台词气泡、骨气能量与校准流转
final class SUPostureMonitorViewController: SUBaseViewController {

    private let viewModel: SUPostureMonitorViewModel

    // MARK: - 独立封装视图组件
    private let petContainerView = SUPetVisualContainerView()
    private let speechBubbleView = SUPetSpeechBubbleView()
    private let gaugeView = SUPostureGaugeView()

    // MARK: - 导航栏轻量状态指示器
    private let energyBadgeButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        config.image = UIImage(systemName: "bolt.heart.fill", withConfiguration: symbolConfig)
        config.imagePadding = 4
        config.title = "0 骨气币"
        config.baseBackgroundColor = .systemOrange.withAlphaComponent(0.15)
        config.baseForegroundColor = .systemOrange
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        let button = UIButton(configuration: config)
        return button
    }()

    private let personaBadgeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        config.image = UIImage(systemName: "briefcase.fill", withConfiguration: symbolConfig)
        config.imagePadding = 5
        config.title = "打工人"
        config.baseForegroundColor = .secondaryLabel
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        let button = UIButton(configuration: config)
        return button
    }()

    private let calibrateButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "一键端坐校准"
        config.image = UIImage(systemName: "scope")
        config.imagePadding = 8
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        let button = UIButton(configuration: config)
        return button
    }()

    // MARK: - 模拟器专属调试工具条 (仅模拟器展示)
    #if targetEnvironment(simulator)
    private let debugPanelCard: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
        view.layer.masksToBounds = true
        return view
    }()

    private let debugSliderLabel: UILabel = {
        let label = UILabel()
        label.text = "模拟器低头角度调试: 0°"
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let debugPitchSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 45.0
        slider.value = 0.0
        return slider
    }()
    #endif

    init(viewModel: SUPostureMonitorViewModel = SUPostureMonitorViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = SUPostureMonitorViewModel()
        super.init(coder: coder)
    }

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = "实时姿态守护"

        // 导航栏配置清新简约原生 SF 图标指示器
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: personaBadgeButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: energyBadgeButton)

        // 挂载 SwiftUI 宠物容器子视图
        view.addSubview(petContainerView)
        petContainerView.attach(to: self)

        // 挂载台词对话气泡
        view.addSubview(speechBubbleView)
        speechBubbleView.isHidden = true // 初始无台词时隐藏

        // 挂载角度负荷表盘
        view.addSubview(gaugeView)

        // 挂载校准按钮
        view.addSubview(calibrateButton)

        #if targetEnvironment(simulator)
        view.addSubview(debugPanelCard)
        debugPanelCard.addSubview(debugSliderLabel)
        debugPanelCard.addSubview(debugPitchSlider)
        #endif

        updateEnergyBadge(totalCoins: viewModel.currentTotalEnergyCoins)
        updatePersonaBadge(persona: viewModel.activePersona)
    }

    override func setupConstraints() {
        super.setupConstraints()

        speechBubbleView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(6)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding + 8)
        }

        petContainerView.snp.makeConstraints { make in
            make.top.equalTo(speechBubbleView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(SULayoutConstants.petContainerHeight)
        }

        gaugeView.snp.makeConstraints { make in
            make.top.equalTo(petContainerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        calibrateButton.snp.makeConstraints { make in
            make.top.equalTo(gaugeView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
            make.height.equalTo(SULayoutConstants.primaryButtonHeight)
        }

        #if targetEnvironment(simulator)
        debugPanelCard.snp.makeConstraints { make in
            make.top.equalTo(calibrateButton.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-SULayoutConstants.smallSpacing)
        }

        debugSliderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        debugPitchSlider.snp.makeConstraints { make in
            make.top.equalTo(debugSliderLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().offset(-6)
        }
        #endif
    }

    override func setupBindings() {
        super.setupBindings()

        calibrateButton.addTarget(self, action: #selector(didTapCalibrate), for: .touchUpInside)

        speechBubbleView.onBubbleTapped = { [weak self] in
            self?.viewModel.replayCurrentQuote()
        }

        #if targetEnvironment(simulator)
        debugPitchSlider.addTarget(self, action: #selector(didChangeDebugSlider(_:)), for: .valueChanged)
        #endif

        viewModel.onReadingUpdated = { [weak self] reading in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.gaugeView.configure(with: reading, connectionState: self.viewModel.connectionState)
            }
        }

        viewModel.onPostureStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.petContainerView.configure(with: state)
            }
        }

        viewModel.onQuoteUpdated = { [weak self] quote, persona in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let iconColor = UIColor(named: persona.rawValue) ?? .systemOrange
                self.speechBubbleView.configure(text: quote, iconColor: iconColor)
            }
        }

        viewModel.onEnergyUpdated = { [weak self] total, today in
            DispatchQueue.main.async {
                self?.updateEnergyBadge(totalCoins: total)
            }
        }

        viewModel.onPersonaChanged = { [weak self] persona in
            DispatchQueue.main.async {
                self?.updatePersonaBadge(persona: persona)
            }
        }

        viewModel.onCalibrationProgress = { [weak self] progress in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let percent = Int(progress * 100)
                self.calibrateButton.setTitle("校准中 \(percent)%", for: .normal)
            }
        }

        viewModel.onCalibrationFinished = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.calibrateButton.setTitle("一键端坐校准", for: .normal)
            }
        }

        viewModel.startMonitoring()
    }

    private func updateEnergyBadge(totalCoins: Int) {
        energyBadgeButton.setTitle("\(totalCoins) 骨气币", for: .normal)
    }

    private func updatePersonaBadge(persona: SUPetPersona) {
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        personaBadgeButton.setImage(UIImage(systemName: persona.iconSystemName, withConfiguration: config), for: .normal)
        personaBadgeButton.setTitle(persona.displayName, for: .normal)
    }

    @objc private func didTapCalibrate() {
        viewModel.startCalibration()
    }

    #if targetEnvironment(simulator)
    @objc private func didChangeDebugSlider(_ sender: UISlider) {
        let angle = Double(sender.value)
        debugSliderLabel.text = String(format: "模拟器低头角度调试: %.1f°", angle)
        viewModel.injectSimulatedAngles(pitchDeg: angle, rollDeg: 0.0)
    }
    #endif

    override func adaptLayoutForSize(_ size: CGSize) {
        super.adaptLayoutForSize(size)
        let isDualPane = size.width >= SULayoutConstants.duoSplitBreakpointWidth
        if isDualPane {
            // iPhone Duo 展开态：左栏放台词与宠物，右栏放表盘与校准
            speechBubbleView.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(SULayoutConstants.verticalSpacing)
                make.leading.equalToSuperview().offset(SULayoutConstants.horizontalPadding)
                make.width.equalToSuperview().multipliedBy(0.48)
            }
            petContainerView.snp.remakeConstraints { make in
                make.top.equalTo(speechBubbleView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.equalToSuperview().offset(SULayoutConstants.horizontalPadding)
                make.width.equalToSuperview().multipliedBy(0.48)
                make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-SULayoutConstants.verticalSpacing)
            }
            gaugeView.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(SULayoutConstants.verticalSpacing)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
                make.width.equalToSuperview().multipliedBy(0.48)
            }
            calibrateButton.snp.remakeConstraints { make in
                make.top.equalTo(gaugeView.snp.bottom).offset(SULayoutConstants.verticalSpacing * 2)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
                make.width.equalToSuperview().multipliedBy(0.48)
                make.height.equalTo(SULayoutConstants.primaryButtonHeight)
            }
        } else {
            // 单列经典自适应流
            speechBubbleView.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(6)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding + 8)
            }
            petContainerView.snp.remakeConstraints { make in
                make.top.equalTo(speechBubbleView.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(SULayoutConstants.petContainerHeight)
            }
            gaugeView.snp.remakeConstraints { make in
                make.top.equalTo(petContainerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            calibrateButton.snp.remakeConstraints { make in
                make.top.equalTo(gaugeView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
                make.height.equalTo(SULayoutConstants.primaryButtonHeight)
            }
        }
    }
}
