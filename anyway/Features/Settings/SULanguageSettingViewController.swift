//
//  SULanguageSettingViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 语言选择二级页面 —— 清新苹果原生风格、即选即生效、带平滑微触觉动效与实时刷新
final class SULanguageSettingViewController: SUBaseViewController {

    // MARK: - 可滑动内容容器
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
        label.text = SULocalized("language_setting_hint", default: "选择应用界面展示的语言，切换后将即时生效")
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 语言列表卡片
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        return view
    }()

    private let rowsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.distribution = .fill
        return stack
    }()

    private var languageRowViews: [SULanguageItemRowView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
    }

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = SULocalized("settings_language", default: "语言选择 / Language")
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(hintLabel)
        contentView.addSubview(cardView)
        cardView.addSubview(rowsStackView)

        let currentLang = SULocalizationManager.shared.currentLanguage
        let languages = SULanguage.allCases

        for (index, lang) in languages.enumerated() {
            let isLast = (index == languages.count - 1)
            let row = SULanguageItemRowView(
                language: lang,
                isSelected: lang == currentLang,
                showSeparator: !isLast
            )
            row.onTapped = { [weak self] selectedLang in
                self?.handleLanguageSelected(selectedLang)
            }
            languageRowViews.append(row)
            rowsStackView.addArrangedSubview(row)
        }
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
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding + 4)
        }

        cardView.snp.makeConstraints { make in
            make.top.equalTo(hintLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.bottom.equalToSuperview().offset(-SULayoutConstants.sectionSpacing * 2)
        }

        rowsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setupBindings() {
        super.setupBindings()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDidChange),
            name: SULocalizationManager.languageDidChangeNotification,
            object: nil
        )
    }

    private func handleLanguageSelected(_ language: SULanguage) {
        guard language != SULocalizationManager.shared.currentLanguage else { return }

        // 切换语言并触发触觉反馈
        SULocalizationManager.shared.setLanguage(language)
        SUAudioFeedbackManager.shared.triggerHapticSelection()

        // 刷新所有选项的勾选状态
        refreshSelectionState()
    }

    @objc private func handleLanguageDidChange() {
        navigationItem.title = SULocalized("settings_language", default: "语言选择 / Language")
        hintLabel.text = SULocalized("language_setting_hint", default: "选择应用界面展示的语言，切换后将即时生效")
        refreshSelectionState()
    }

    private func refreshSelectionState() {
        let currentLang = SULocalizationManager.shared.currentLanguage
        for row in languageRowViews {
            row.setSelected(row.language == currentLang)
        }
    }
}

// MARK: - 单行语言选项组件
final class SULanguageItemRowView: UIView {

    let language: SULanguage
    var onTapped: ((SULanguage) -> Void)?

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemBlue
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        iv.image = UIImage(systemName: "checkmark", withConfiguration: config)
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let highlightOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.label.withAlphaComponent(0.06)
        view.alpha = 0
        return view
    }()

    init(language: SULanguage, isSelected: Bool, showSeparator: Bool) {
        self.language = language
        super.init(frame: .zero)
        isUserInteractionEnabled = true

        setupUI(isSelected: isSelected, showSeparator: showSeparator)
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(isSelected: Bool, showSeparator: Bool) {
        addSubview(highlightOverlay)
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(checkmarkImageView)

        if showSeparator {
            addSubview(separatorView)
        }

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        iconImageView.image = UIImage(systemName: "globe", withConfiguration: symbolConfig)

        titleLabel.text = language.displayName
        subtitleLabel.text = secondaryName(for: language)

        checkmarkImageView.isHidden = !isSelected

        highlightOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-8)
        }

        checkmarkImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(18)
        }

        if showSeparator {
            separatorView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.leading.equalTo(titleLabel.snp.leading)
                make.trailing.equalToSuperview()
                make.height.equalTo(1.0 / UIScreen.main.scale)
            }
        }

        snp.makeConstraints { make in
            make.height.equalTo(52)
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
        onTapped?(language)
    }

    func setSelected(_ selected: Bool) {
        UIView.transition(with: checkmarkImageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.checkmarkImageView.isHidden = !selected
        }
    }

    private func secondaryName(for language: SULanguage) -> String {
        switch language {
        case .en: return "English"
        case .zhHans: return "Simplified Chinese"
        case .zhHant: return "Traditional Chinese"
        case .ja: return "Japanese"
        case .ko: return "Korean"
        case .ar: return "Arabic"
        case .fr: return "French"
        }
    }
}
