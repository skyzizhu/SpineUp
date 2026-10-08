//
//  SUGradeBannerCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 战报顶部骨气等级勋章卡片 —— 清新简约大气、原生 SF 图标、动态着色
final class SUGradeBannerCardView: UIView {

    private let containerCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let badgePill: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 28
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let gradeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .heavy)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let scoreTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textAlignment = .right
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
        addSubview(containerCard)
        containerCard.addSubview(badgePill)
        badgePill.addSubview(gradeLabel)
        containerCard.addSubview(titleLabel)
        containerCard.addSubview(subtitleLabel)
        containerCard.addSubview(scoreTagLabel)

        containerCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        badgePill.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
            make.size.equalTo(56)
        }

        gradeLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalTo(badgePill.snp.trailing).offset(14)
            make.trailing.lessThanOrEqualTo(scoreTagLabel.snp.leading).offset(-8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalToSuperview().offset(-18)
            make.bottom.equalToSuperview().offset(-16)
        }

        scoreTagLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
        }
    }

    func configure(with session: SUPostureSession) {
        gradeLabel.text = session.grade
        titleLabel.text = session.gradeTitle
        scoreTagLabel.text = "\(session.score) 分"

        let ratioPercent = Int(session.uprightRatio * 100)
        subtitleLabel.text = "端正挺拔率 \(ratioPercent)% · 挺拔专注 \(session.formattedUprightTime)"

        let tintColor: UIColor
        switch session.grade {
        case "S": tintColor = .systemGreen
        case "A": tintColor = .systemBlue
        case "B": tintColor = .systemOrange
        default:  tintColor = .systemRed
        }

        badgePill.backgroundColor = tintColor
        scoreTagLabel.textColor = tintColor
    }
}
