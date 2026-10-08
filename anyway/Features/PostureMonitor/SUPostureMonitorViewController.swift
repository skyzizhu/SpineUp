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
    private let connectionBannerView = SUConnectionBannerView()
    private let petContainerView = SUPetVisualContainerView()
    private let speechBubbleView = SUPetSpeechBubbleView()
    private let gaugeView = SUPostureGaugeView()

    // MARK: - 顶部状态指示栏（解耦自 NavigationBar，避免挤占标题与文字折行）
    private let topStatusBarView: UIView = {
        let view = UIView()
        return view
    }()

    private let energyBadgeButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        config.image = UIImage(systemName: "bolt.heart.fill", withConfiguration: symbolConfig)
        config.imagePadding = 5
        config.title = "0 骨气币"
        config.baseBackgroundColor = .systemOrange.withAlphaComponent(0.12)
        config.baseForegroundColor = .systemOrange
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.titleLineBreakMode = .byTruncatingTail
        let button = UIButton(configuration: config)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()

    private let personaBadgeButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        config.image = UIImage(systemName: "briefcase.fill", withConfiguration: symbolConfig)
        config.imagePadding = 6
        config.title = "打工人"
        config.baseBackgroundColor = .secondarySystemFill
        config.baseForegroundColor = .label
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.titleLineBreakMode = .byTruncatingTail
        let button = UIButton(configuration: config)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()

    private let calibrateButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = SULocalized("calibrate_button", default: "一键端坐校准")
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
        navigationItem.title = SULocalized("monitor_title", default: "实时姿态守护")

        // 导航栏清空左右按钮，完全释放横向呼吸空间，杜绝标题被挤压截断
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil

        // 挂载顶部状态栏及双胶囊指示器
        view.addSubview(topStatusBarView)
        topStatusBarView.addSubview(personaBadgeButton)
        topStatusBarView.addSubview(energyBadgeButton)

        // 挂载 SwiftUI 宠物容器子视图
        view.addSubview(petContainerView)
        petContainerView.attach(to: self)

        // 挂载连接异常与降级引导横幅
        view.addSubview(connectionBannerView)

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

        topStatusBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(4)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(34)
        }

        personaBadgeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
            make.trailing.lessThanOrEqualTo(energyBadgeButton.snp.leading).offset(-10)
        }

        energyBadgeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }

        connectionBannerView.snp.makeConstraints { make in
            make.top.equalTo(topStatusBarView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        speechBubbleView.snp.makeConstraints { make in
            make.top.equalTo(connectionBannerView.snp.bottom).offset(6)
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
        personaBadgeButton.addTarget(self, action: #selector(didTapPersonaBadge), for: .touchUpInside)
        energyBadgeButton.addTarget(self, action: #selector(didTapEnergyBadge), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDidChange),
            name: SULocalizationManager.languageDidChangeNotification,
            object: nil
        )

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
                let format = SULocalized("calibrating_progress", default: "校准中 %d%%")
                self.calibrateButton.setTitle(String(format: format, percent), for: .normal)
            }
        }

        viewModel.onConnectionStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.connectionBannerView.updateConnectionState(state)
                self.gaugeView.configure(with: self.viewModel.latestReading ?? SUPostureReading(
                    timestamp: Date(),
                    rawPitch: 0,
                    rawRoll: 0,
                    relativePitchDeg: 0,
                    relativeRollDeg: 0,
                    state: .unknown,
                    extraLoadKg: 0
                ), connectionState: state)
            }
        }
        connectionBannerView.updateConnectionState(viewModel.connectionState)

        viewModel.onCalibrationFinished = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.calibrateButton.setTitle(SULocalized("calibrate_button", default: "一键端坐校准"), for: .normal)
            }
        }

        viewModel.startMonitoring()
    }

    private func updateEnergyBadge(totalCoins: Int) {
        let format = SULocalized("energy_coins_badge", default: "%d 骨气币")
        energyBadgeButton.setTitle(String(format: format, totalCoins), for: .normal)
    }

    private func updatePersonaBadge(persona: SUPetPersona) {
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        personaBadgeButton.setImage(UIImage(systemName: persona.iconSystemName, withConfiguration: config), for: .normal)
        personaBadgeButton.setTitle(persona.displayName, for: .normal)
    }

    @objc private func didTapPersonaBadge() {
        let alert = UIAlertController(
            title: SULocalized("switch_persona_title", default: "切换桌宠人格"),
            message: SULocalized("switch_persona_subtitle", default: "不同人格拥有截然不同的督促台词风格与交互动效"),
            preferredStyle: .actionSheet
        )

        for persona in SUPetPersona.allCases {
            let isCurrent = persona == viewModel.activePersona
            let title = isCurrent ? "✓ \(persona.displayName)" : persona.displayName
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                SUPetPersonaManager.shared.selectPersona(persona)
                SUAudioFeedbackManager.shared.triggerHapticSelection()
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: SULocalized("cancel", default: "取消"), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = personaBadgeButton
            popover.sourceRect = personaBadgeButton.bounds
        }

        present(alert, animated: true)
    }

    @objc private func didTapEnergyBadge() {
        SUAudioFeedbackManager.shared.triggerHapticLightTap()
        let alert = UIAlertController(
            title: SULocalized("energy_coins_badge_title", default: "骨气能量币"),
            message: String(
                format: SULocalized("energy_coins_info_msg", default: "当前累计：%d 骨气币\n保持端坐可获得骨气币奖励，连续挺拔打卡可激活专属成就！"),
                viewModel.currentTotalEnergyCoins
            ),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: SULocalized("confirm", default: "好的"), style: .default))
        present(alert, animated: true)
    }

    @objc private func handleLanguageDidChange() {
        navigationItem.title = SULocalized("monitor_title", default: "实时姿态守护")
        updateEnergyBadge(totalCoins: viewModel.currentTotalEnergyCoins)
        updatePersonaBadge(persona: viewModel.activePersona)
        calibrateButton.setTitle(SULocalized("calibrate_button", default: "一键端坐校准"), for: .normal)
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
        let mode = SUDuoLayoutHelper.currentDisplayMode(size: size, traitCollection: traitCollection)
        switch mode {
        case .regularDual, .tent:
            // iPhone Duo 展开态/帐篷立态：中缝避让双栏，左栏放台词与桌宠，右栏放仪表盘与校准控制
            let layout = SUDuoLayoutHelper.splitColumnLayout(totalWidth: size.width)
            topStatusBarView.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(34)
            }
            connectionBannerView.snp.remakeConstraints { make in
                make.top.equalTo(topStatusBarView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            speechBubbleView.snp.remakeConstraints { make in
                make.top.equalTo(connectionBannerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.equalToSuperview().offset(SULayoutConstants.horizontalPadding)
                make.width.equalTo(layout.leftWidth)
            }
            petContainerView.snp.remakeConstraints { make in
                make.top.equalTo(speechBubbleView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.equalToSuperview().offset(SULayoutConstants.horizontalPadding)
                make.width.equalTo(layout.leftWidth)
                make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-SULayoutConstants.verticalSpacing)
            }
            gaugeView.snp.remakeConstraints { make in
                make.top.equalTo(connectionBannerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
                make.width.equalTo(layout.rightWidth)
            }
            calibrateButton.snp.remakeConstraints { make in
                make.top.equalTo(gaugeView.snp.bottom).offset(SULayoutConstants.verticalSpacing * 2)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
                make.width.equalTo(layout.rightWidth)
                make.height.equalTo(SULayoutConstants.primaryButtonHeight)
            }

        case .tabletop:
            // iPhone Duo 半折悬停 Tabletop 态：上屏展示宠物，下屏操作控制
            let vertical = SUDuoLayoutHelper.tabletopVerticalLayout(totalHeight: size.height)
            topStatusBarView.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(34)
            }
            connectionBannerView.snp.remakeConstraints { make in
                make.top.equalTo(topStatusBarView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            speechBubbleView.snp.remakeConstraints { make in
                make.top.equalTo(connectionBannerView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding + 8)
            }
            petContainerView.snp.remakeConstraints { make in
                make.top.equalTo(speechBubbleView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(vertical.topHeight * 0.7)
            }
            gaugeView.snp.remakeConstraints { make in
                make.top.equalTo(view.snp.top).offset(vertical.topHeight + vertical.foldSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            calibrateButton.snp.remakeConstraints { make in
                make.top.equalTo(gaugeView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
                make.height.equalTo(SULayoutConstants.primaryButtonHeight)
            }

        case .compact:
            // 单列经典自适应流
            topStatusBarView.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(34)
            }
            connectionBannerView.snp.remakeConstraints { make in
                make.top.equalTo(topStatusBarView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            speechBubbleView.snp.remakeConstraints { make in
                make.top.equalTo(connectionBannerView.snp.bottom).offset(6)
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
