//
//  SUDailyReportViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// Tab 2: 今日骨气病历单与战报
final class SUDailyReportViewController: SUBaseViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "今日骨气战报"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusMedium
        view.layer.masksToBounds = true
        return view
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "完成一次体态监测后\nAI 将为您生成专属《今日骨气病历单》"
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = "骨气战报"

        view.addSubview(titleLabel)
        view.addSubview(cardView)
        cardView.addSubview(subtitleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(SULayoutConstants.verticalSpacing * 2)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        cardView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(180)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(SULayoutConstants.cardInternalPadding)
        }
    }
}
