//
//  SUPracticeActionInfoCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 30 秒微操动作说明卡片 —— 包含动作名称、核心益处标签与采用专业悬挂缩进排版的步骤指引清单
final class SUPracticeActionInfoCardView: UIView {

    // MARK: - UI 控件
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.35)
        view.layer.cornerRadius = 18
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let actionTitleLabel: UILabel = {
        let label = UILabel()
        if let desc = UIFont.systemFont(ofSize: 17, weight: .heavy).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: desc, size: 0)
        } else {
            label.font = .systemFont(ofSize: 17, weight: .heavy)
        }
        label.textColor = .label
        return label
    }()

    private let actionTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11.5, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let instructionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(containerView)
        containerView.addSubview(actionTitleLabel)
        containerView.addSubview(actionTagLabel)
        containerView.addSubview(instructionsStackView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        actionTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(14)
        }

        actionTagLabel.snp.makeConstraints { make in
            make.centerY.equalTo(actionTitleLabel.snp.centerY)
            make.leading.equalTo(actionTitleLabel.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }

        instructionsStackView.snp.makeConstraints { make in
            make.top.equalTo(actionTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    // MARK: - 外部配置
    func configure(action: SUPracticeActionType) {
        actionTitleLabel.text = action.title
        actionTagLabel.text = action.tagText

        instructionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (idx, step) in action.instructions.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.alignment = .top
            rowStack.spacing = 8

            let badgeView = UIView()
            badgeView.backgroundColor = action.themeColor.withAlphaComponent(0.12)
            badgeView.layer.cornerRadius = 8.5
            badgeView.layer.cornerCurve = .continuous
            badgeView.snp.makeConstraints { make in
                make.size.equalTo(17)
            }

            let badgeNumLabel = UILabel()
            badgeNumLabel.font = .systemFont(ofSize: 10, weight: .bold)
            badgeNumLabel.textColor = action.themeColor
            badgeNumLabel.textAlignment = .center
            badgeNumLabel.text = "\(idx + 1)"
            badgeView.addSubview(badgeNumLabel)
            badgeNumLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }

            let textLabel = UILabel()
            textLabel.numberOfLines = 0
            textLabel.font = .systemFont(ofSize: 12.5, weight: .regular)
            textLabel.textColor = .secondaryLabel
            textLabel.text = step

            rowStack.addArrangedSubview(badgeView)
            rowStack.addArrangedSubview(textLabel)
            instructionsStackView.addArrangedSubview(rowStack)
        }
    }
}
