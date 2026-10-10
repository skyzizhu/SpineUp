//
//  SUPostureMonitorViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import CoreMotion
import SnapKit
import os

/// Tab 1: 核心姿态监测与桌宠主页 —— 驱动宠物形态微动效、实时台词气泡、骨气能量与校准流转
final class SUPostureMonitorViewController: SUBaseViewController {

    private let viewModel: SUPostureMonitorViewModel

    // MARK: - 可滑动内容容器
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let contentView = UIView()

    // MARK: - 独立封装视图组件
    private let connectionBannerView = SUConnectionBannerView()
    private let petContainerView = SUPetVisualContainerView()
    private let speechBubbleView = SUPetSpeechBubbleView()
    private let gaugeView = SUPostureGaugeView()
    private let reliefQuickPillView = SUReliefQuickPillView()

    // MARK: - 顶部自适应通知流（横幅 / 台词气泡，隐藏时自动折叠高度为0，彻底消除空白冗余）
    private let topNoticeStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    // MARK: - 顶部状态指示栏
    private let topStatusBarView: UIView = {
        let view = UIView()
        return view
    }()

    private let energyBadgeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        config.image = UIImage(systemName: "bolt.heart.fill", withConfiguration: symbolConfig)
        config.imagePadding = 4
        config.title = "0 骨气币"
        
