//
//  SUThemeSettingViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 主题外观选择二级页面 —— 支持跟随系统、浅色模式与深色模式，即选即生效
final class SUThemeSettingViewController: SUBaseViewController {

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
        label.text = SULocalized("theme_setting_hint", default: "选择应用界面展示的主题风格，切换后将即时生效")
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 主题列表卡片
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

    private var themeRowViews: [SUThemeItemRowView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
    }

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = SULocalized("settings_theme", default: "外观主题")
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(hintLabel)
        contentView.addSubview(cardView)
        cardView.addSubview(rowsStackView)

        let currentTheme = SUThemeManager.shared.currentTheme
        let themes = SUAppTheme.allCases

        for (index, theme) in themes.enumerated() {
            let isLast = (index == themes.count - 1)
            let row = SUThemeItemRowView(
                theme: theme,
                isSelected: theme == currentTheme,
                showSeparator: !isLast
            )
            row.onTapped = { [weak self] selectedTheme in
                self?.handleThemeSelected(selectedTheme)
            }
            themeRowViews.append(row)
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
            selector: #selector(handleThemeDidChange),
            name: SUThemeManager.themeDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDidChange),
            name: SULocalizationManager.languageDidChangeNotification,
            object: nil
        )
    }

    private func handleThemeSelected(_ theme: SUAppTheme) {
        guard theme != SUThemeManager.shared.currentTheme else { return }

        // 切换主题并触发微震动
        SUThemeManager.shared.setTheme(theme)
        SUAudioFeedbackManager.shared.triggerHapticSelection()

        // 刷新所有选项的勾选状态
        refreshSelectionState()
    }

    @objc private func handleThemeDidChange() {
        refreshSelectionState()
    }

    @objc private func handleLanguageDidChange() {
        navigationItem.title = SULocalized("settings_theme", default: "外观主题")
        hintLabel.text = SULocalized("theme_setting_hint", default: "选择应用界面展示的主题风格，切换后将即时生效")
        for row in themeRowViews {
            row.refreshLocalizedStrings()
        }
    }

    private func refreshSelectionState() {
        let currentTheme = SUThemeManager.shared.currentTheme
        for row in themeRowViews {
            row.setSelected(row.theme == currentTheme)
        }
    }
}

// MARK: - 单行主题选项组件
final class SUThemeItemRowView: UIView {

    let theme: SUAppTheme
    var onTapped: ((SUAppTheme) -> Void)?

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

    init(theme: SUAppTheme, isSelected: Bool, showSeparator: Bool) {
        self.theme = theme
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
        iconImageView.image = UIImage(systemName: theme.iconSystemName, withConfiguration: symbolConfig)

        titleLabel.text = theme.displayName
        subtitleLabel.text = theme.subtitle

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
                make.height.equalTo(0.5)
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
        onTapped?(theme)
    }

    func setSelected(_ selected: Bool) {
        UIView.transition(with: checkmarkImageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.checkmarkImageView.isHidden = !selected
        }
    }

    func refreshLocalizedStrings() {
        titleLabel.text = theme.displayName
        subtitleLabel.text = theme.subtitle
    }
}
