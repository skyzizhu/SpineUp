//
//  SUShareCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 高颜值极简社交分享卡片 —— 清新简约大气、严格使用原生 SF 图标、支持无损导出 UIImage
final class SUShareCardView: UIView {

    private let cardBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        return view
    }()

    // MARK: - 头部品牌区
    private let brandHeaderStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        iv.image = UIImage(systemName: "figure.walk", withConfiguration: config)
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let brandTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "SpineUp"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .right
        return label
    }()

    // MARK: - 核心评级徽章
    private let gradeBadgeCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let gradeLetterLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 44, weight: .heavy)
        label.textColor = .systemBlue
        label.textAlignment = .center
        return label
    }()

    private let gradeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let scorePillLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemBlue
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }()

    // MARK: - 三指标统计栏
    private let statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()

    private let uprightStatView = SUShareStatBoxView(icon: "clock.fill", title: SULocalized("share_stat_upright", default: "挺拔专注"), tint: .systemGreen)
    private let ratioStatView = SUShareStatBoxView(icon: "chart.pie.fill", title: SULocalized("share_stat_ratio", default: "端正率"), tint: .systemBlue)
    private let extraLoadStatView = SUShareStatBoxView(icon: "scalemass.fill", title: SULocalized("share_stat_load", default: "额外负荷"), tint: .systemOrange)

    // MARK: - 趣味换算栏
    private let metaphorCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemOrange.withAlphaComponent(0.08)
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let metaphorIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iv.image = UIImage(systemName: "square.stack.3d.down.forward.fill", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let metaphorTextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemOrange
        label.numberOfLines = 0
        return label
    }()

    // MARK: - AI 诊断与宠物评语
    private let diagnosisCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let diagnosisTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let personaCommentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 底部防伪标识
    private let footerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()

    private let headphonesIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        iv.image = UIImage(systemName: "headphones", withConfiguration: config)
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let footerTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Protected by AirPods Spatial Motion & SpineUp AI"
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .tertiaryLabel
        return label
    }()

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 340, height: 530))
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(cardBackgroundView)
        cardBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Header
        cardBackgroundView.addSubview(brandHeaderStack)
        brandHeaderStack.addArrangedSubview(logoImageView)
        brandHeaderStack.addArrangedSubview(brandTitleLabel)
        cardBackgroundView.addSubview(dateLabel)

        brandHeaderStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(18)
        }

        logoImageView.snp.makeConstraints { make in
            make.size.equalTo(20)
        }

        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(brandHeaderStack.snp.centerY)
            make.trailing.equalToSuperview().offset(-18)
        }

        // Grade Badge
        cardBackgroundView.addSubview(gradeBadgeCard)
        gradeBadgeCard.addSubview(gradeLetterLabel)
        gradeBadgeCard.addSubview(gradeTitleLabel)
        gradeBadgeCard.addSubview(scorePillLabel)

        gradeBadgeCard.snp.makeConstraints { make in
            make.top.equalTo(brandHeaderStack.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(72)
        }

        gradeLetterLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(52)
        }

        gradeTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(gradeLetterLabel.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(16)
        }

        scorePillLabel.snp.makeConstraints { make in
            make.leading.equalTo(gradeTitleLabel.snp.leading)
            make.top.equalTo(gradeTitleLabel.snp.bottom).offset(4)
            make.width.equalTo(58)
            make.height.equalTo(20)
        }

        // Stats Box
        cardBackgroundView.addSubview(statsStackView)
        statsStackView.addArrangedSubview(uprightStatView)
        statsStackView.addArrangedSubview(ratioStatView)
        statsStackView.addArrangedSubview(extraLoadStatView)

        statsStackView.snp.makeConstraints { make in
            make.top.equalTo(gradeBadgeCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(68)
        }

        // Metaphor Card
        cardBackgroundView.addSubview(metaphorCardView)
        metaphorCardView.addSubview(metaphorIconImageView)
        metaphorCardView.addSubview(metaphorTextLabel)

        metaphorCardView.snp.makeConstraints { make in
            make.top.equalTo(statsStackView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(44)
        }

        metaphorIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }

        metaphorTextLabel.snp.makeConstraints { make in
            make.leading.equalTo(metaphorIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        // Diagnosis & Comment
        cardBackgroundView.addSubview(diagnosisCardView)
        diagnosisCardView.addSubview(diagnosisTitleLabel)
        diagnosisCardView.addSubview(personaCommentLabel)

        diagnosisCardView.snp.makeConstraints { make in
            make.top.equalTo(metaphorCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
        }

        diagnosisTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        personaCommentLabel.snp.makeConstraints { make in
            make.top.equalTo(diagnosisTitleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-12)
        }

        // Footer
        cardBackgroundView.addSubview(footerStack)
        footerStack.addArrangedSubview(headphonesIconImageView)
        footerStack.addArrangedSubview(footerTextLabel)

        headphonesIconImageView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }

        footerStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-14)
            make.centerX.equalToSuperview()
        }
    }

    /// 配置战报数据
    func configure(with report: SUDailyReport) {
        let session = report.session
        dateLabel.text = report.dateFormattedText

        gradeLetterLabel.text = session.grade
        gradeTitleLabel.text = session.gradeTitle
        scorePillLabel.text = String(format: SULocalized("score_unit", default: "%d分"), session.score)

        // 着色适配
        let tintColor: UIColor
        switch session.grade {
        case "S": tintColor = .systemGreen
        case "A": tintColor = .systemBlue
        case "B": tintColor = .systemOrange
        default:  tintColor = .systemRed
        }
        gradeLetterLabel.textColor = tintColor
        scorePillLabel.backgroundColor = tintColor

        uprightStatView.configure(value: session.formattedUprightTime)
        ratioStatView.configure(value: "\(Int(session.uprightRatio * 100))%")
        extraLoadStatView.configure(value: String(format: "%.1fkg", session.accumulatedExtraLoadKg))

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        metaphorIconImageView.image = UIImage(systemName: report.equivalentItem.iconSystemName, withConfiguration: config)
        metaphorTextLabel.text = report.equivalentItem.descriptionText

        let diagFormat = SULocalized("clinical_diagnosis", default: "诊断：%@")
        diagnosisTitleLabel.text = String(format: diagFormat, report.diagnosisTitle)
        personaCommentLabel.text = "「\(report.personaComment)」"
    }

    /// 将卡片精准无损栅格化为高质量 UIImage
    func renderAsImage() -> UIImage {
        layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            self.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - 辅助子组件：分享卡片单项指标小盒
final class SUShareStatBoxView: UIView {
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    init(icon: String, title: String, tint: UIColor) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
        layer.cornerCurve = .continuous

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)

        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        iconImageView.image = UIImage(systemName: icon, withConfiguration: config)
        iconImageView.tintColor = tint
        titleLabel.text = title

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.size.equalTo(14)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(3)
            make.leading.trailing.equalToSuperview().inset(4)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(value: String) {
        valueLabel.text = value
    }
}