        config.baseBackgroundColor = .systemOrange.withAlphaComponent(0.15)
        config.baseForegroundColor = .systemOrange
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9)
        config.titleLineBreakMode = .byTruncatingTail
        
        let transformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 11.5, weight: .bold)
            return outgoing
        }
        config.titleTextAttributesTransformer = transformer
        
        let button = UIButton(configuration: config)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()

    private let personaBadgeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        config.image = UIImage(systemName: "briefcase.fill", withConfiguration: symbolConfig)
        config.imagePadding = 4
        config.title = "打工人"
        
        config.baseBackgroundColor = UIColor.label.withAlphaComponent(0.06)
        config.baseForegroundColor = .label
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9)
        config.titleLineBreakMode = .byTruncatingTail
        
        let transformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 11.5, weight: .bold)
            return outgoing
        }
        config.titleTextAttributesTransformer = transformer
        
        let button = UIButton(configuration: config)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()

    private let connectionCapsuleButton: UIButton = {
        var config = UIButton.Configuration.filled()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        config.image = UIImage(systemName: "circle.fill", withConfiguration: symbolConfig)
        config.imagePadding = 5
        config.title = SULocalized("sensor_tracking", default: "AirPods 空间运动追踪中")
        
        config.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        config.baseForegroundColor = .systemGreen
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        config.titleLineBreakMode = .byTruncatingTail
        
        let transformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
            return outgoing
        }
        config.titleTextAttributesTransformer = transformer
        
        let button = UIButton(configuration: config)
        button.layer.borderWidth = 0.8
        button.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.25).cgColor
        button.layer.cornerRadius = 17
        button.layer.masksToBounds = true
        return button
    }()

    private let calibrateButton: UIButton = {
        var config = UIButton.Configuration.filled()
        
        var titleAttr = AttributedString(SULocalized("calibrate_button", default: "一键端坐校准"))
        titleAttr.font = UIFont.systemFont(ofSize: 16.5, weight: .bold)
        config.attributedTitle = titleAttr
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        config.image = UIImage(systemName: "scope", withConfiguration: symbolConfig)
        config.imagePadding = 10
        config.cornerStyle = .capsule
        
        // 优雅深邃的 Apple 皇家蔚蓝 (Apple Royal Blue)，质感高级纯净
        let brandBlue = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.15, green: 0.52, blue: 1.0, alpha: 1.0)
                : UIColor(red: 0.06, green: 0.46, blue: 0.96, alpha: 1.0)
        }
        config.baseBackgroundColor = brandBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        
        let button = UIButton(configuration: config)
        button.layer.shadowColor = UIColor(red: 0.06, green: 0.46, blue: 0.96, alpha: 1.0).cgColor
        button.layer.shadowOpacity = 0.22
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 14
        return button
    }()


    init(viewModel: SUPostureMonitorViewModel = SUPostureMonitorViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = SUPostureMonitorViewModel()
        super.init(coder: coder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if SUWidgetSyncManager.shared.checkAndConsumePendingCalibration() {
            viewModel.startCalibration()
        }
    }

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = SULocalized("monitor_title", default: "实时姿态守护")

        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(connectionCapsuleButton)
        contentView.addSubview(topStatusBarView)
        topStatusBarView.addSubview(personaBadgeButton)
        topStatusBarView.addSubview(energyBadgeButton)

        contentView.addSubview(petContainerView)
        petContainerView.attach(to: self)
        
        // 增加宠物点击交互
        let petTap = UITapGestureRecognizer(target: self, action: #selector(didTapPet))
        petContainerView.addGestureRecognizer(petTap)
        petContainerView.isUserInteractionEnabled = true

        topNoticeStackView.addArrangedSubview(connectionBannerView)
        topNoticeStackView.addArrangedSubview(speechBubbleView)
        contentView.addSubview(topNoticeStackView)

        connectionBannerView.isHidden = true
        speechBubbleView.isHidden = true

        contentView.addSubview(gaugeView)
        contentView.addSubview(reliefQuickPillView)
        contentView.addSubview(calibrateButton)


        updateEnergyBadge(totalCoins: viewModel.currentTotalEnergyCoins)
        updatePersonaBadge(persona: viewModel.activePersona)
        updateConnectionBadge(state: viewModel.connectionState)
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        connectionCapsuleButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.centerX.equalToSuperview()
            make.height.equalTo(34)
            make.leading.greaterThanOrEqualToSuperview().offset(SULayoutConstants.horizontalPadding)
            make.trailing.lessThanOrEqualToSuperview().offset(-SULayoutConstants.horizontalPadding)
        }

        topStatusBarView.snp.makeConstraints { make in
            make.top.equalTo(connectionCapsuleButton.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(32)
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

        topNoticeStackView.snp.makeConstraints { make in
            make.top.equalTo(topStatusBarView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        petContainerView.snp.makeConstraints { make in
            make.top.equalTo(topNoticeStackView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(SULayoutConstants.petContainerHeight)
        }

        gaugeView.snp.makeConstraints { make in
            make.top.equalTo(petContainerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(SULayoutConstants.gaugeViewHeight)
        }

        reliefQuickPillView.snp.makeConstraints { make in
            make.top.equalTo(gaugeView.snp.bottom).offset(0)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(0)
        }

        calibrateButton.snp.makeConstraints { make in
            make.top.equalTo(reliefQuickPillView.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
            make.height.equalTo(SULayoutConstants.primaryButtonHeight)
            make.bottom.equalTo(contentView.snp.bottom).offset(-SULayoutConstants.sectionSpacing)
        }
    }

    override func setupBindings() {
        super.setupBindings()

        calibrateButton.addTarget(self, action: #selector(didTapCalibrate), for: .touchUpInside)
        personaBadgeButton.addTarget(self, action: #selector(didTapPersonaBadge), for: .touchUpInside)
        connectionCapsuleButton.addTarget(self, action: #selector(didTapConnectionCapsule), for: .touchUpInside)
        #if targetEnvironment(simulator)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressConnectionCapsule(_:)))
        connectionCapsuleButton.addGestureRecognizer(longPress)
        #endif
        energyBadgeButton.addTarget(self, action: #selector(didTapEnergyBadge), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDidChange),
            name: SULocalizationManager.languageDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWidgetCalibrationRequest),
            name: .suRequestCalibrationFromWidget,
            object: nil
        )

        speechBubbleView.onBubbleTapped = { [weak self] in
            self?.viewModel.replayCurrentQuote()
        }

        connectionBannerView.onActionTapped = { [weak self] state in
            guard let self = self else { return }
            self.handleActionForState(state)
        }

        gaugeView.onHazardDetailTapped = { [weak self] in
            guard let self = self else { return }
            let reading = self.viewModel.latestReading
            let pitch = reading?.relativePitchDeg ?? 0.0
            let load = reading?.extraLoadKg ?? 0.0
            let hazardVC = SUPostureHazardSheetViewController(pitchDeg: pitch, extraLoadKg: load)
            let navVC = SUBaseNavigationController(rootViewController: hazardVC)
            if let sheet = navVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
            self.present(navVC, animated: true)
        }

        gaugeView.onReliefGuideTapped = { [weak self] in
            guard let self = self else { return }
            let reading = self.viewModel.latestReading
            let pitch = reading?.relativePitchDeg ?? 0.0
            let load = reading?.extraLoadKg ?? 0.0
            let reliefVC = SUPostureReliefGuideViewController(pitchDeg: pitch, extraLoadKg: load)
            let navVC = SUBaseNavigationController(rootViewController: reliefVC)
            if let sheet = navVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            self.present(navVC, animated: true)
        }

        reliefQuickPillView.onTapped = { [weak self] in
            self?.presentReliefPractice()
        }
        reliefQuickPillView.onDismissRequested = { [weak self] in
            guard let self = self else { return }
            self.setReliefPillExpanded(false, animated: true)
        }


        viewModel.onReadingUpdated = { [weak self] reading in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.gaugeView.configure(with: reading, connectionState: self.viewModel.connectionState)
                self.petContainerView.configure(with: reading.state, pitchDeg: reading.relativePitchDeg)
                self.updateReliefPillState(with: reading)
            }
        }

        viewModel.onPostureStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.petContainerView.configure(with: state, pitchDeg: self.viewModel.latestReading?.relativePitchDeg ?? 0.0)
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
                self.updateConnectionBadge(state: state)
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
        updateConnectionBadge(state: viewModel.connectionState)

        viewModel.onCalibrationFinished = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.calibrateButton.setTitle(SULocalized("calibrate_button", default: "一键端坐校准"), for: .normal)
            }
        }

        viewModel.startMonitoring()
    }

    private func updateConnectionBadge(state: SUHeadphoneConnectionState) {
        var config = connectionCapsuleButton.configuration ?? UIButton.Configuration.filled()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)

        config.image = UIImage(systemName: state.iconSystemName, withConfiguration: symbolConfig)
        config.title = state.displayTitle
        config.baseBackgroundColor = state.themeColor.withAlphaComponent(0.12)
        config.baseForegroundColor = state.themeColor
        connectionCapsuleButton.layer.borderColor = state.themeColor.withAlphaComponent(0.25).cgColor

        let transformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
            return outgoing
        }
        config.titleTextAttributesTransformer = transformer
        connectionCapsuleButton.configuration = config
    }

    @objc private func didTapConnectionCapsule() {
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        handleActionForState(viewModel.connectionState)
    }

    private func handleActionForState(_ state: SUHeadphoneConnectionState) {
        switch state {
        case .connected:
            let alert = UIAlertController(
                title: state.displayTitle,
                message: state.displaySubtitle,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: SULocalized("action_calibrate_baseline", default: "一键端坐校准"), style: .default) { [weak self] _ in
                self?.viewModel.startCalibration()
            })
            alert.addAction(UIAlertAction(title: SULocalized("confirm", default: "好的"), style: .cancel))
            present(alert, animated: true)

        case .connectedWornUnauthorized, .connectedUnwornUnauthorized:
            requestMotionAuthorizationFlow()

        case .connectedUnwornAuthorized:
            let alert = UIAlertController(
                title: state.displayTitle,
                message: state.displaySubtitle,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: SULocalized("confirm", default: "知道了"), style: .default))
            present(alert, animated: true)

        case .disconnected:
            let alert = UIAlertController(
                title: state.displayTitle,
                message: state.displaySubtitle,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: SULocalized("action_connect_bluetooth", default: "前往系统设置"), style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
            alert.addAction(UIAlertAction(title: SULocalized("confirm", default: "我知道了"), style: .cancel))
            present(alert, animated: true)

        case .unsupported:
            let alert = UIAlertController(
                title: SULocalized("unsupported_device_title", default: "设备暂不支持耳机动作感知"),
                message: SULocalized("unsupported_device_desc", default: "SpineUp 需要配备头部空间运动传感器的耳机：\n• AirPods Pro (1代 / 2代)\n• AirPods (3代 / 4代)\n• AirPods Max\n• Beats Fit Pro\n\n车载蓝牙、音箱或基础款 AirPods 1/2 代由于硬件无陀螺仪，无法追踪姿态。"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: SULocalized("confirm", default: "了解"), style: .default))
            present(alert, animated: true)
        }
    }

    private var isRequestingAuth: Bool = false

    private func requestMotionAuthorizationFlow() {
        guard !isRequestingAuth else { return }
        isRequestingAuth = true

        viewModel.requestMotionAuthorization { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isRequestingAuth = false
                if granted {
                    SUAudioFeedbackManager.shared.triggerHapticSuccess()
                } else {
                    let status = CMHeadphoneMotionManager.authorizationStatus()
                    let isRestricted = (status == .restricted)

                    let title = isRestricted
                        ? SULocalized("auth_restricted_title", default: "权限受系统限制")
                        : SULocalized("auth_permission_title", default: "需要「动作与健身」权限")
                    let message = isRestricted
                        ? SULocalized("auth_restricted_msg", default: "运动与健身权限受到家长控制或设备管理策略限制，请前往「系统设置 - 屏幕使用时间 - 内容与隐私访问限制」检查。")
                        : SULocalized("auth_permission_msg", default: "SpineUp 需要访问头部运动数据以计算坐姿角度。请在「设置 - SpineUp」中开启运动权限。")

                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    if !isRestricted {
                        alert.addAction(UIAlertAction(title: SULocalized("go_to_settings", default: "前往系统设置"), style: .default) { _ in
                            if let url = URL(string: UIApplication.openSettingsURLString),
                               UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    alert.addAction(UIAlertAction(title: SULocalized("confirm", default: "好的"), style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        }
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
            let action = UIAlertAction(title: title, style: .default) { _ in
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
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        if let tabBar = tabBarController, (tabBar.viewControllers?.count ?? 0) >= 3 {
            tabBar.selectedIndex = 2
        } else {
            let leaderboardVC = SULeaderboardViewController()
            let navVC = SUBaseNavigationController(rootViewController: leaderboardVC)
            present(navVC, animated: true)
        }
    }

    @objc private func handleLanguageDidChange() {
        navigationItem.title = SULocalized("monitor_title", default: "实时姿态守护")
        updateEnergyBadge(totalCoins: viewModel.currentTotalEnergyCoins)
        updatePersonaBadge(persona: viewModel.activePersona)
        updateConnectionBadge(state: viewModel.connectionState)
        calibrateButton.setTitle(SULocalized("calibrate_button", default: "一键端坐校准"), for: .normal)
        gaugeView.refreshLocalizedStrings()
        if let reading = viewModel.latestReading {
            gaugeView.configure(with: reading, connectionState: viewModel.connectionState)
            petContainerView.configure(with: reading.state, pitchDeg: reading.relativePitchDeg)
        } else {
            petContainerView.configure(with: .upright, pitchDeg: 0.0)
        }
        connectionBannerView.updateConnectionState(viewModel.connectionState)
        reliefQuickPillView.updateState(reliefQuickPillView.currentState, animated: false)
    }

    private var isReliefPillExpanded: Bool = false

    // MARK: - 30 秒急救减负微操一键呼出与回血结算闭环
    private func presentReliefPractice() {
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        let practiceVC = SUPostureReliefPracticeViewController(persona: viewModel.activePersona)
        practiceVC.onPracticeCompleted = { [weak self] in
            guard let self = self else { return }
            // 1. 物理卸负回血对冲 2.0 kg
            SUPostureSessionManager.shared.applyReliefRecovery(alleviatedKg: 2.0)
            // 2. 奖励 10 骨气币
            SUSpineEnergyManager.shared.rewardBonusCoins(10)
            self.updateEnergyBadge(totalCoins: self.viewModel.currentTotalEnergyCoins)
            // 3. 胶囊展开并展示回血成功态 (5秒后自动折叠收起隐退)
            self.reliefQuickPillView.updateState(.recovered(alleviatedKg: 2.0))
            self.setReliefPillExpanded(true, animated: true)
            // 4. 桌宠气泡热烈欢呼
            let cheerQuote = SULocalized("relief_cheer_quote", default: "太棒了！已帮你的颈椎卸下 2.0kg 剪切负荷，奖励 10 骨气币，满血复活！")
            self.speechBubbleView.configure(text: cheerQuote, iconColor: .systemGreen)
            SUSpeechManager.shared.speak(text: cheerQuote, persona: self.viewModel.activePersona, force: true)
            // 5. 触发成功触觉
            SUAudioFeedbackManager.shared.triggerHapticSuccess()
        }

        practiceVC.modalPresentationStyle = .pageSheet
        if let sheet = practiceVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
        present(practiceVC, animated: true)
    }

    private func setReliefPillExpanded(_ expanded: Bool, animated: Bool = true) {
        guard isReliefPillExpanded != expanded else { return }
        isReliefPillExpanded = expanded

        let topOffset: CGFloat = expanded ? 12 : 0
        let height: CGFloat = expanded ? 46 : 0

        reliefQuickPillView.snp.updateConstraints { make in
            make.top.equalTo(gaugeView.snp.bottom).offset(topOffset)
            make.height.equalTo(height)
        }

        if expanded {
            reliefQuickPillView.isHidden = false
        }

        let animationBlock = {
            self.reliefQuickPillView.alpha = expanded ? 1.0 : 0.0
            self.contentView.layoutIfNeeded()
        }

        let completionBlock: (Bool) -> Void = { _ in
            if !expanded {
                self.reliefQuickPillView.isHidden = true
            }
        }

        if animated {
            UIView.animate(
                withDuration: 0.38,
                delay: 0,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.4,
                options: [.curveEaseInOut, .allowUserInteraction],
                animations: animationBlock,
                completion: completionBlock
            )
        } else {
            animationBlock()
            completionBlock(true)
        }
    }

    private func updateReliefPillState(with reading: SUPostureReading) {
        guard !reliefQuickPillView.isShowingRecovered else { return }

        // 仅在用户实际处于驼背前倾（slightSlump 或 severeSlump）且颈椎产生明显额外负荷时呼出急救微操胶囊；
        // 当用户端正挺拔 (upright，额外承重为 0kg) 时，胶囊严密折叠隐藏，杜绝数据矛盾与视觉打扰
        let isSlouching = (reading.state == .slightSlump || reading.state == .severeSlump)
        let isHeavyLoad = reading.extraLoadKg >= 6.0
        let shouldShowRelief = (isSlouching || isHeavyLoad) && reading.extraLoadKg >= 3.0

        if shouldShowRelief {
            // 真实物理额外负荷，与上方力学仪表盘严格 1:1 对齐同步
            reliefQuickPillView.updateState(.fatigued(extraLoadKg: reading.extraLoadKg))
            setReliefPillExpanded(true, animated: true)
        } else {
            reliefQuickPillView.updateState(.hidden)
            setReliefPillExpanded(false, animated: true)
        }
    }

    @objc private func didTapCalibrate() {
        viewModel.startCalibration()
    }

    @objc private func handleWidgetCalibrationRequest() {
        viewModel.startCalibration()
    }

    @objc private func didTapPet() {
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        viewModel.replayCurrentQuote()
    }

    #if targetEnvironment(simulator)
    @objc private func didLongPressConnectionCapsule(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        let sheet = UIAlertController(title: "🛠️ 模拟器：快速切换 AirPods 状态", message: "选择要注入的耳机物理/入耳/权限状态", preferredStyle: .actionSheet)
        let states: [(String, SUHeadphoneConnectionState)] = [
            ("状态 1: 未连接 (disconnected)", .disconnected),
            ("状态 2: 已连接未佩戴未授权 (connectedUnwornUnauthorized)", .connectedUnwornUnauthorized),
            ("状态 3: 已连接未佩戴已授权 (connectedUnwornAuthorized - 挂起)", .connectedUnwornAuthorized),
            ("状态 4: 已连接已佩戴未授权 (connectedWornUnauthorized)", .connectedWornUnauthorized),
            ("状态 5: 已连接已佩戴已授权 (connected - 黄金终态)", .connected),
            ("边缘状态: 硬件不支持 (unsupported)", .unsupported)
        ]
        for (label, state) in states {
            sheet.addAction(UIAlertAction(title: label, style: .default) { [weak self] _ in
                self?.viewModel.injectSimulatedConnectionState(state)
            })
        }
        sheet.addAction(UIAlertAction(title: SULocalized("cancel", default: "取消"), style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = connectionCapsuleButton
            popover.sourceRect = connectionCapsuleButton.bounds
        }
        present(sheet, animated: true)
    }
    #endif

    override func adaptLayoutForSize(_ size: CGSize) {
        super.adaptLayoutForSize(size)
        let mode = SUDuoLayoutHelper.currentDisplayMode(size: size, traitCollection: traitCollection)
        switch mode {
        case .regularDual, .tent:
            // iPhone Duo 展开态/帐篷立态 / iPad / 横屏：中缝避让双栏，左栏放台词与桌宠，右栏放仪表盘与校准控制
            // 避让 iOS 18+ 横屏浮动 TabBar 侧栏 (宽约 72pt)
            let sideBarOffset: CGFloat = 76.0

            connectionCapsuleButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(4)
                make.centerX.equalToSuperview().offset(sideBarOffset / 2)
                make.height.equalTo(34)
                make.leading.greaterThanOrEqualToSuperview().offset(sideBarOffset + SULayoutConstants.horizontalPadding)
                make.trailing.lessThanOrEqualToSuperview().offset(-SULayoutConstants.horizontalPadding)
            }
            topStatusBarView.snp.remakeConstraints { make in
                make.top.equalTo(connectionCapsuleButton.snp.bottom).offset(8)
                make.leading.equalToSuperview().offset(sideBarOffset + SULayoutConstants.horizontalPadding)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
                make.height.equalTo(32)
            }
            topNoticeStackView.snp.remakeConstraints { make in
                make.top.equalTo(topStatusBarView.snp.bottom).offset(4)
                make.leading.equalToSuperview().offset(sideBarOffset + SULayoutConstants.horizontalPadding)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
            }
            petContainerView.snp.remakeConstraints { make in
                make.top.equalTo(topNoticeStackView.snp.bottom).offset(4)
                make.leading.equalToSuperview().offset(sideBarOffset + SULayoutConstants.horizontalPadding)
                make.trailing.equalTo(gaugeView.snp.leading).offset(-SULayoutConstants.horizontalPadding)
                make.width.equalTo(gaugeView.snp.width)
                make.height.equalTo(SULayoutConstants.petContainerHeight)
                make.bottom.lessThanOrEqualTo(contentView.snp.bottom).offset(-SULayoutConstants.sectionSpacing)
            }
            gaugeView.snp.remakeConstraints { make in
                make.top.equalTo(topNoticeStackView.snp.bottom).offset(4)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
                make.height.equalTo(SULayoutConstants.gaugeViewHeight)
            }
            let dualPillTop: CGFloat = isReliefPillExpanded ? 10 : 0
            let dualPillHeight: CGFloat = isReliefPillExpanded ? 46 : 0
            reliefQuickPillView.snp.remakeConstraints { make in
                make.top.equalTo(gaugeView.snp.bottom).offset(dualPillTop)
                make.leading.trailing.equalTo(gaugeView)
                make.height.equalTo(dualPillHeight)
            }
            calibrateButton.snp.remakeConstraints { make in
                make.top.equalTo(reliefQuickPillView.snp.bottom).offset(12)
                make.leading.trailing.equalTo(gaugeView)
                make.height.equalTo(SULayoutConstants.primaryButtonHeight)
                make.bottom.equalTo(contentView.snp.bottom).offset(-SULayoutConstants.sectionSpacing)
            }

        case .tabletop:
            // iPhone Duo 半折悬停 Tabletop 态：上屏展示宠物，下屏操作控制
            let vertical = SUDuoLayoutHelper.tabletopVerticalLayout(totalHeight: size.height)
            connectionCapsuleButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(4)
                make.centerX.equalToSuperview()
                make.height.equalTo(34)
                make.leading.greaterThanOrEqualToSuperview().offset(SULayoutConstants.horizontalPadding)
                make.trailing.lessThanOrEqualToSuperview().offset(-SULayoutConstants.horizontalPadding)
            }
            topStatusBarView.snp.remakeConstraints { make in
                make.top.equalTo(connectionCapsuleButton.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(32)
            }
            topNoticeStackView.snp.remakeConstraints { make in
                make.top.equalTo(topStatusBarView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            petContainerView.snp.remakeConstraints { make in
                make.top.equalTo(topNoticeStackView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(vertical.topHeight * 0.7)
            }
            gaugeView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(vertical.topHeight + vertical.foldSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(SULayoutConstants.gaugeViewHeight)
            }
            let tablePillTop: CGFloat = isReliefPillExpanded ? 10 : 0
            let tablePillHeight: CGFloat = isReliefPillExpanded ? 46 : 0
            reliefQuickPillView.snp.remakeConstraints { make in
                make.top.equalTo(gaugeView.snp.bottom).offset(tablePillTop)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(tablePillHeight)
            }
            calibrateButton.snp.remakeConstraints { make in
                make.top.equalTo(reliefQuickPillView.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
                make.height.equalTo(SULayoutConstants.primaryButtonHeight)
                make.bottom.equalTo(contentView.snp.bottom).offset(-SULayoutConstants.sectionSpacing)
            }

        case .compact:
            // 单列经典自适应流
            connectionCapsuleButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(4)
                make.centerX.equalToSuperview()
                make.height.equalTo(34)
                make.leading.greaterThanOrEqualToSuperview().offset(SULayoutConstants.horizontalPadding)
                make.trailing.lessThanOrEqualToSuperview().offset(-SULayoutConstants.horizontalPadding)
            }
            topStatusBarView.snp.remakeConstraints { make in
                make.top.equalTo(connectionCapsuleButton.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(32)
            }
            topNoticeStackView.snp.remakeConstraints { make in
                make.top.equalTo(topStatusBarView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            petContainerView.snp.remakeConstraints { make in
                make.top.equalTo(topNoticeStackView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(SULayoutConstants.petContainerHeight)
            }
            gaugeView.snp.remakeConstraints { make in
                make.top.equalTo(petContainerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(SULayoutConstants.gaugeViewHeight)
            }
            let compactPillTop: CGFloat = isReliefPillExpanded ? 12 : 0
            let compactPillHeight: CGFloat = isReliefPillExpanded ? 46 : 0
            reliefQuickPillView.snp.remakeConstraints { make in
                make.top.equalTo(gaugeView.snp.bottom).offset(compactPillTop)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
                make.height.equalTo(compactPillHeight)
            }
            calibrateButton.snp.remakeConstraints { make in
                make.top.equalTo(reliefQuickPillView.snp.bottom).offset(14)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
                make.height.equalTo(SULayoutConstants.primaryButtonHeight)
                make.bottom.equalTo(contentView.snp.bottom).offset(-SULayoutConstants.sectionSpacing)
            }
        }
    }
}
