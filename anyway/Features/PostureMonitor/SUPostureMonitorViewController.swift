//
//  SUPostureMonitorViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit
import os

/// Tab 1: 核心姿态监测与桌宠主页 —— 驱动宠物形态微动效、实时角度表盘与校准流转
final class SUPostureMonitorViewController: SUBaseViewController {

    private let viewModel: SUPostureMonitorViewModel

    // MARK: - 独立封装视图组件
    private let petContainerView = SUPetVisualContainerView()
    private let gaugeView = SUPostureGaugeView()

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

        // 挂载 SwiftUI 宠物容器子视图
        view.addSubview(petContainerView)
        petContainerView.attach(to: self)

        // 挂载角度负荷表盘
        view.addSubview(gaugeView)

        // 挂载校准按钮
        view.addSubview(calibrateButton)

        #if targetEnvironment(simulator)
        view.addSubview(debugPanelCard)
        debugPanelCard.addSubview(debugSliderLabel)
        debugPanelCard.addSubview(debugPitchSlider)
        #endif
    }

    override func setupConstraints() {
        super.setupConstraints()

        petContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(SULayoutConstants.verticalSpacing)
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

        #if targetEnvironment(simulator)
        debugPitchSlider.addTarget(self, action: #selector(didChangeDebugSlider(_:)), for: .valueChanged)
        #endif

        viewModel.onReadingUpdated = { [weak self] reading in
            guard let self = self else { return }
            self.gaugeView.configure(with: reading, connectionState: self.viewModel.connectionState)
        }

        viewModel.onPostureStateChanged = { [weak self] state in
            guard let self = self else { return }
            self.petContainerView.configure(with: state)
        }

        viewModel.onCalibrationProgress = { [weak self] progress in
            guard let self = self else { return }
            let percent = Int(progress * 100)
            self.calibrateButton.setTitle("校准中 \(percent)%", for: .normal)
        }

        viewModel.onCalibrationFinished = { [weak self] in
            guard let self = self else { return }
            self.calibrateButton.setTitle("一键端坐校准", for: .normal)
        }

        viewModel.startMonitoring()
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
            // iPhone Duo 展开态：宠物在左，仪表在右
            petContainerView.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(SULayoutConstants.verticalSpacing)
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
            // 单列经典流
            petContainerView.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(SULayoutConstants.verticalSpacing)
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
