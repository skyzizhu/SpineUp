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
        label.text = SULocalized("settings_persona_section", default: "宠物拟人人格")
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private var personaCardViews: [SUPersonaCardView] = []
    private let personaCardsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Section 2: 提醒偏好设置
    private let alertsSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("settings_alerts_section", default: "提醒偏好")
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let alertsCardView: UIView = {
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

    private let voiceRowView = SUSettingsSwitchRowView(
        title: SULocalized("settings_voice_alert", default: "AI 拟人语音播报"),
        subtitle: SULocalized("settings_voice_alert_desc", default: "3分钟防打扰，轻柔避让背景音乐"),
        iconSystemName: "speaker.wave.3.fill",
        iconTint: .systemBlue
    )

    private let hapticRowView = SUSettingsSwitchRowView(
        title: SULocalized("settings_haptic_alert", default: "触觉微震动提醒"),
        subtitle: SULocalized("settings_haptic_alert_desc", default: "低头超时后轻微震感"),
        iconSystemName: "iphone.radiowaves.left.and.right",
        iconTint: .systemIndigo
    )

    private let soundRowView = SUSettingsSwitchRowView(
        title: SULocalized("settings_sound_alert", default: "轻快系统提示铃"),
        subtitle: SULocalized("settings_sound_alert_desc", default: "低头时清脆水滴声"),
        iconSystemName: "bell.badge.fill",
        iconTint: .systemOrange
    )

    private let soundSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let soundStyleRowView = SUSettingsNavigationRowView(
        title: SULocalized("settings_sound_style", default: "提示声音效"),
        value: "",
        iconSystemName: "music.note",
        iconBackground: .systemPink
    )

    private let sensitivitySeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let sensitivityRowView = SUSettingsNavigationRowView(
        title: SULocalized("settings_sensitivity_title", default: "预警灵敏度"),
        value: "",
        iconSystemName: "slider.horizontal.3",
        iconBackground: .systemTeal
    )

    private let sedentarySeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let sedentaryRowView = SUSettingsSwitchRowView(
        title: SULocalized("settings_sedentary_title", default: "久坐超时站立提醒"),
        subtitle: SULocalized("settings_sedentary_desc", default: "连续工作45分钟后轻柔提醒起身伸展"),
        iconSystemName: "figure.walk",
        iconTint: .systemGreen
    )

    // MARK: - 提醒偏好说明卡片
    private let alertsFooterCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 26
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.03
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        return view
    }()

    private let alertsFooterIconView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iv.image = UIImage(systemName: "speaker.wave.2.bubble.fill", withConfiguration: config) ?? UIImage(systemName: "info.circle.fill", withConfiguration: config)
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let alertsFooterTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("settings_alerts_footer_title", default: "后台音频与低延迟提醒")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let alertsSectionFooterLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized(
            "settings_alerts_footer_desc",
            default: "开启守护后，应用将使用后台音频通道维持 AirPods 空间姿态流，确保锁屏与切换应用时仍可及时播报不良坐姿提醒；绝不采集任何环境声音。"
        )
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Section 3: 骨气能量与坚持打卡
    private let energySectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("settings_energy_section", default: "骨气能量")
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let energyCardView: UIView = {
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

    private let streakItemView = SUEnergyStatItemView(
        iconSystemName: "flame.fill",
        iconTint: .systemOrange,
        title: SULocalized("settings_streak_days", default: "连续打卡"),
        value: String(format: SULocalized("streak_days_val", default: "%d 天"), 1)
    )

    private let totalCoinsItemView = SUEnergyStatItemView(
        iconSystemName: "bolt.heart.fill",
        iconTint: .systemYellow,
        title: SULocalized("settings_total_coins", default: "累计能量币"),
        value: "0"
    )

    // MARK: - Section 4: 通用偏好 (外观主题与多语言)
    private let generalSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("settings_general_section", default: "通用设置")
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let generalCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.03
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 16
        // Note: For inner views to not clip shadow, don't use masksToBounds = true
        return view
    }()

    private let userNameRowView = SUSettingsNavigationRowView(
        title: SULocalized("settings_user_name", default: "Air昵称"),
        value: SUUserDefaultsManager.shared.userName,
        iconSystemName: "person.crop.circle.fill",
        iconBackground: .systemBlue
    )

    private let nameSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
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

    private let healthKitSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let healthKitRowView = SUSettingsSwitchRowView(
        title: SULocalized("settings_healthkit_title", default: "同步至 Apple 健康"),
        subtitle: SULocalized("settings_healthkit_desc", default: "挺拔专注自动记录为正念分钟数"),
        iconSystemName: "heart.fill",
        iconTint: .systemRed
    )

    private let notifSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let dailyNotifRowView = SUSettingsSwitchRowView(
        title: SULocalized("settings_daily_notif_title", default: "每日定时提醒推送"),
        subtitle: SULocalized("settings_daily_notif_desc", default: "早晨09:30佩戴提醒 · 傍晚18:30战报出炉"),
        iconSystemName: "bell.badge.fill",
        iconTint: .systemIndigo
    )

    // MARK: - Section 5: 高级玩法
    private let advancedSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("settings_advanced_section", default: "高级玩法")
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let advancedCardView: UIView = {
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

    private let autoLaunchRowView = SUSettingsNavigationRowView(
        title: SULocalized("settings_auto_launch_title", default: "戴上耳机自动启动"),
        value: SULocalized("settings_auto_launch_value", default: "快捷指令指引"),
        iconSystemName: "bolt.badge.automatic",
        iconBackground: .systemPurple
    )

    // MARK: - Section 6: 数据管理与隐私
    private let dataSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("settings_data_section", default: "数据管理与隐私")
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let dataCardView: UIView = {
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

    private let exportCSVRowView = SUSettingsNavigationRowView(
        title: SULocalized("settings_export_csv_title", default: "导出健康体态记录 (CSV)"),
        value: "",
        iconSystemName: "square.and.arrow.up",
        iconBackground: .systemTeal
    )

    private let dataSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let clearDataRowView = SUSettingsNavigationRowView(
        title: SULocalized("settings_clear_data_title", default: "重置所有本地数据"),
        value: "",
        iconSystemName: "trash.fill",
        iconBackground: .systemRed
    )

    // MARK: - Section 6: 合规与法律条款
    private let legalSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("settings_legal_section", default: "法律与免责声明")
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let legalCardView: UIView = {
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

    private let legalRowView = SUSettingsNavigationRowView(
        title: SULocalized("settings_legal_documents_title", default: "协议与声明"),
        value: "",
        iconSystemName: "shield.checkerboard",
        iconBackground: .systemTeal
    )

    // MARK: - Section 6: 版本与标语
    private let sloganLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("settings_slogan", default: "SpineUp · 做人要有骨气")
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if CommandLine.arguments.contains("-scrollSettingsToBottom") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let bottomOffset = CGPoint(x: 0, y: max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.adjustedContentInset.bottom))
                self.scrollView.setContentOffset(bottomOffset, animated: false)
            }
        }
        if CommandLine.arguments.contains("-openAutoLaunchGuide") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let guideVC = SUAutoLaunchGuideViewController()
                self.navigationController?.pushViewController(guideVC, animated: false)
            }
        }
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
        alertsCardView.addSubview(soundSeparatorView)
        alertsCardView.addSubview(soundStyleRowView)
        alertsCardView.addSubview(sensitivitySeparatorView)
        alertsCardView.addSubview(sensitivityRowView)
        alertsCardView.addSubview(sedentarySeparatorView)
        alertsCardView.addSubview(sedentaryRowView)
        contentView.addSubview(alertsFooterCardView)
        alertsFooterCardView.addSubview(alertsFooterIconView)
        alertsFooterCardView.addSubview(alertsFooterTitleLabel)
        alertsFooterCardView.addSubview(alertsSectionFooterLabel)

        // 组装能量统计
        contentView.addSubview(energySectionTitleLabel)
        contentView.addSubview(energyCardView)
        energyCardView.addSubview(streakItemView)
        energyCardView.addSubview(totalCoinsItemView)

        // 组装通用偏好入口 (外观主题与多语言二级子页面)
        contentView.addSubview(generalSectionTitleLabel)
        contentView.addSubview(generalCardView)
        generalCardView.addSubview(userNameRowView)
        generalCardView.addSubview(nameSeparatorView)
        generalCardView.addSubview(themeRowView)
        generalCardView.addSubview(generalSeparatorView)
        generalCardView.addSubview(languageRowView)
        generalCardView.addSubview(healthKitSeparatorView)
        generalCardView.addSubview(healthKitRowView)
        generalCardView.addSubview(notifSeparatorView)
        generalCardView.addSubview(dailyNotifRowView)

        // 组装高级玩法入口
        contentView.addSubview(advancedSectionTitleLabel)
        contentView.addSubview(advancedCardView)
        advancedCardView.addSubview(autoLaunchRowView)

        // 组装数据管理与隐私入口
        contentView.addSubview(dataSectionTitleLabel)
        contentView.addSubview(dataCardView)
        dataCardView.addSubview(exportCSVRowView)
        dataCardView.addSubview(dataSeparatorView)
        dataCardView.addSubview(clearDataRowView)

        // 组装法律与合规入口
        contentView.addSubview(legalSectionTitleLabel)
        contentView.addSubview(legalCardView)
        legalCardView.addSubview(legalRowView)

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
            make.height.greaterThanOrEqualTo(58)
        }

        hapticRowView.snp.makeConstraints { make in
            make.top.equalTo(voiceRowView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(58)
        }

        soundRowView.snp.makeConstraints { make in
            make.top.equalTo(hapticRowView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(58)
        }

        soundSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(soundRowView.snp.bottom)
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        soundStyleRowView.snp.makeConstraints { make in
            make.top.equalTo(soundSeparatorView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
        }

        sensitivitySeparatorView.snp.makeConstraints { make in
            make.top.equalTo(soundStyleRowView.snp.bottom)
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        sensitivityRowView.snp.makeConstraints { make in
            make.top.equalTo(sensitivitySeparatorView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
        }

        sedentarySeparatorView.snp.makeConstraints { make in
            make.top.equalTo(sensitivityRowView.snp.bottom)
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        sedentaryRowView.snp.makeConstraints { make in
            make.top.equalTo(sedentarySeparatorView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(58)
        }

        alertsFooterCardView.snp.makeConstraints { make in
            make.top.equalTo(alertsCardView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        alertsFooterIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(14)
            make.size.equalTo(18)
        }

        alertsFooterTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(alertsFooterIconView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-14)
        }

        alertsSectionFooterLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(alertsFooterTitleLabel.snp.bottom).offset(6)
            make.top.greaterThanOrEqualTo(alertsFooterIconView.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-12)
        }

        energySectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(alertsFooterCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
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

        userNameRowView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
        }

        nameSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(userNameRowView.snp.bottom)
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        themeRowView.snp.makeConstraints { make in
            make.top.equalTo(nameSeparatorView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
        }

        generalSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(themeRowView.snp.bottom)
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        languageRowView.snp.makeConstraints { make in
            make.top.equalTo(generalSeparatorView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
        }

        healthKitSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(languageRowView.snp.bottom)
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        healthKitRowView.snp.makeConstraints { make in
            make.top.equalTo(healthKitSeparatorView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(58)
        }

        notifSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(healthKitRowView.snp.bottom)
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        dailyNotifRowView.snp.makeConstraints { make in
            make.top.equalTo(notifSeparatorView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(58)
        }

        advancedSectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(generalCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        advancedCardView.snp.makeConstraints { make in
            make.top.equalTo(advancedSectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        autoLaunchRowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
        }

        dataSectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(advancedCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        dataCardView.snp.makeConstraints { make in
            make.top.equalTo(dataSectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        exportCSVRowView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
        }

        dataSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(exportCSVRowView.snp.bottom)
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        clearDataRowView.snp.makeConstraints { make in
            make.top.equalTo(dataSeparatorView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
        }

        legalSectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(dataCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        legalCardView.snp.makeConstraints { make in
            make.top.equalTo(legalSectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        legalRowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
        }

        sloganLabel.snp.makeConstraints { make in
            make.top.equalTo(legalCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing * 1.5)
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

        soundStyleRowView.onTap = { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(
                title: SULocalized("sound_style_picker_title", default: "选择提示声音效"),
                message: SULocalized("sound_style_picker_msg", default: "低头超时时播放的轻柔提示音"),
                preferredStyle: .actionSheet
            )
            for style in SUAlertSoundStyle.allCases {
                let action = UIAlertAction(title: style.displayName, style: .default) { [weak self] _ in
                    self?.viewModel.setSoundStyle(style)
                    self?.soundStyleRowView.setValue(style.displayName)
                }
                alert.addAction(action)
            }
            alert.addAction(UIAlertAction(title: SULocalized("common_cancel", default: "取消"), style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = self.soundStyleRowView
                popover.sourceRect = self.soundStyleRowView.bounds
            }
            self.present(alert, animated: true)
        }

        sensitivityRowView.onTap = { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(
                title: SULocalized("sensitivity_picker_title", default: "预警灵敏度"),
                message: SULocalized("sensitivity_picker_msg", default: "根据办公桌椅与显示器高度调整前倾预警阈值"),
                preferredStyle: .actionSheet
            )
            for item in SUPostureSensitivity.allCases {
                let title = "\(item.title) - \(item.subtitle)"
                let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                    self?.viewModel.setSensitivity(item)
                    self?.sensitivityRowView.setValue(item.title)
                }
                alert.addAction(action)
            }
            alert.addAction(UIAlertAction(title: SULocalized("common_cancel", default: "取消"), style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = self.sensitivityRowView
                popover.sourceRect = self.sensitivityRowView.bounds
            }
            self.present(alert, animated: true)
        }

        sedentaryRowView.onSwitchChanged = { [weak self] isOn in
            self?.viewModel.setSedentaryReminderEnabled(isOn)
        }

        healthKitRowView.onSwitchChanged = { [weak self] isOn in
            guard let self = self else { return }
            Task {
                let granted = await self.viewModel.setHealthKitSyncEnabled(isOn)
                if !granted && isOn {
                    DispatchQueue.main.async {
                        self.healthKitRowView.setSwitchOn(false)
                        let alert = UIAlertController(
                            title: SULocalized("healthkit_auth_fail_title", default: "未获得健康授权"),
                            message: SULocalized("healthkit_auth_fail_msg", default: "请在系统“设置 > 健康”中允许 SpineUp 写入正念数据与读取步数。"),
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: SULocalized("common_confirm", default: "好"), style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }

        dailyNotifRowView.onSwitchChanged = { [weak self] isOn in
            guard let self = self else { return }
            Task {
                let granted = await self.viewModel.setDailyNotificationEnabled(isOn)
                if !granted && isOn {
                    DispatchQueue.main.async {
                        self.dailyNotifRowView.setSwitchOn(false)
                        let alert = UIAlertController(
                            title: SULocalized("notif_auth_fail_title", default: "未开启通知权限"),
                            message: SULocalized("notif_auth_fail_msg", default: "请在系统“设置 > 通知 > SpineUp”中允许通知推送。"),
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: SULocalized("common_confirm", default: "好"), style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }

        exportCSVRowView.onTap = { [weak self] in
            guard let self = self else { return }
            if let url = self.viewModel.exportCSVURL() {
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = self.exportCSVRowView
                    popover.sourceRect = self.exportCSVRowView.bounds
                }
                self.present(activityVC, animated: true)
            }
        }

        clearDataRowView.onTap = { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(
                title: SULocalized("clear_data_confirm_title", default: "重置所有本地数据？"),
                message: SULocalized("clear_data_confirm_msg", default: "此操作将清除校准基准、历史会话战报与能量币，且不可撤销。"),
                preferredStyle: .actionSheet
            )
            let confirmAction = UIAlertAction(title: SULocalized("clear_data_confirm_btn", default: "确认清除"), style: .destructive) { [weak self] _ in
                self?.viewModel.clearAllData()
            }
            alert.addAction(confirmAction)
            alert.addAction(UIAlertAction(title: SULocalized("common_cancel", default: "取消"), style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = self.clearDataRowView
                popover.sourceRect = self.clearDataRowView.bounds
            }
            self.present(alert, animated: true)
        }

        userNameRowView.onTap = { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(
                title: SULocalized("edit_username_title", default: "修改个性昵称"),
                message: SULocalized("edit_username_msg", default: "给自己起一个响亮的挺拔代号吧！"),
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.text = SUUserDefaultsManager.shared.userName
                tf.placeholder = SULocalized("edit_username_placeholder", default: "如：不低头的极客阿强")
            }
            alert.addAction(UIAlertAction(title: SULocalized("common_cancel", default: "取消"), style: .cancel))
            alert.addAction(UIAlertAction(title: SULocalized("common_confirm", default: "保存"), style: .default) { [weak self] _ in
                guard let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
                SUUserDefaultsManager.shared.userName = text
                self?.userNameRowView.setValue(text)
            })
            self.present(alert, animated: true)
        }

        themeRowView.onTap = { [weak self] in
            let themeVC = SUThemeSettingViewController()
            self?.navigationController?.pushViewController(themeVC, animated: true)
        }

        languageRowView.onTap = { [weak self] in
            let languageVC = SULanguageSettingViewController()
            self?.navigationController?.pushViewController(languageVC, animated: true)
        }

        autoLaunchRowView.onTap = { [weak self] in
            let guideVC = SUAutoLaunchGuideViewController()
            self?.navigationController?.pushViewController(guideVC, animated: true)
        }

        legalRowView.onTap = { [weak self] in
            let legalVC = SULegalListViewController()
            self?.navigationController?.pushViewController(legalVC, animated: true)
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

        soundStyleRowView.setValue(viewModel.currentSoundStyle.displayName)
        sensitivityRowView.setValue(viewModel.currentSensitivity.title)
        sedentaryRowView.setSwitchOn(viewModel.isSedentaryReminderEnabled)
        healthKitRowView.setSwitchOn(viewModel.isHealthKitSyncEnabled)
        dailyNotifRowView.setSwitchOn(viewModel.isDailyNotificationEnabled)

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

        soundStyleRowView.setTitle(SULocalized("settings_sound_style", default: "提示声音效"))
        soundStyleRowView.setValue(viewModel.currentSoundStyle.displayName)

        sensitivityRowView.setTitle(SULocalized("settings_sensitivity_title", default: "预警灵敏度"))
        sensitivityRowView.setValue(viewModel.currentSensitivity.title)

        sedentaryRowView.setTitle(SULocalized("settings_sedentary_title", default: "久坐超时站立提醒"))
        sedentaryRowView.setSubtitle(SULocalized("settings_sedentary_desc", default: "连续工作45分钟后轻柔提醒起身伸展"))

        alertsFooterTitleLabel.text = SULocalized("settings_alerts_footer_title", default: "后台音频与低延迟提醒")
        alertsSectionFooterLabel.text = SULocalized(
            "settings_alerts_footer_desc",
            default: "开启守护后，应用将使用后台音频通道维持 AirPods 空间姿态流，确保锁屏与切换应用时仍可及时播报不良坐姿提醒；绝不采集任何环境声音。"
        )

        // Section 3: 能量统计
        energySectionTitleLabel.text = SULocalized("settings_energy_section", default: "骨气能量")
        streakItemView.setTitle(SULocalized("streak_days_title", default: "连续打卡"))
        let streakFormat = SULocalized("streak_days_val", default: "%d 天")
        streakItemView.updateValue(String(format: streakFormat, viewModel.streakDays))
        totalCoinsItemView.setTitle(SULocalized("energy_coins_total_title", default: "累计能量币"))

        // Section 4: 通用设置
        generalSectionTitleLabel.text = SULocalized("settings_general_section", default: "通用设置")
        userNameRowView.setTitle(SULocalized("settings_user_name", default: "Air昵称"))
        userNameRowView.setValue(SUUserDefaultsManager.shared.userName)
        themeRowView.setTitle(SULocalized("settings_theme", default: "外观主题"))
        themeRowView.setValue(SUThemeManager.shared.currentTheme.displayName)

        languageRowView.setTitle(SULocalized("settings_language", default: "语言设置"))
        let langVal = SULocalizationManager.shared.isFollowSystem ? SULocalized("follow_system", default: "跟随系统") : SULocalizationManager.shared.currentLanguage.displayName
        languageRowView.setValue(langVal)

        healthKitRowView.setTitle(SULocalized("settings_healthkit_title", default: "同步至 Apple 健康"))
        healthKitRowView.setSubtitle(SULocalized("settings_healthkit_desc", default: "挺拔专注自动记录为正念分钟数"))

        dailyNotifRowView.setTitle(SULocalized("settings_daily_notif_title", default: "每日定时提醒推送"))
        dailyNotifRowView.setSubtitle(SULocalized("settings_daily_notif_desc", default: "早晨09:30佩戴提醒 · 傍晚18:30战报出炉"))

        // Section 5: 高级玩法
        advancedSectionTitleLabel.text = SULocalized("settings_advanced_section", default: "高级玩法")
        autoLaunchRowView.setTitle(SULocalized("settings_auto_launch_title", default: "戴上耳机自动启动"))
        autoLaunchRowView.setValue(SULocalized("settings_auto_launch_value", default: "快捷指令指引"))

        // Section 6: 数据管理与隐私
        dataSectionTitleLabel.text = SULocalized("settings_data_section", default: "数据管理与隐私")
        exportCSVRowView.setTitle(SULocalized("settings_export_csv_title", default: "导出健康体态记录 (CSV)"))
        clearDataRowView.setTitle(SULocalized("settings_clear_data_title", default: "清除所有本地数据"))

        // Section 7: 合规与法律条款
        legalSectionTitleLabel.text = SULocalized("settings_legal_section", default: "法律与免责声明")
        legalRowView.setTitle(SULocalized("settings_legal_documents_title", default: "协议与声明"))

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
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
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
            make.top.equalToSuperview().offset(14)
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
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
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
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
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
            make.trailing.lessThanOrEqualToSuperview().offset(-8)
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
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
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
        valueLabel.isHidden = value.isEmpty

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

        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-14)
            make.size.equalTo(14)
        }

        valueLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(chevronImageView.snp.leading).offset(-6)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconContainerView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-8)
            make.top.greaterThanOrEqualToSuperview().offset(10)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
        }

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(52)
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
        valueLabel.isHidden = text.isEmpty
    }
}

