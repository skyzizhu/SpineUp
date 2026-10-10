//
//  SUWeeklyMetricsGridView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 周度 6 大核心指标卡片矩阵
final class SUWeeklyMetricsGridView: UIView {

    private let gridStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }()

    private let row1StackView = UIStackView()
    private let row2StackView = UIStackView()
    private let row3StackView = UIStackView()

    // 6 个单项指标卡片
    private let wearTimeCard = SUWeeklyMetricItemView(iconName: "clock.fill", iconColor: .systemBlue, titleKey: "weekly_metric_wear", defaultTitle: "累计监测")
    private let alleviatedCard = SUWeeklyMetricItemView(iconName: "leaf.fill", iconColor: .systemGreen, titleKey: "weekly_metric_alleviated", defaultTitle: "协助减负")
    private let fatigueCard = SUWeeklyMetricItemView(iconName: "exclamationmark.triangle.fill", iconColor: .systemOrange, titleKey: "weekly_metric_fatigue", defaultTitle: "疲劳塌陷期")
    private let riskCard = SUWeeklyMetricItemView(iconName: "shield.checkerboard", iconColor: .systemPurple, titleKey: "weekly_metric_risk", defaultTitle: "富贵包风险")
    private let loadCard = SUWeeklyMetricItemView(iconName: "scalemass.fill", iconColor: .systemRed, titleKey: "weekly_metric_load", defaultTitle: "累计抗压")
    private let coinsCard = SUWeeklyMetricItemView(iconName: "bolt.ring.closed", iconColor: .systemYellow, titleKey: "weekly_metric_coins", defaultTitle: "获得能量")

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(gridStackView)

        [row1StackView, row2StackView, row3StackView].forEach { row in
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 10
            gridStackView.addArrangedSubview(row)
        }

        row1StackView.addArrangedSubview(wearTimeCard)
        row1StackView.addArrangedSubview(alleviatedCard)

        row2StackView.addArrangedSubview(fatigueCard)
        row2StackView.addArrangedSubview(riskCard)

        row3StackView.addArrangedSubview(loadCard)
        row3StackView.addArrangedSubview(coinsCard)
    }

    private func setupConstraints() {
        gridStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with report: SUWeeklyReport) {
        wearTimeCard.configure(value: String(format: "%.1f", report.totalWearHours), unit: SULocalized("unit_hours", default: "小时"))
        alleviatedCard.configure(value: String(format: "%.1f", report.alleviatedLoadKg), unit: "kg")
        fatigueCard.configure(value: "\(report.fatigueHotspotHour):00", unit: SULocalized("unit_hotspot", default: "高发期"))
        riskCard.configure(value: "\(report.dowagerHumpRisk)%", unit: SULocalized("unit_low_risk", default: "低危区"))
        loadCard.configure(value: String(format: "%.1f", report.accumulatedLoadKg), unit: "kg")
        coinsCard.configure(value: "+\(report.coinsEarned)", unit: SULocalized("unit_coins", default: "能量币"))
    }
}

/// 单个周指标项小卡片
final class SUWeeklyMetricItemView: UIView {

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()

    init(iconName: String, iconColor: UIColor, titleKey: String, defaultTitle: String) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = SULayoutConstants.cornerRadiusMedium
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.03
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        iconImageView.tintColor = iconColor
        iconImageView.contentMode = .scaleAspectFit

        titleLabel.text = SULocalized(titleKey, default: defaultTitle)
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        valueLabel.font = .systemFont(ofSize: 22, weight: .heavy)
        valueLabel.textColor = .label

        unitLabel.font = .systemFont(ofSize: 12, weight: .bold)
        unitLabel.textColor = .tertiaryLabel

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView.snp.centerY)
            make.leading.equalTo(iconImageView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-8)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        unitLabel.snp.makeConstraints { make in
            make.bottom.equalTo(valueLabel.snp.bottom).offset(-2)
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0 && bounds.height > 0 {
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: SULayoutConstants.cornerRadiusMedium
            ).cgPath
        }
    }

    func configure(value: String, unit: String) {
        valueLabel.text = value
        unitLabel.text = unit
    }
}
