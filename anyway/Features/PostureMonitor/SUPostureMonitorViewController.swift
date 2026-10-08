//
//  SUPostureMonitorViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit
import os

/// Tab 1: 核心姿态监测与桌宠主页
final class SUPostureMonitorViewController: SUBaseViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SpineUp · 体态守护兽"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private let statusCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusMedium
        view.layer.masksToBounds = true
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "戴上 AirPods 或使用下方模拟器调试"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let angleValueLabel: UILabel = {
        let label = UILabel()
        label.text = "0.0°"
        label.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        label.textColor = .systemGreen
        label.textAlignment = .center
        return label
    }()

    private let calibrateButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "一键校准基准坐姿"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        let button = UIButton(configuration: config)
        return button
    }()

    // 传感器服务依赖注入 (模拟器使用 Mock，真机使用 HeadphoneMotion)
    #if targetEnvironment(simulator)
    private let motionService: SUMotionServiceProtocol = SUMockMotionManager()
    #else
    private let motionService: SUMotionServiceProtocol = SUHeadphoneMotionManager()
    #endif

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = "实时监测"

        view.addSubview(titleLabel)
        view.addSubview(statusCardView)
        statusCardView.addSubview(angleValueLabel)
        statusCardView.addSubview(statusLabel)
        view.addSubview(calibrateButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(SULayoutConstants.verticalSpacing * 2)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        statusCardView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(200)
        }

        angleValueLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-18)
        }

        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(angleValueLabel.snp.bottom).offset(SULayoutConstants.smallSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.cardInternalPadding)
        }

        calibrateButton.snp.makeConstraints { make in
            make.top.equalTo(statusCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
            make.height.equalTo(SULayoutConstants.primaryButtonHeight)
        }
    }

    override func setupBindings() {
        super.setupBindings()

        calibrateButton.addTarget(self, action: #selector(didTapCalibrate), for: .touchUpInside)

        motionService.onReadingUpdated = { [weak self] reading in
            guard let self = self else { return }
            self.angleValueLabel.text = String(format: "%.1f°", reading.relativePitchDeg)

            switch reading.state {
            case .upright:
                self.angleValueLabel.textColor = .systemGreen
                self.statusLabel.text = "坐姿端正 · 宠物元气充盈中"
            case .slightSlump:
                self.angleValueLabel.textColor = .systemOrange
                self.statusLabel.text = "轻微前倾 · 宠物头上冒汗了"
            case .severeSlump:
                self.angleValueLabel.textColor = .systemRed
                self.statusLabel.text = "严重驼背！宠物被压扁求救中"
            case .calibrating:
                self.statusLabel.text = "正在校准中..."
            case .unknown:
                self.statusLabel.text = "等待耳机佩戴..."
            }
        }

        motionService.startMonitoring()
    }

    @objc private func didTapCalibrate() {
        motionService.calibrateBaseline()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    override func adaptLayoutForSize(_ size: CGSize) {
        super.adaptLayoutForSize(size)
        // 为 iPhone Duo 展开态留出响应钩子
        let isDualPane = size.width >= SULayoutConstants.duoSplitBreakpointWidth
        SULogger.ui.info("SUPostureMonitorViewController adaptLayout: isDualPane=\(isDualPane)")
    }
}
