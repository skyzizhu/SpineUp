//
//  SUSettingsViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// Tab 3: 个性化设置与关于 —— 清新简约、全苹果 SF 原生图标、流畅卡片切换
final class SUSettingsViewController: SUBaseViewController {

    private let viewModel: SUSettingsViewModel

    // MARK: - 可滑动内容容器
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let contentView = UIView()

    // MARK: - Section 1: 宠物人格切换
    private let personaSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "宠物拟人人格"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private var personaCardViews: [SUPersonaCardView] = []
    private let personaCardsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Section 2: 提醒偏好设置
    private let alertsSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "提醒偏好"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let alertsCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let voiceRowView = SUSettingsSwitchRowView(
        title: "AI 拟人语音播报",
        subtitle: "3分钟防打扰，轻柔避让背景音乐",
        iconSystemName: "speaker.wave.3.fill",
        iconTint: .systemBlue
    )

    private let hapticRowView = SUSettingsSwitchRowView(
        title: "触觉微震动提醒",
        subtitle: "低头超时后轻微震感",
        iconSystemName: "iphone.radiowaves.left.and.right",
        iconTint: .systemIndigo
    )

    private let soundRowView = SUSettingsSwitchRowView(
        title: "轻快系统提示铃",
        subtitle: "低头时清脆水滴声",
        iconSystemName: "bell.badge.fill",
        iconTint: .systemOrange
    )

    // MARK: - Section 3: 骨气能量与坚持打卡
    private let energySectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "骨气能量"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let energyCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let streakItemView = SUEnergyStatItemView(
        iconSystemName: "flame.fill",
        iconTint: .systemOrange,
        title: "连续打卡",
        value: "1 天"
    )

    private let totalCoinsItemView = SUEnergyStatItemView(
        iconSystemName: "bolt.heart.fill",
        iconTint: .systemYellow,
        title: "累计能量币",
        value: "0"
    )

