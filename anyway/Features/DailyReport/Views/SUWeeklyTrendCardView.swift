//
//  SUWeeklyTrendCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 7 天体态趋势分布柱状图卡片
final class SUWeeklyTrendCardView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("weekly_trend_title", default: "7 天体态趋势分布")
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("weekly_trend_subtitle", default: "柱状高低反映每日佩戴时长，高亮周度最佳日")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let chartStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 8
        return stack
    }()

    // 图例栏
    private let legendStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.spacing = 16
        return stack
    }()

    private var columnViews: [SUWeeklyColumnView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0 && bounds.height > 0 {
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: SULayoutConstants.cornerRadiusLarge
            ).cgPath
        }
    }

    private func setupCard() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 16
    }

    private func setupSubviews() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(chartStackView)
        addSubview(legendStackView)
        setupLegends()

        // 预先创建固定 7 列柱状图，避免每次 configure 时反复销毁和重建 View 及约束
        for _ in 0..<7 {
            let col = SUWeeklyColumnView()
            chartStackView.addArrangedSubview(col)
            columnViews.append(col)
        }
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(20)
        }

        chartStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(140)
        }

        legendStackView.snp.makeConstraints { make in
            make.top.equalTo(chartStackView.snp.bottom).offset(18)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-18)
        }
    }

    private func setupLegends() {
        legendStackView.addArrangedSubview(makeLegendItem(color: .systemGreen, text: SULocalized("legend_upright", default: "挺拔端正")))
        legendStackView.addArrangedSubview(makeLegendItem(color: .systemOrange, text: SULocalized("legend_slump", default: "低头前倾")))
        legendStackView.addArrangedSubview(makeLegendItem(color: .systemYellow, text: SULocalized("legend_best", default: "🏆 最佳日")))
    }

    private func makeLegendItem(color: UIColor, text: String) -> UIView {
        let container = UIView()
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 4

        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 11, weight: .bold)
        lbl.textColor = .secondaryLabel

        container.addSubview(dot)
        container.addSubview(lbl)

        dot.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(8)
        }

        lbl.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(5)
            make.trailing.top.bottom.equalToSuperview()
        }

        return container
    }

    func configure(with items: [SUWeeklyDailyBarItem]) {
        let maxDuration = items.map { $0.totalDurationSec }.max() ?? 18000.0
        let baseMax = max(maxDuration, 1.0)

        for (index, item) in items.prefix(7).enumerated() {
            guard index < columnViews.count else { break }
            columnViews[index].configure(item: item, baseMax: baseMax)
        }
    }
}

// MARK: - 可复用高性能柱状单列组件
final class SUWeeklyColumnView: UIView {

    private let crownImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "crown.fill")
        iv.tintColor = .systemYellow
        iv.contentMode = .scaleAspectFit
        iv.alpha = 0.0
        return iv
    }()

    private let barContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.4)
        view.layer.cornerRadius = 6
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()

    private let uprightBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.85)
        return view
    }()

    private let slumpBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemOrange
        return view
    }()

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(crownImageView)
        addSubview(barContainer)
        barContainer.addSubview(slumpBar)
        barContainer.addSubview(uprightBar)
        addSubview(dayLabel)
        addSubview(scoreLabel)

        crownImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(12)
        }

        barContainer.snp.makeConstraints { make in
            make.top.equalTo(crownImageView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.width.equalTo(16)
            make.bottom.equalTo(dayLabel.snp.top).offset(-8)
        }

        uprightBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(10)
        }

        slumpBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(uprightBar.snp.top)
            make.height.equalTo(10)
        }

        dayLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(scoreLabel.snp.top).offset(-2)
        }

        scoreLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    func configure(item: SUWeeklyDailyBarItem, baseMax: Double) {
        crownImageView.alpha = item.isBestDay ? 1.0 : 0.0

        uprightBar.backgroundColor = item.isBestDay ? .systemGreen : UIColor.systemGreen.withAlphaComponent(0.85)
        slumpBar.backgroundColor = item.isBestDay ? UIColor.systemOrange.withAlphaComponent(0.7) : .systemOrange

        dayLabel.text = item.dayName
        dayLabel.font = .systemFont(ofSize: 11, weight: item.isBestDay ? .heavy : .medium)
        dayLabel.textColor = item.isBestDay ? .systemGreen : .secondaryLabel

        scoreLabel.text = "\(item.score)"

        let totalRatio = min(1.0, item.totalDurationSec / baseMax)
        let totalBarHeight = max(12.0, 70.0 * totalRatio)
        let uprightHeight = totalBarHeight * CGFloat(item.uprightRatio)
        let slumpHeight = max(0, totalBarHeight - uprightHeight)

        uprightBar.snp.updateConstraints { make in
            make.height.equalTo(uprightHeight)
        }

        slumpBar.snp.updateConstraints { make in
            make.height.equalTo(slumpHeight)
        }
    }
}
