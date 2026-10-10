//
//  SUPracticeTopNavBarView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 30 秒微操顶部导航栏组件 —— 包含退出关闭、步骤指示胶囊与多模态感知切换胶囊
final class SUPracticeTopNavBarView: UIView {

    // MARK: - 回调
    var onCloseTapped: (() -> Void)?
    var onModeToggleTapped: (() -> Void)?

    // MARK: - UI 控件
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        btn.tintColor = .secondaryLabel
        btn.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.85)
        btn.layer.cornerRadius = 16
        btn.layer.cornerCurve = .continuous
        return btn
    }()

    private let stepBadgePill: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        view.layer.cornerRadius = 13
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let stepBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .systemOrange
        label.textAlignment = .center
        return label
    }()

    private let modeTogglePillButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.85)
        btn.layer.cornerRadius = 14
        btn.layer.cornerCurve = .continuous
        return btn
    }()

    private let modeDotView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 3.5
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let modeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11.5, weight: .semibold)
        label.textColor = .label
        label.text = SULocalized("practice_mode_headphone", default: "🎧 耳机体态感知")
        return label
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

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 34)
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(closeButton)
        addSubview(stepBadgePill)
        stepBadgePill.addSubview(stepBadgeLabel)

        addSubview(modeTogglePillButton)
        modeTogglePillButton.addSubview(modeDotView)
        modeTogglePillButton.addSubview(modeTitleLabel)

        closeButton.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(32)
        }

        stepBadgePill.snp.makeConstraints { make in
            make.leading.equalTo(closeButton.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.height.equalTo(26)
        }

        stepBadgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10))
        }

        modeTogglePillButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(stepBadgePill.snp.trailing).offset(8)
            make.height.equalTo(28)
        }

        modeDotView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(7)
        }

        modeTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(modeDotView.snp.trailing).offset(5)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }

        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        modeTogglePillButton.addTarget(self, action: #selector(didTapMode), for: .touchUpInside)
    }

    @objc private func didTapClose() {
        onCloseTapped?()
    }

    @objc private func didTapMode() {
        onModeToggleTapped?()
    }

    // MARK: - 外部配置接口
    func configure(stepText: String, themeColor: UIColor) {
        stepBadgeLabel.text = stepText
        stepBadgeLabel.textColor = themeColor
        stepBadgePill.backgroundColor = themeColor.withAlphaComponent(0.12)
    }

    func setModeStatus(title: String, dotColor: UIColor) {
        modeTitleLabel.text = title
        modeDotView.backgroundColor = dotColor
    }
}
