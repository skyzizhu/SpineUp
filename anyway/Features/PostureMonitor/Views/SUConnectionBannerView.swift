//
//  SUConnectionBannerView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 耳机连接异常与优雅降级引导横幅 —— 清新简约大气、原生 SF 图标、动态操作 CTA、弹性展开收起
final class SUConnectionBannerView: UIView {

    private let container = SULiquidGlassView(
        cornerRadius: SULayoutConstants.cornerRadiusSmall,
        tintColor: UIColor.systemOrange.withAlphaComponent(0.12)
    )

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iv.image = UIImage(systemName: "headphones", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AirPods 未连接"
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "戴上支持空间音频的 AirPods，体态感知将自动恢复"
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12)
        let btn = UIButton(configuration: config)
        return btn
    }()

    private let textStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.distribution = .fill
        return stack
    }()

    private var currentState: SUHeadphoneConnectionState = .disconnected
    var onActionTapped: ((SUHeadphoneConnectionState) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(container)
        container.contentView.addSubview(iconImageView)
        container.contentView.addSubview(textStackView)

        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        textStackView.addArrangedSubview(actionButton)

        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(12)
            make.size.equalTo(24)
        }

        textStackView.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }

        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBanner))
        addGestureRecognizer(tap)
    }

    @objc private func didTapActionButton() {
        onActionTapped?(currentState)
    }

    @objc private func didTapBanner() {
        onActionTapped?(currentState)
    }

    func updateConnectionState(_ state: SUHeadphoneConnectionState) {
        self.currentState = state
        switch state {
        case .connected:
            hideAnimated()

        default:
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            iconImageView.image = UIImage(systemName: state.iconSystemName, withConfiguration: symbolConfig)
            iconImageView.tintColor = state.themeColor
            container.glassTintColor = state.themeColor.withAlphaComponent(0.12)

            titleLabel.text = state.displayTitle
            subtitleLabel.text = state.displaySubtitle

            if let btnTitle = state.actionButtonTitle {
                var config = actionButton.configuration ?? UIButton.Configuration.filled()
                config.baseBackgroundColor = state.themeColor
                config.baseForegroundColor = .white
                config.title = btnTitle
                let transformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = UIFont.systemFont(ofSize: 11.0, weight: .bold)
                    return outgoing
                }
                config.titleTextAttributesTransformer = transformer
                actionButton.configuration = config
                actionButton.isHidden = false
            } else {
                actionButton.isHidden = true
            }

            showAnimated()
        }
    }

    private func showAnimated() {
        guard isHidden || alpha == 0 else { return }
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
            self.superview?.layoutIfNeeded()
        }
    }

    private func hideAnimated() {
        guard !isHidden else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.isHidden = true
            self.superview?.layoutIfNeeded()
        })
    }
}
