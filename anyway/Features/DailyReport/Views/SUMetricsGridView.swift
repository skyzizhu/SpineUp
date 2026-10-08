//
//  SUMetricsGridView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 战报 4 宫格核心体态指标视图 —— 原生 SF 图标、卡片式留白排版
final class SUMetricsGridView: UIView {

    private let topRowStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }()

    private let bottomRowStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }()

    private let uprightBox = SUMetricCardBoxView(icon: "clock.fill", title: SULocalized("metrics_upright_ratio", default: "挺拔专注"), tint: .systemGreen)
    private let slumpBox = SUMetricCardBoxView(icon: "exclamationmark.triangle.fill", title: SULocalized("metrics_longest_streak", default: "低头疲劳"), tint: .systemOrange)
    private let violationsBox = SUMetricCardBoxView(icon: "hand.raised.fill", title: SULocalized("metrics_violations", default: "违规频次"), tint: .systemRed)
    private let loadBox = SUMetricCardBoxView(icon: "scalemass.fill", title: SULocalized("metrics_extra_load", default: "颈椎额外负荷"), tint: .systemIndigo)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(topRowStack)
        addSubview(bottomRowStack)

        topRowStack.addArrangedSubview(uprightBox)
        topRowStack.addArrangedSubview(slumpBox)

        bottomRowStack.addArrangedSubview(violationsBox)
        bottomRowStack.addArrangedSubview(loadBox)

        topRowStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(88)
        }

        bottomRowStack.snp.makeConstraints { make in
            make.top.equalTo(topRowStack.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(88)
        }
    }

    func configure(with session: SUPostureSession) {
        uprightBox.setValue(session.formattedUprightTime)
        slumpBox.setValue(session.formattedSlumpTime)
        violationsBox.setValue("\(session.violationsCount) 次")
        loadBox.setValue(String(format: "%.1f kg", session.accumulatedExtraLoadKg))
    }
}

// MARK: - 辅助子组件：单卡片指标盒
final class SUMetricCardBoxView: UIView {

    private let container: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    init(icon: String, title: String, tint: UIColor) {
        super.init(frame: .zero)

        addSubview(container)
        container.addSubview(iconImageView)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)

        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.image = UIImage(systemName: icon, withConfiguration: config)
        iconImageView.tintColor = tint
        titleLabel.text = title

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.size.equalTo(18)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView.snp.centerY)
            make.leading.equalTo(iconImageView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-10)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }
}
