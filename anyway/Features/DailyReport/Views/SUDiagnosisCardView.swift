//
//  SUDiagnosisCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 今日骨气病历单卡片 —— 包含诊断结论、趣味医学处方与宠物拟人寄语
final class SUDiagnosisCardView: UIView {

    private let container: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let cardHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("diagnosis_card_title", default: "《今日骨气病历单》")
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let headerIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        iv.image = UIImage(systemName: "cross.case.fill", withConfiguration: config)
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let diagnosisTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .systemRed
        label.numberOfLines = 0
        return label
    }()

    private let prescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let petQuoteBubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let petIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let petQuoteLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
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
        container.addSubview(headerIconImageView)
        container.addSubview(cardHeaderLabel)
        container.addSubview(diagnosisTitleLabel)
        container.addSubview(prescriptionLabel)
        container.addSubview(petQuoteBubbleView)
        petQuoteBubbleView.addSubview(petIconImageView)
        petQuoteBubbleView.addSubview(petQuoteLabel)

        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerIconImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(18)
            make.size.equalTo(18)
        }

        cardHeaderLabel.snp.makeConstraints { make in
            make.centerY.equalTo(headerIconImageView.snp.centerY)
            make.leading.equalTo(headerIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-18)
        }

        diagnosisTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(cardHeaderLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(18)
        }

        prescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(diagnosisTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(18)
        }

        petQuoteBubbleView.snp.makeConstraints { make in
            make.top.equalTo(prescriptionLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().offset(-18)
        }

        petIconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(18)
        }

        petQuoteLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(petIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    func configure(with report: SUDailyReport) {
        let diagFormat = SULocalized("clinical_diagnosis", default: "临床诊断：%@")
        diagnosisTitleLabel.text = String(format: diagFormat, report.diagnosisTitle)
        prescriptionLabel.text = report.doctorPrescription

        let persona = report.persona
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        petIconImageView.image = UIImage(systemName: persona.iconSystemName, withConfiguration: config)

        let tint: UIColor
        switch persona {
        case .worker: tint = .systemOrange
        case .cat: tint = .systemPurple
        case .coach: tint = .systemGreen
        }
        petIconImageView.tintColor = tint

        let quoteFormat = SULocalized("pet_quote_format", default: "%@寄语：「%@」")
        petQuoteLabel.text = String(format: quoteFormat, persona.displayName, report.personaComment)
    }

    /// 动态刷新多语言文案
    func refreshLocalizedStrings() {
        cardHeaderLabel.text = SULocalized("diagnosis_card_title", default: "《今日骨气病历单》")
    }
}
