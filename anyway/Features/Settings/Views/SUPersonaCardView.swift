//
//  SUPersonaCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 宠物人格选择卡片 —— 清新简约、原生 SF 图标、带选中微反馈与边框高亮
final class SUPersonaCardView: UIView {

    let persona: SUPetPersona
    var onSelected: ((SUPetPersona) -> Void)?

    private let containerCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.clear.cgColor
        return view
    }()

    private let iconContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
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
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        iv.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    init(persona: SUPetPersona) {
        self.persona = persona
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerCard)
        containerCard.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        containerCard.addSubview(titleLabel)
        containerCard.addSubview(subtitleLabel)
        containerCard.addSubview(descriptionLabel)
        containerCard.addSubview(checkmarkImageView)

        containerCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconContainer.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
            make.size.equalTo(40)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }

        checkmarkImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.size.equalTo(22)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-8)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainer.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-14)
        }

        // 配置数据与图标
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        iconImageView.image = UIImage(systemName: persona.iconSystemName, withConfiguration: config)
        titleLabel.text = persona.displayName
        subtitleLabel.text = persona.subtitle
        descriptionLabel.text = persona.description

        let tint = colorForPersona(persona)
        iconContainer.backgroundColor = tint.withAlphaComponent(0.15)
        iconImageView.tintColor = tint

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    private func colorForPersona(_ persona: SUPetPersona) -> UIColor {
        switch persona {
        case .worker: return .systemOrange
        case .cat: return .systemPurple
        case .coach: return .systemGreen
        }
    }

    func setSelected(_ isSelected: Bool) {
        checkmarkImageView.isHidden = !isSelected
        let tint = colorForPersona(persona)

        if isSelected {
            containerCard.layer.borderColor = tint.cgColor
            containerCard.backgroundColor = tint.withAlphaComponent(0.06)
            checkmarkImageView.tintColor = tint
        } else {
            containerCard.layer.borderColor = UIColor.clear.cgColor
            containerCard.backgroundColor = .secondarySystemGroupedBackground
        }
    }

    @objc private func handleTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.transform = .identity
            }
        }
        onSelected?(persona)
    }
}
