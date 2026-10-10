//
//  SUAutoLaunchGuideViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/10.
//

import UIKit
import SnapKit

/// 高级玩法：戴上耳机自动启动配置指南页面
final class SUAutoLaunchGuideViewController: SUBaseViewController {

    // MARK: - 可滑动容器
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let contentView = UIView()

    // MARK: - 顶部 Hero 引导卡片
    private let heroCardView: UIView = {
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

    private let heroIconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
        view.layer.cornerRadius = 28
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let heroIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        iv.image = UIImage(systemName: "airpodspro", withConfiguration: config) ?? UIImage(systemName: "headphones", withConfiguration: config)
        iv.tintColor = .systemPurple
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let heroTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("auto_launch_hero_title", default: "AirPods 入耳 · 自动开练")
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let heroSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized(
            "auto_launch_hero_subtitle",
            default: "利用 iOS 原生「快捷指令」自动化，每次佩戴 AirPods 连上 iPhone 时，系统将自动秒开 SpineUp 并开启坐姿守护，无需每次解锁翻找应用。"
        )
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 配置步骤卡片
    private let stepsSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("auto_launch_steps_title", default: "4 步极简配置流程 (仅需 1 分钟)")
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let stepsCardView: UIView = {
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

    private let step1View = SUAutoLaunchStepRowView(
        stepNumber: 1,
        title: SULocalized("auto_launch_step1_title", default: "打开快捷指令 App"),
        detail: SULocalized("auto_launch_step1_desc", default: "在 iPhone 上打开自带的「快捷指令」App，轻点底部中间的「自动化」标签页。")
    )

    private let separator1: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let step2View = SUAutoLaunchStepRowView(
        stepNumber: 2,
        title: SULocalized("auto_launch_step2_title", default: "新建个人自动化"),
        detail: SULocalized("auto_launch_step2_desc", default: "轻点右上角「+」，在触发条件列表中向下滑动并选择「蓝牙」。")
    )

    private let separator2: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let step3View = SUAutoLaunchStepRowView(
        stepNumber: 3,
        title: SULocalized("auto_launch_step3_title", default: "绑定 AirPods 并设为立即运行"),
        detail: SULocalized("auto_launch_step3_desc", default: "在「设备」中勾选您的 AirPods；在下方运行选项中勾选「立即运行」，并关闭「运行时通知」。")
    )

    private let separator3: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let step4View = SUAutoLaunchStepRowView(
        stepNumber: 4,
        title: SULocalized("auto_launch_step4_title", default: "添加打开 SpineUp 操作"),
        detail: SULocalized("auto_launch_step4_desc", default: "点击下一步，选择「新建空白自动化」-> 添加操作，搜索「打开 App」并选择「SpineUp」，点击完成即可！")
    )

    // MARK: - 提示卡片
    private let tipCardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.08)
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.25).cgColor
        return view
    }()

    private let tipLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized(
            "auto_launch_tip",
            default: "💡 极客小贴士：iOS 17 及以上系统的蓝牙自动化完全支持免确认「立即运行」。设置完成后，只要您戴上耳机触发蓝牙连接，手机将自动秒开 SpineUp！"
        )
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemOrange
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 一键前往快捷指令按钮
    private let openShortcutsButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemPurple
        button.tintColor = .white
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let icon = UIImage(systemName: "arrow.up.forward.app.fill", withConfiguration: iconConfig)
        button.setImage(icon, for: .normal)
        button.setTitle("  " + SULocalized("auto_launch_open_shortcuts_btn", default: "立即前往「快捷指令」配置"), for: .normal)
        button.semanticContentAttribute = .forceLeftToRight

        button.layer.shadowColor = UIColor.systemPurple.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        return button
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshLocalizedStrings()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if CommandLine.arguments.contains("-scrollGuideToBottom") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let bottomOffset = CGPoint(x: 0, y: max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.adjustedContentInset.bottom))
                self.scrollView.setContentOffset(bottomOffset, animated: false)
            }
        }
    }

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = SULocalized("auto_launch_nav_title", default: "戴上耳机自动启动")

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 顶部 Hero 卡片
        contentView.addSubview(heroCardView)
        heroCardView.addSubview(heroIconContainer)
        heroIconContainer.addSubview(heroIconImageView)
        heroCardView.addSubview(heroTitleLabel)
        heroCardView.addSubview(heroSubtitleLabel)

        // 步骤卡片
        contentView.addSubview(stepsSectionTitleLabel)
        contentView.addSubview(stepsCardView)
        stepsCardView.addSubview(step1View)
        stepsCardView.addSubview(separator1)
        stepsCardView.addSubview(step2View)
        stepsCardView.addSubview(separator2)
        stepsCardView.addSubview(step3View)
        stepsCardView.addSubview(separator3)
        stepsCardView.addSubview(step4View)

        // 小贴士
        contentView.addSubview(tipCardView)
        tipCardView.addSubview(tipLabel)

        // 底部按钮
        contentView.addSubview(openShortcutsButton)
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

        // Hero 卡片
        heroCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        heroIconContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.size.equalTo(56)
        }

        heroIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(32)
        }

        heroTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(heroIconContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        heroSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(heroTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }

        // 步骤标题与卡片
        stepsSectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(heroCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        stepsCardView.snp.makeConstraints { make in
            make.top.equalTo(stepsSectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        step1View.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        separator1.snp.makeConstraints { make in
            make.top.equalTo(step1View.snp.bottom)
            make.leading.equalToSuperview().offset(48)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        step2View.snp.makeConstraints { make in
            make.top.equalTo(separator1.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        separator2.snp.makeConstraints { make in
            make.top.equalTo(step2View.snp.bottom)
            make.leading.equalToSuperview().offset(48)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        step3View.snp.makeConstraints { make in
            make.top.equalTo(separator2.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        separator3.snp.makeConstraints { make in
            make.top.equalTo(step3View.snp.bottom)
            make.leading.equalToSuperview().offset(48)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        step4View.snp.makeConstraints { make in
            make.top.equalTo(separator3.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 小贴士卡片
        tipCardView.snp.makeConstraints { make in
            make.top.equalTo(stepsCardView.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        tipLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }

        // 底部按钮
        openShortcutsButton.snp.makeConstraints { make in
            make.top.equalTo(tipCardView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().offset(-SULayoutConstants.sectionSpacing * 2)
        }
    }

    override func setupBindings() {
        super.setupBindings()
        openShortcutsButton.addTarget(self, action: #selector(handleOpenShortcuts), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDidChange),
            name: SULocalizationManager.languageDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleOpenShortcuts() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let url = URL(string: "shortcuts://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let appStoreURL = URL(string: "https://apps.apple.com/app/id915254993") {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }

    @objc private func handleLanguageDidChange() {
        refreshLocalizedStrings()
    }

    private func refreshLocalizedStrings() {
        navigationItem.title = SULocalized("auto_launch_nav_title", default: "戴上耳机自动启动")
        heroTitleLabel.text = SULocalized("auto_launch_hero_title", default: "AirPods 入耳 · 自动开练")
        heroSubtitleLabel.text = SULocalized(
            "auto_launch_hero_subtitle",
            default: "利用 iOS 原生「快捷指令」自动化，每次佩戴 AirPods 连上 iPhone 时，系统将自动秒开 SpineUp 并开启坐姿守护，无需每次解锁翻找应用。"
        )
        stepsSectionTitleLabel.text = SULocalized("auto_launch_steps_title", default: "4 步极简配置流程 (仅需 1 分钟)")

        step1View.update(
            title: SULocalized("auto_launch_step1_title", default: "打开快捷指令 App"),
            detail: SULocalized("auto_launch_step1_desc", default: "在 iPhone 上打开自带的「快捷指令」App，轻点底部中间的「自动化」标签页。")
        )
        step2View.update(
            title: SULocalized("auto_launch_step2_title", default: "新建个人自动化"),
            detail: SULocalized("auto_launch_step2_desc", default: "轻点右上角「+」，在触发条件列表中向下滑动并选择「蓝牙」。")
        )
        step3View.update(
            title: SULocalized("auto_launch_step3_title", default: "绑定 AirPods 并设为立即运行"),
            detail: SULocalized("auto_launch_step3_desc", default: "在「设备」中勾选您的 AirPods；在下方运行选项中勾选「立即运行」，并关闭「运行时通知」。")
        )
        step4View.update(
            title: SULocalized("auto_launch_step4_title", default: "添加打开 SpineUp 操作"),
            detail: SULocalized("auto_launch_step4_desc", default: "点击下一步，选择「新建空白自动化」-> 添加操作，搜索「打开 App」并选择「SpineUp」，点击完成即可！")
        )

        tipLabel.text = SULocalized(
            "auto_launch_tip",
            default: "💡 极客小贴士：iOS 17 及以上系统的蓝牙自动化完全支持免确认「立即运行」。设置完成后，只要您戴上耳机触发蓝牙连接，手机将自动秒开 SpineUp！"
        )
        openShortcutsButton.setTitle("  " + SULocalized("auto_launch_open_shortcuts_btn", default: "立即前往「快捷指令」配置"), for: .normal)
    }
}

// MARK: - 步骤子行组件
final class SUAutoLaunchStepRowView: UIView {
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.14)
        label.textColor = .systemPurple
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    init(stepNumber: Int, title: String, detail: String) {
        super.init(frame: .zero)
        badgeLabel.text = "\(stepNumber)"
        titleLabel.text = title
        detailLabel.text = detail
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(badgeLabel)
        addSubview(titleLabel)
        addSubview(detailLabel)

        badgeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(badgeLabel)
            make.leading.equalTo(badgeLabel.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-14)
        }

        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    func update(title: String, detail: String) {
        titleLabel.text = title
        detailLabel.text = detail
    }
}
