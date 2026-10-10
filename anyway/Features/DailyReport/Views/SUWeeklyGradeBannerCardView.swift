//
//  SUWeeklyGradeBannerCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 周报综合健康评分与评级横幅
final class SUWeeklyGradeBannerCardView: UIView {

    private let gradientLayer = CAGradientLayer()

    private let weekRangeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("weekly_score_title", default: "周度体态健康综合评分")
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 52, weight: .black)
        label.textColor = .label
        return label
    }()

    private let scoreUnitLabel: UILabel = {
        let label = UILabel()
        label.text = "/ 100"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let gradeBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let gradeIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .heavy)
        iv.image = UIImage(systemName: "trophy.fill", withConfiguration: config)
        iv.tintColor = .systemGreen
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let gradeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .heavy)
        label.textColor = .systemGreen
        return label
    }()

    private let uprightRateBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let uprightRateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .systemBlue
        return label
    }()

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
        addSubview(weekRangeLabel)
        addSubview(titleLabel)
        addSubview(scoreLabel)
        addSubview(scoreUnitLabel)

        addSubview(gradeBadgeView)
        gradeBadgeView.addSubview(gradeIconImageView)
        gradeBadgeView.addSubview(gradeLabel)

        addSubview(uprightRateBadgeView)
        uprightRateBadgeView.addSubview(uprightRateLabel)
    }

    private func setupConstraints() {
        weekRangeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(weekRangeLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(20)
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
        }

        scoreUnitLabel.snp.makeConstraints { make in
            make.bottom.equalTo(scoreLabel.snp.bottom).offset(-10)
            make.leading.equalTo(scoreLabel.snp.trailing).offset(6)
        }

        gradeBadgeView.snp.makeConstraints { make in
            make.centerY.equalTo(scoreLabel.snp.centerY).offset(-14)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(28)
        }

        gradeIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }

        gradeLabel.snp.makeConstraints { make in
            make.leading.equalTo(gradeIconImageView.snp.trailing).offset(5)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        uprightRateBadgeView.snp.makeConstraints { make in
            make.top.equalTo(gradeBadgeView.snp.bottom).offset(8)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(28)
        }

        uprightRateLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with report: SUWeeklyReport) {
        weekRangeLabel.text = report.dateRangeText
        scoreLabel.text = "\(report.healthScore)"
        gradeLabel.text = report.gradeText
        uprightRateLabel.text = String(format: SULocalized("weekly_upright_fmt", default: "%.1f%% 挺拔率"), report.uprightPercentage)
    }
}
