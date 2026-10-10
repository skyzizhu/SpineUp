//
//  SULegalListViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/10.
//

import UIKit
import SnapKit

/// 法律信息与免责声明列表页面 —— 展示健康免责声明、隐私政策与服务条款三个入口
final class SULegalListViewController: SUBaseViewController {

    // MARK: - 可滑动容器
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let contentView = UIView()

    // MARK: - 提示说明文案
    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("legal_list_hint", default: "SpineUp 重视您的身体健康与数据隐私安全，请点击查阅以下官方合规声明与服务协议。")
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 列表卡片容器
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.03
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 16
        return view
    }()

    // MARK: - 三个法律入口行
    private let medicalRowView = SULegalItemRowView(
        title: SULocalized("legal_item_medical_title", default: "健康与医疗免责声明"),
        subtitle: SULocalized("legal_item_medical_desc", default: "本应用非医疗器械，不提供医疗诊断或替代专业医嘱"),
        iconSystemName: "cross.case.fill",
        iconBackground: .systemRed
    )

    private let separator1: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let privacyRowView = SULegalItemRowView(
        title: SULocalized("legal_item_privacy_title", default: "隐私政策"),
        subtitle: SULocalized("legal_item_privacy_desc", default: "100% 传感器端侧本地运算，零个人追踪与无感安全体验"),
        iconSystemName: "hand.raised.fill",
        iconBackground: .systemBlue
    )

    private let separator2: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let termsRowView = SULegalItemRowView(
        title: SULocalized("legal_item_terms_title", default: "用户服务条款"),
        subtitle: SULocalized("legal_item_terms_desc", default: "软件使用许可协议、免责条款与知识产权规范"),
        iconSystemName: "doc.plaintext.fill",
        iconBackground: .systemIndigo
    )

    // MARK: - 底部版权声明
    private let copyrightLabel: UILabel = {
        let label = UILabel()
        label.text = "SpineUp · Ergonomic Posture Guard"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
    }

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = SULocalized("legal_list_title", default: "法律信息与免责声明")

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(hintLabel)
        contentView.addSubview(cardView)

        cardView.addSubview(medicalRowView)
        cardView.addSubview(separator1)
        cardView.addSubview(privacyRowView)
        cardView.addSubview(separator2)
        cardView.addSubview(termsRowView)

        contentView.addSubview(copyrightLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        hintLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        cardView.snp.makeConstraints { make in
            make.top.equalTo(hintLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        medicalRowView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        separator1.snp.makeConstraints { make in
            make.top.equalTo(medicalRowView.snp.bottom)
            make.leading.equalToSuperview().offset(56)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        privacyRowView.snp.makeConstraints { make in
            make.top.equalTo(separator1.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        separator2.snp.makeConstraints { make in
            make.top.equalTo(privacyRowView.snp.bottom)
            make.leading.equalToSuperview().offset(56)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        termsRowView.snp.makeConstraints { make in
            make.top.equalTo(separator2.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        copyrightLabel.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-SULayoutConstants.sectionSpacing * 1.5)
        }
    }

    override func setupBindings() {
        super.setupBindings()

        medicalRowView.onTap = { [weak self] in
            let webVC = SUWebViewController(
                url: URL(string: SUAppConfig.medicalDisclaimerURL),
                pageTitle: SULocalized("legal_item_medical_title", default: "健康与医疗免责声明"),
                fallbackResourceName: "medical"
            )
            self?.navigationController?.pushViewController(webVC, animated: true)
        }

        privacyRowView.onTap = { [weak self] in
            let webVC = SUWebViewController(
                url: URL(string: SUAppConfig.privacyPolicyURL),
                pageTitle: SULocalized("legal_item_privacy_title", default: "隐私政策"),
                fallbackResourceName: "privacy"
            )
            self?.navigationController?.pushViewController(webVC, animated: true)
        }

        termsRowView.onTap = { [weak self] in
            let webVC = SUWebViewController(
                url: URL(string: SUAppConfig.termsOfServiceURL),
                pageTitle: SULocalized("legal_item_terms_title", default: "用户服务条款"),
                fallbackResourceName: "terms"
            )
            self?.navigationController?.pushViewController(webVC, animated: true)
        }
    }
}

// MARK: - 辅助组件：带副标题的法律行视图
final class SULegalItemRowView: UIView {
    var onTap: (() -> Void)?

    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        iv.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let highlightOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.label.withAlphaComponent(0.06)
        view.alpha = 0
        return view
    }()

    init(title: String, subtitle: String, iconSystemName: String, iconBackground: UIColor) {
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        setupUI(title: title, subtitle: subtitle, iconSystemName: iconSystemName, iconBackground: iconBackground)
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(title: String, subtitle: String, iconSystemName: String, iconBackground: UIColor) {
        addSubview(highlightOverlay)
        addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(chevronImageView)

        iconContainerView.backgroundColor = iconBackground
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        iconImageView.image = UIImage(systemName: iconSystemName, withConfiguration: config)

        titleLabel.text = title
        subtitleLabel.text = subtitle

        highlightOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconContainerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(14)
            make.size.equalTo(30)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(iconContainerView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-8)
            make.bottom.equalToSuperview().offset(-12)
        }

        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-14)
            make.size.equalTo(14)
        }
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.highlightOverlay.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.highlightOverlay.alpha = 0
            }
        }
        onTap?()
    }

    func setTitle(_ text: String) {
        titleLabel.text = text
    }

    func setSubtitle(_ text: String) {
        subtitleLabel.text = text
    }
}
