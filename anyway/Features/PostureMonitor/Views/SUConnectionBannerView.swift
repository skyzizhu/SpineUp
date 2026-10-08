//
//  SUConnectionBannerView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 耳机连接异常与优雅降级引导横幅 —— 清新简约大气、原生 SF 图标、弹性展开收起
final class SUConnectionBannerView: UIView {

    private let container = SULiquidGlassView(
        cornerRadius: SULayoutConstants.cornerRadiusSmall,
        tintColor: UIColor.systemOrange.withAlphaComponent(0.12)
    )

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        iv.image = UIImage(systemName: "headphones", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AirPods 未连接或已摘下"
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(container)
        container.contentView.addSubview(iconImageView)
        container.contentView.addSubview(titleLabel)
        container.contentView.addSubview(subtitleLabel)

        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(22)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    func updateConnectionState(_ state: SUHeadphoneConnectionState) {
        switch state {
        case .connected:
            hideAnimated()
        case .disconnected:
            titleLabel.text = SULocalized("banner_airpods_disconnected", default: "AirPods 未连接或已摘下")
            subtitleLabel.text = SULocalized("banner_airpods_subtitle", default: "请佩戴支持运动感知的 AirPods，系统将自动唤醒感知")
            showAnimated()
        case .unsupported:
            titleLabel.text = SULocalized("banner_unsupported", default: "当前设备不支持耳机动作感知")
            subtitleLabel.text = SULocalized("banner_unsupported_subtitle", default: "需要 AirPods Pro / Max / 3代+ / Beats Fit Pro 支持")
            showAnimated()
        }
    }

    private func showAnimated() {
        guard isHidden || alpha == 0 else { return }
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }
    }

    private func hideAnimated() {
        guard !isHidden else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { _ in
            self.isHidden = true
        }
    }
}
