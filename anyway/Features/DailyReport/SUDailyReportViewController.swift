//
//  SUDailyReportViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// Tab 2: 骨气战报与健康档案 —— 支持【今日战报】与【本周战报】双周期深度切换
final class SUDailyReportViewController: SUBaseViewController {

    private let viewModel: SUDailyReportViewModel

    // MARK: - 可滑动内容容器
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let contentView = UIView()

    // MARK: - 顶部周期分段控制器 (日 / 周)
    private let periodSegmentedControl: UISegmentedControl = {
        let items = [
            SULocalized("period_daily", default: "今日战报"),
            SULocalized("period_weekly", default: "本周战报")
        ]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = .systemBlue
        sc.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .bold)
        ], for: .selected)
        sc.setTitleTextAttributes([
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .normal)
        return sc
    }()

    // MARK: - 日报视图容器与子卡片
    private let dailyContainerView = UIView()
    private let gradeBannerView = SUGradeBannerCardView()
    private let metricsGridView = SUMetricsGridView()

    private let metaphorCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.04
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 16
        return view
    }()

    private let metaphorIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        iv.image = UIImage(systemName: "square.stack.3d.down.forward.fill", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let metaphorTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("metaphor_title", default: "颈椎受力生活化换算")
        label.font = .systemFont(ofSize: 15, weight: .heavy)
        label.textColor = .label
        return label
    }()

    private let metaphorDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let diagnosisCardView = SUDiagnosisCardView()

    // MARK: - 周报视图容器与子卡片
    private let weeklyContainerView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let weeklyGradeBannerView = SUWeeklyGradeBannerCardView()
    private let weeklyTrendCardView = SUWeeklyTrendCardView()
    private let weeklyMetricsGridView = SUWeeklyMetricsGridView()
    private let weeklyAICardView = SUWeeklyAICardView()

    // MARK: - 底部分享主操作按钮
    private let shareButton: UIButton = {
        var config = UIButton.Configuration.filled()
        var titleAttr = AttributedString(SULocalized("share_report", default: "生成并分享骨气战报"))
        titleAttr.font = UIFont.systemFont(ofSize: 17, weight: .black)
        config.attributedTitle = titleAttr
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        config.image = UIImage(systemName: "square.and.arrow.up.fill", withConfiguration: symbolConfig)
        config.imagePadding = 10
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)

        let button = UIButton(configuration: config)
        button.layer.shadowColor = UIColor.systemBlue.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 14
        return button
    }()

    private var isWeeklyRendered = false

    init(viewModel: SUDailyReportViewModel = SUDailyReportViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = SUDailyReportViewModel()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        periodSegmentedControl.selectedSegmentIndex = 0
        switchPeriodView(to: .daily, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshReport()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if metaphorCardView.bounds.width > 0 && metaphorCardView.bounds.height > 0 {
            metaphorCardView.layer.shadowPath = UIBezierPath(
                roundedRect: metaphorCardView.bounds,
                cornerRadius: SULayoutConstants.cornerRadiusLarge
            ).cgPath
        }
        if shareButton.bounds.width > 0 && shareButton.bounds.height > 0 {
            shareButton.layer.shadowPath = UIBezierPath(
                roundedRect: shareButton.bounds,
                cornerRadius: shareButton.bounds.height / 2
            ).cgPath
        }
    }

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = SULocalized("report_title", default: "骨气健康档案")

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(periodSegmentedControl)

        // 组装日报容器
        contentView.addSubview(dailyContainerView)
        dailyContainerView.addSubview(gradeBannerView)
        dailyContainerView.addSubview(metricsGridView)
        dailyContainerView.addSubview(metaphorCardView)
        metaphorCardView.addSubview(metaphorIconImageView)
        metaphorCardView.addSubview(metaphorTitleLabel)
        metaphorCardView.addSubview(metaphorDescriptionLabel)
        dailyContainerView.addSubview(diagnosisCardView)

        // 组装周报容器
        contentView.addSubview(weeklyContainerView)
        weeklyContainerView.addSubview(weeklyGradeBannerView)
        weeklyContainerView.addSubview(weeklyTrendCardView)
        weeklyContainerView.addSubview(weeklyMetricsGridView)
        weeklyContainerView.addSubview(weeklyAICardView)

        contentView.addSubview(shareButton)
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

        // 顶部周期切换胶囊
        periodSegmentedControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(36)
        }

        // 日报容器约束
        dailyContainerView.snp.makeConstraints { make in
            make.top.equalTo(periodSegmentedControl.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }

        gradeBannerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        metricsGridView.snp.makeConstraints { make in
            make.top.equalTo(gradeBannerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        metaphorCardView.snp.makeConstraints { make in
            make.top.equalTo(metricsGridView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        metaphorIconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(22)
        }

        metaphorTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(metaphorIconImageView.snp.centerY)
            make.leading.equalTo(metaphorIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-16)
        }

        metaphorDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(metaphorIconImageView.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-14)
        }

        diagnosisCardView.snp.makeConstraints { make in
            make.top.equalTo(metaphorCardView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.bottom.equalToSuperview()
        }

        // 周报容器约束
        weeklyContainerView.snp.makeConstraints { make in
            make.top.equalTo(periodSegmentedControl.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }

        weeklyGradeBannerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        weeklyTrendCardView.snp.makeConstraints { make in
            make.top.equalTo(weeklyGradeBannerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        weeklyMetricsGridView.snp.makeConstraints { make in
            make.top.equalTo(weeklyTrendCardView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        weeklyAICardView.snp.makeConstraints { make in
            make.top.equalTo(weeklyMetricsGridView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.bottom.equalToSuperview()
        }

        // 分享按钮约束
        updateShareButtonConstraints(for: .daily)
    }

    private func updateShareButtonConstraints(for period: SUReportPeriodType) {
        shareButton.snp.remakeConstraints { make in
            if period == .daily {
                make.top.equalTo(dailyContainerView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            } else {
                make.top.equalTo(weeklyContainerView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            }
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
            make.height.equalTo(SULayoutConstants.primaryButtonHeight)
            make.bottom.equalToSuperview().offset(-SULayoutConstants.sectionSpacing * 2)
        }
    }

    override func setupBindings() {
        super.setupBindings()

        periodSegmentedControl.addTarget(self, action: #selector(didChangePeriod), for: .valueChanged)
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)

        diagnosisCardView.onReliefGuideTapped = { [weak self] in
            guard let self = self else { return }
            let report = self.viewModel.currentDailyReport
            let reliefVC = SUPostureReliefGuideViewController(
                pitchDeg: 15.0,
                extraLoadKg: 10.0,
                session: report.session,
                persona: report.persona
            )
            let navVC = SUBaseNavigationController(rootViewController: reliefVC)
            if let sheet = navVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            self.present(navVC, animated: true)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDidChange),
            name: SULocalizationManager.languageDidChangeNotification,
            object: nil
        )

        viewModel.onReportUpdated = { [weak self] dailyReport in
            DispatchQueue.main.async {
                self?.renderDailyReport(dailyReport)
            }
        }

        viewModel.onWeeklyReportUpdated = { [weak self] weeklyReport in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.viewModel.selectedPeriod == .weekly || self.isWeeklyRendered {
                    self.renderWeeklyReport(weeklyReport)
                    self.isWeeklyRendered = true
                }
            }
        }

        viewModel.onPeriodChanged = { [weak self] period in
            DispatchQueue.main.async {
                self?.switchPeriodView(to: period, animated: true)
            }
        }

        // 首屏仅渲染用户当前可见的今日战报，延后周报渲染以彻底消除切换卡顿
        renderDailyReport(viewModel.currentDailyReport)
    }

    @objc private func didChangePeriod() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()

        let selected = SUReportPeriodType(rawValue: periodSegmentedControl.selectedSegmentIndex) ?? .daily
        viewModel.selectPeriod(selected)
    }

    private func switchPeriodView(to period: SUReportPeriodType, animated: Bool = true) {
        let isDaily = (period == .daily)

        if !isDaily && !isWeeklyRendered {
            renderWeeklyReport(viewModel.currentWeeklyReport)
            isWeeklyRendered = true
        }

        let updateViews = {
            self.dailyContainerView.isHidden = !isDaily
            self.weeklyContainerView.isHidden = isDaily
            self.updateShareButtonConstraints(for: period)

            var config = self.shareButton.configuration ?? UIButton.Configuration.filled()
            let titleText = isDaily
                ? SULocalized("share_report", default: "生成并分享今日战报")
                : SULocalized("share_weekly_report", default: "生成并分享骨气周报")
            config.attributedTitle = AttributedString(titleText, attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 17, weight: .black)
            ]))
            self.shareButton.configuration = config
        }

        if animated {
            UIView.transition(with: contentView, duration: 0.25, options: [.transitionCrossDissolve]) {
                updateViews()
            }
        } else {
            updateViews()
        }
    }

    private func renderDailyReport(_ report: SUDailyReport) {
        gradeBannerView.configure(with: report.session)
        metricsGridView.configure(with: report.session)

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        metaphorIconImageView.image = UIImage(systemName: report.equivalentItem.iconSystemName, withConfiguration: config)
        metaphorDescriptionLabel.text = report.equivalentItem.descriptionText

        diagnosisCardView.configure(with: report)
    }

    private func renderWeeklyReport(_ report: SUWeeklyReport) {
        weeklyGradeBannerView.configure(with: report)
        weeklyTrendCardView.configure(with: report.dailyBreakdown)
        weeklyMetricsGridView.configure(with: report)
        weeklyAICardView.configure(with: report)
    }

    @objc private func handleLanguageDidChange() {
        navigationItem.title = SULocalized("report_title", default: "骨气健康档案")
        metaphorTitleLabel.text = SULocalized("metaphor_title", default: "颈椎受力生活化换算")

        periodSegmentedControl.setTitle(SULocalized("period_daily", default: "今日战报"), forSegmentAt: 0)
        periodSegmentedControl.setTitle(SULocalized("period_weekly", default: "本周战报"), forSegmentAt: 1)

        let isDaily = (viewModel.selectedPeriod == .daily)
        let titleText = isDaily
            ? SULocalized("share_report", default: "生成并分享今日战报")
            : SULocalized("share_weekly_report", default: "生成并分享骨气周报")
        shareButton.setTitle(titleText, for: .normal)

        metricsGridView.refreshLocalizedStrings()
        diagnosisCardView.refreshLocalizedStrings()

        viewModel.refreshReport()
        renderDailyReport(viewModel.currentDailyReport)
        renderWeeklyReport(viewModel.currentWeeklyReport)
    }

    @objc private func didTapShare() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // 离屏渲染分享卡片 (若为日报使用 SUShareCardView，若为周报离屏渲染 weeklyContainerView 快照)
        let shareImage: UIImage?
        if viewModel.selectedPeriod == .daily {
            let shareCard = SUShareCardView()
            shareCard.configure(with: viewModel.currentDailyReport)
            shareImage = shareCard.renderAsImage()
        } else {
            // 对周报内容进行高质量离屏图像合成
            UIGraphicsBeginImageContextWithOptions(weeklyContainerView.bounds.size, false, 0.0)
            weeklyContainerView.drawHierarchy(in: weeklyContainerView.bounds, afterScreenUpdates: true)
            shareImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }

        if let image = shareImage {
            SUShareSheetHelper.presentShareSheet(
                image: image,
                sourceView: shareButton,
                presenter: self
            )
        }
    }
}