    // MARK: - Section 4: 通用偏好 (外观主题与多语言)
    private let generalSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("settings_general_section", default: "通用设置")
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let generalCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        return view
    }()

    private let themeRowView = SUSettingsNavigationRowView(
        title: SULocalized("settings_theme", default: "外观主题"),
        value: SUThemeManager.shared.currentTheme.displayName,
        iconSystemName: "circle.lefthalf.filled",
        iconBackground: .systemTeal
    )

    private let generalSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let languageRowView = SUSettingsNavigationRowView(
        title: SULocalized("settings_language", default: "语言设置"),
        value: SULocalizationManager.shared.isFollowSystem ? SULocalized("follow_system", default: "跟随系统") : SULocalizationManager.shared.currentLanguage.displayName,
        iconSystemName: "globe",
        iconBackground: .systemIndigo
    )

    // MARK: - Section 5: 版本与标语
    private let sloganLabel: UILabel = {
        let label = UILabel()
        label.text = "SpineUp · 做人要有骨气"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "\(SUAppConfig.appDisplayName) v\(SUAppConfig.appVersion) (\(SUAppConfig.buildVersion))"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    init(viewModel: SUSettingsViewModel = SUSettingsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = SUSettingsViewModel()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshEnergyData()
        refreshLocalizedStrings()
    }

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = SULocalized("settings_title", default: "设置与个性化")

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 组装人格卡片
        contentView.addSubview(personaSectionTitleLabel)
        contentView.addSubview(personaCardsStackView)

        for persona in viewModel.availablePersonas {
            let card = SUPersonaCardView(persona: persona)
            card.onSelected = { [weak self] selectedPersona in
                self?.viewModel.selectPersona(selectedPersona)
            }
            personaCardViews.append(card)
            personaCardsStackView.addArrangedSubview(card)
        }

        // 组装提醒开关
        contentView.addSubview(alertsSectionTitleLabel)
        contentView.addSubview(alertsCardView)
        alertsCardView.addSubview(voiceRowView)
        alertsCardView.addSubview(hapticRowView)
        alertsCardView.addSubview(soundRowView)

        // 组装能量统计
        contentView.addSubview(energySectionTitleLabel)
        contentView.addSubview(energyCardView)
        energyCardView.addSubview(streakItemView)
        energyCardView.addSubview(totalCoinsItemView)

        // 组装通用偏好入口 (外观主题与多语言二级子页面)
        contentView.addSubview(generalSectionTitleLabel)
        contentView.addSubview(generalCardView)
        generalCardView.addSubview(themeRowView)
        generalCardView.addSubview(generalSeparatorView)
        generalCardView.addSubview(languageRowView)

        // 标语与版权
        contentView.addSubview(sloganLabel)
        contentView.addSubview(versionLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        // 遵循规则 7 与 9：滑动视图贯穿边缘，系统管理安全区
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        personaSectionTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        personaCardsStackView.snp.makeConstraints { make in
            make.top.equalTo(personaSectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        alertsSectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(personaCardsStackView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        alertsCardView.snp.makeConstraints { make in
            make.top.equalTo(alertsSectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        voiceRowView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(58)
        }

        hapticRowView.snp.makeConstraints { make in
            make.top.equalTo(voiceRowView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(58)
        }

        soundRowView.snp.makeConstraints { make in
            make.top.equalTo(hapticRowView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(58)
        }

        energySectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(alertsCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        energyCardView.snp.makeConstraints { make in
            make.top.equalTo(energySectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(80)
        }

        streakItemView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.equalTo(energyCardView.snp.centerX)
        }

        totalCoinsItemView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalTo(energyCardView.snp.centerX)
        }

        generalSectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(energyCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        generalCardView.snp.makeConstraints { make in
            make.top.equalTo(generalSectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        themeRowView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }

        generalSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(themeRowView.snp.bottom)
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        languageRowView.snp.makeConstraints { make in
            make.top.equalTo(generalSeparatorView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(52)
        }

        sloganLabel.snp.makeConstraints { make in
            make.top.equalTo(generalCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing * 1.5)
            make.centerX.equalToSuperview()
        }

        versionLabel.snp.makeConstraints { make in
            make.top.equalTo(sloganLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-SULayoutConstants.sectionSpacing * 2)
        }
    }

    override func setupBindings() {
        super.setupBindings()

        voiceRowView.onSwitchChanged = { [weak self] isOn in
            self?.viewModel.setVoiceAlertEnabled(isOn)
        }

        hapticRowView.onSwitchChanged = { [weak self] isOn in
            self?.viewModel.setHapticAlertEnabled(isOn)
        }

        soundRowView.onSwitchChanged = { [weak self] isOn in
            self?.viewModel.setSoundAlertEnabled(isOn)
        }

        themeRowView.onTap = { [weak self] in
            let themeVC = SUThemeSettingViewController()
            self?.navigationController?.pushViewController(themeVC, animated: true)
        }

        languageRowView.onTap = { [weak self] in
            let languageVC = SULanguageSettingViewController()
            self?.navigationController?.pushViewController(languageVC, animated: true)
        }

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

        viewModel.onStateChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.refreshUI()
            }
        }

        refreshUI()
    }

    private func refreshUI() {
        for card in personaCardViews {
            card.setSelected(card.persona == viewModel.activePersona)
        }

        voiceRowView.setSwitchOn(viewModel.isVoiceAlertEnabled)
        hapticRowView.setSwitchOn(viewModel.isHapticAlertEnabled)
        soundRowView.setSwitchOn(viewModel.isSoundAlertEnabled)

        let streakFormat = SULocalized("streak_days_val", default: "%d 天")
        streakItemView.updateValue(String(format: streakFormat, viewModel.streakDays))
        totalCoinsItemView.updateValue("\(viewModel.totalCoins)")

        themeRowView.setValue(SUThemeManager.shared.currentTheme.displayName)
        let langVal = SULocalizationManager.shared.isFollowSystem ? SULocalized("follow_system", default: "跟随系统") : SULocalizationManager.shared.currentLanguage.displayName
        languageRowView.setValue(langVal)
    }

    @objc private func handleThemeDidChange() {
        themeRowView.setValue(SUThemeManager.shared.currentTheme.displayName)
    }

    @objc private func handleLanguageDidChange() {
        refreshLocalizedStrings()
        refreshUI()
    }

    private func refreshLocalizedStrings() {
        navigationItem.title = SULocalized("settings_title", default: "偏好设置")

        // Section 1: 人格卡片
        personaSectionTitleLabel.text = SULocalized("settings_persona_section", default: "宠物拟人人格")
        for card in personaCardViews {
            card.refreshLocalizedStrings()
        }

        // Section 2: 提醒开关
        alertsSectionTitleLabel.text = SULocalized("settings_alerts_section", default: "提醒偏好")
        voiceRowView.setTitle(SULocalized("settings_voice_alert", default: "AI 拟人语音播报"))
        voiceRowView.setSubtitle(SULocalized("settings_voice_alert_desc", default: "3分钟防打扰，轻柔避让背景音乐"))

        hapticRowView.setTitle(SULocalized("settings_haptic_alert", default: "触觉微震动提醒"))
        hapticRowView.setSubtitle(SULocalized("settings_haptic_alert_desc", default: "低头超时后轻微震感"))

        soundRowView.setTitle(SULocalized("settings_sound_alert", default: "轻快系统提示铃"))
        soundRowView.setSubtitle(SULocalized("settings_sound_alert_desc", default: "低头时清脆水滴声"))

        // Section 3: 能量统计
        energySectionTitleLabel.text = SULocalized("settings_energy_section", default: "骨气能量")
        streakItemView.setTitle(SULocalized("streak_days_title", default: "连续打卡"))
        let streakFormat = SULocalized("streak_days_val", default: "%d 天")
        streakItemView.updateValue(String(format: streakFormat, viewModel.streakDays))
        totalCoinsItemView.setTitle(SULocalized("energy_coins_total_title", default: "累计能量币"))

        // Section 4: 通用设置
        generalSectionTitleLabel.text = SULocalized("settings_general_section", default: "通用设置")
        themeRowView.setTitle(SULocalized("settings_theme", default: "外观主题"))
        themeRowView.setValue(SUThemeManager.shared.currentTheme.displayName)

        languageRowView.setTitle(SULocalized("settings_language", default: "语言设置"))
        let langVal = SULocalizationManager.shared.isFollowSystem ? SULocalized("follow_system", default: "跟随系统") : SULocalizationManager.shared.currentLanguage.displayName
        languageRowView.setValue(langVal)

        // Slogan
        sloganLabel.text = SULocalized("app_slogan", default: "SpineUp · 做人要有骨气")
    }
}

// MARK: - 辅助子组件：设置开关行视图
final class SUSettingsSwitchRowView: UIView {
    var onSwitchChanged: ((Bool) -> Void)?

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
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
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private let toggleSwitch = UISwitch()

    init(title: String, subtitle: String, iconSystemName: String, iconTint: UIColor) {
        super.init(frame: .zero)

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(toggleSwitch)

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconImageView.image = UIImage(systemName: iconSystemName, withConfiguration: config)
        iconImageView.tintColor = iconTint
        titleLabel.text = title
        subtitleLabel.text = subtitle

        iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(14)
            make.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(toggleSwitch.snp.leading).offset(-8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.lessThanOrEqualTo(toggleSwitch.snp.leading).offset(-8)
        }

        toggleSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-14)
        }

        toggleSwitch.addTarget(self, action: #selector(handleSwitch(_:)), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSwitchOn(_ isOn: Bool) {
        toggleSwitch.isOn = isOn
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func setSubtitle(_ subtitle: String) {
        subtitleLabel.text = subtitle
    }

    @objc private func handleSwitch(_ sender: UISwitch) {
        onSwitchChanged?(sender.isOn)
    }
}

// MARK: - 辅助子组件：能量统计指标视图
final class SUEnergyStatItemView: UIView {
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()

    init(iconSystemName: String, iconTint: UIColor, title: String, value: String) {
        super.init(frame: .zero)

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        iconImageView.image = UIImage(systemName: iconSystemName, withConfiguration: config)
        iconImageView.tintColor = iconTint
        titleLabel.text = title
        valueLabel.text = value

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView.snp.centerY)
            make.leading.equalTo(iconImageView.snp.trailing).offset(6)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func updateValue(_ text: String) {
        valueLabel.text = text
    }
}

// MARK: - 辅助子组件：二级导航入口行视图
final class SUSettingsNavigationRowView: UIView {
    var onTap: (() -> Void)?

    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 7
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

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
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

    init(title: String, value: String, iconSystemName: String, iconBackground: UIColor) {
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        setupUI(title: title, value: value, iconSystemName: iconSystemName, iconBackground: iconBackground)
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(title: String, value: String, iconSystemName: String, iconBackground: UIColor) {
        addSubview(highlightOverlay)
        addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(chevronImageView)

        iconContainerView.backgroundColor = iconBackground
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.image = UIImage(systemName: iconSystemName, withConfiguration: config)

        titleLabel.text = title
        valueLabel.text = value

        highlightOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconContainerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(14)
            make.size.equalTo(28)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconContainerView.snp.trailing).offset(12)
        }

        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-14)
            make.size.equalTo(14)
        }

        valueLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(chevronImageView.snp.leading).offset(-6)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
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
        onTap?()
    }

    func setTitle(_ text: String) {
        titleLabel.text = text
    }

    func setValue(_ text: String) {
        valueLabel.text = text
    }
}

