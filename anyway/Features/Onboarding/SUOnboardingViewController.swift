//
//  SUOnboardingViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit
import CoreMotion

/// 首次启动引导流控制器 —— 包含产品概念、权限申请说明、佩戴引导与校准教学
final class SUOnboardingViewController: SUBaseViewController {

    var onOnboardingCompleted: (() -> Void)?

    private var currentPage: Int = 0

    private struct PageData {
        let title: String
        let subtitle: String
        let iconName: String
        let buttonTitle: String
    }

    private let pages: [PageData] = [
        PageData(
            title: "让 AirPods 成为你的脊椎守护兽",
            subtitle: "借助 AirPods 内置的空间运动传感器，实时感知颈椎倾斜角度，告别乌龟颈与富贵包。",
            iconName: "airpodspro",
            buttonTitle: "了解核心原理"
        ),
        PageData(
            title: "需要运动传感器权限",
            subtitle: "SpineUp 需要访问头部运动数据以计算坐姿角度。所有姿态数据均在设备本地实时计算，绝不上传云端。",
            iconName: "hand.raised.badge.shield.half.filled",
            buttonTitle: "授权并继续"
        ),
        PageData(
            title: "戴上耳机，一键端坐校准",
            subtitle: "戴上耳机端坐好，轻点校准按钮即可确定你的自然基准零点。低头玩手机或驼背摸鱼时，宠物会变成软泥怪提醒你！",
            iconName: "figure.stand",
            buttonTitle: "开启我的桌宠"
        )
    ]

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemBlue
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .systemBlue
        pc.pageIndicatorTintColor = .systemGray4
        pc.isUserInteractionEnabled = false
        return pc
    }()

    private let actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        let button = UIButton(configuration: config)
        return button
    }()

    override func setupSubviews() {
        super.setupSubviews()
        view.backgroundColor = .systemBackground

        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(pageControl)
        view.addSubview(actionButton)

        pageControl.numberOfPages = pages.count
        updatePageContent()
    }

    override func setupConstraints() {
        super.setupConstraints()

        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-80)
            make.width.height.equalTo(120)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
        }

        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(actionButton.snp.top).offset(-SULayoutConstants.sectionSpacing)
            make.centerX.equalToSuperview()
        }

        actionButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
            make.height.equalTo(SULayoutConstants.primaryButtonHeight)
        }
    }

    override func setupBindings() {
        super.setupBindings()
        actionButton.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)
    }

    private func updatePageContent() {
        let data = pages[currentPage]
        let config = UIImage.SymbolConfiguration(pointSize: 90, weight: .regular)
        iconImageView.image = UIImage(systemName: data.iconName, withConfiguration: config)
        titleLabel.text = data.title
        subtitleLabel.text = data.subtitle
        actionButton.setTitle(data.buttonTitle, for: .normal)
        pageControl.currentPage = currentPage
    }

    @objc private func didTapAction() {
        if currentPage == 1 {
            // 触发系统传感器权限弹窗 (通过访问 CMHeadphoneMotionManager)
            let manager = CMHeadphoneMotionManager()
            if manager.isDeviceMotionAvailable {
                manager.startDeviceMotionUpdates(to: .main) { _, _ in
                    manager.stopDeviceMotionUpdates()
                }
            }
        }

        if currentPage < pages.count - 1 {
            currentPage += 1
            UIView.transition(with: view, duration: 0.35, options: .transitionCrossDissolve, animations: {
                self.updatePageContent()
            })
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        SUUserDefaultsManager.shared.hasCompletedOnboarding = true
        onOnboardingCompleted?()
        dismiss(animated: true)
    }
}
