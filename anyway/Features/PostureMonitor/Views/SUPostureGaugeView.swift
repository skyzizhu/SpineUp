//
//  SUPostureGaugeView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 独立封装视图：坐姿角度仪表与物理负荷指示卡片
final class SUPostureGaugeView: UIView {

    private let containerCard = SULiquidGlassView(cornerRadius: SULayoutConstants.cornerRadiusMedium)

    private let connectionIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()

    private let connectionLabel: UILabel = {
        let label = UILabel()
        label.text = "AirPods 空间运动追踪中"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let angleTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("angle_title", default: "相对前倾角度")
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let angleValueLabel: UILabel = {
        let label = UILabel()
        label.text = "0.0°"
        label.font = UIFont.systemFont(ofSize: 38, weight: .heavy)
        label.textColor = .systemGreen
        label.textAlignment = .center
        return label
    }()

    private let loadValueLabel: UILabel = {
        let label = UILabel()
        label.text = "颈椎额外承重: 0.0 kg"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    private let angleProgressTrack: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemFill
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        return view
    }()

    private let angleProgressBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(containerCard)
        containerCard.contentView.addSubview(connectionIndicator)
        containerCard.contentView.addSubview(connectionLabel)
        containerCard.contentView.addSubview(angleTitleLabel)
        containerCard.contentView.addSubview(angleValueLabel)
        containerCard.contentView.addSubview(loadValueLabel)
        containerCard.contentView.addSubview(angleProgressTrack)
        angleProgressTrack.addSubview(angleProgressBar)
    }

    private func setupConstraints() {
        containerCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        connectionIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(SULayoutConstants.cardInternalPadding)
            make.leading.equalToSuperview().offset(SULayoutConstants.cardInternalPadding)
            make.width.height.equalTo(8)
        }

        connectionLabel.snp.makeConstraints { make in
            make.centerY.equalTo(connectionIndicator)
            make.leading.equalTo(connectionIndicator.snp.trailing).offset(6)
            make.trailing.lessThanOrEqualToSuperview().inset(SULayoutConstants.cardInternalPadding)
        }

        angleTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(connectionLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }

        angleValueLabel.snp.makeConstraints { make in
            make.top.equalTo(angleTitleLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
        }

        loadValueLabel.snp.makeConstraints { make in
            make.top.equalTo(angleValueLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
        }

        angleProgressTrack.snp.makeConstraints { make in
            make.top.equalTo(loadValueLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.cardInternalPadding)
            make.height.equalTo(6)
            make.bottom.equalToSuperview().offset(-SULayoutConstants.cardInternalPadding)
        }

        angleProgressBar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
    }

    /// 更新姿态读数与进度渲染
    func configure(with reading: SUPostureReading, connectionState: SUHeadphoneConnectionState) {
        let pitchDeg = max(0.0, reading.relativePitchDeg)
        angleValueLabel.text = String(format: "%.1f°", pitchDeg)
        let loadTitle = SULocalized("metrics_extra_load", default: "额外负荷")
        loadValueLabel.text = String(format: "%@: +%.1f kg", loadTitle, reading.extraLoadKg)

        // 颜色与状态
        let tintColor: UIColor
        switch reading.state {
        case .upright:
            tintColor = .systemGreen
        case .slightSlump:
            tintColor = .systemOrange
        case .severeSlump:
            tintColor = .systemRed
        case .calibrating, .unknown:
            tintColor = .systemGray
        }

        angleValueLabel.textColor = tintColor
        angleProgressBar.backgroundColor = tintColor

        // 进度条百分比 (0° ~ 45°)
        let maxAngle: Double = 45.0
        let ratio = min(1.0, max(0.0, pitchDeg / maxAngle))
        let totalWidth = angleProgressTrack.bounds.width > 0 ? angleProgressTrack.bounds.width : 260
        angleProgressBar.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(CGFloat(ratio) * totalWidth)
        }

        // 耳机状态
        switch connectionState {
        case .connected:
            connectionIndicator.backgroundColor = .systemGreen
            connectionLabel.text = SULocalized("sensor_tracking", default: "AirPods 空间运动追踪中")
        case .disconnected:
            connectionIndicator.backgroundColor = .systemOrange
            connectionLabel.text = SULocalized("banner_airpods_disconnected", default: "AirPods 未连接")
        case .unsupported:
            connectionIndicator.backgroundColor = .systemRed
            connectionLabel.text = SULocalized("banner_unsupported", default: "设备不支持运动传感器")
        }
    }

    /// 动态刷新多语言文案
    func refreshLocalizedStrings() {
        angleTitleLabel.text = SULocalized("angle_title", default: "相对前倾角度")
    }
}
