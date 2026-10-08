//
//  SUDailyReportViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// Tab 2: 今日骨气病历单与战报 —— 科学承重换算、AI趣味医学诊断、原生高颜值分享卡片
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

    // MARK: - 独立封装子视图
    private let gradeBannerView = SUGradeBannerCardView()
    private let metricsGridView = SUMetricsGridView()

    // MARK: - 趣味力学换算横幅
    private let metaphorCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemOrange.withAlphaComponent(0.08)
        view.layer.cornerRadius = SULayoutConstants.cornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let metaphorIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        iv.image = UIImage(systemName: "square.stack.3d.down.forward.fill", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let metaphorTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("metaphor_title", default: "颈椎受力生活化换算")
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .systemOrange
        return label
    }()

    private let metaphorDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // MARK: - AI 病历单卡片
    private let diagnosisCardView = SUDiagnosisCardView()

    // MARK: - 底部分享主操作按钮
    private let shareButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = SULocalized("share_report", default: "生成并分享骨气战报")
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        config.image = UIImage(systemName: "square.and.arrow.up.fill", withConfiguration: symbolConfig)
        config.imagePadding = 8
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        let button = UIButton(configuration: config)
        return button
    }()

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshReport()
    }

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = SULocalized("report_title", default: "今日骨气战报")

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(gradeBannerView)
        contentView.addSubview(metricsGridView)

        contentView.addSubview(metaphorCardView)
        metaphorCardView.addSubview(metaphorIconImageView)
        metaphorCardView.addSubview(metaphorTitleLabel)
        metaphorCardView.addSubview(metaphorDescriptionLabel)

        contentView.addSubview(diagnosisCardView)
        contentView.addSubview(shareButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        // 遵循规则 7 & 9：贯穿边缘铺满，系统管理安全区
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        gradeBannerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(SULayoutConstants.verticalSpacing)
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
        }

        shareButton.snp.makeConstraints { make in
            make.top.equalTo(diagnosisCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
            make.height.equalTo(SULayoutConstants.primaryButtonHeight)
            make.bottom.equalToSuperview().offset(-SULayoutConstants.sectionSpacing * 2)
        }
    }

    override func setupBindings() {
        super.setupBindings()

        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDidChange),
            name: SULocalizationManager.languageDidChangeNotification,
            object: nil
        )

        viewModel.onReportUpdated = { [weak self] report in
            DispatchQueue.main.async {
                self?.renderReport(report)
            }
        }

        renderReport(viewModel.currentReport)
    }

    private func renderReport(_ report: SUDailyReport) {
        gradeBannerView.configure(with: report.session)
        metricsGridView.configure(with: report.session)

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        metaphorIconImageView.image = UIImage(systemName: report.equivalentItem.iconSystemName, withConfiguration: config)
        metaphorDescriptionLabel.text = report.equivalentItem.descriptionText

        diagnosisCardView.configure(with: report)
    }

    @objc private func handleLanguageDidChange() {
        navigationItem.title = SULocalized("report_title", default: "今日骨气战报")
        metaphorTitleLabel.text = SULocalized("metaphor_title", default: "颈椎受力生活化换算")
        shareButton.setTitle(SULocalized("share_report", default: "生成并分享骨气战报"), for: .normal)
        metricsGridView.refreshLocalizedStrings()
        diagnosisCardView.refreshLocalizedStrings()
        viewModel.refreshReport()
        renderReport(viewModel.currentReport)
    }

    @objc private func didTapShare() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // 离屏渲染高质量高颜值分享卡片
        let shareCard = SUShareCardView()
        shareCard.configure(with: viewModel.currentReport)
        let shareImage = shareCard.renderAsImage()

        // 调起系统原生分享面板
        SUShareSheetHelper.presentShareSheet(
            image: shareImage,
            sourceView: shareButton,
            presenter: self
        )
    }

    override func adaptLayoutForSize(_ size: CGSize) {
        super.adaptLayoutForSize(size)
        let isDualPane = size.width >= SULayoutConstants.duoSplitBreakpointWidth
        if isDualPane {
            let layout = SUDuoLayoutHelper.splitColumnLayout(totalWidth: size.width)
            // iPhone Duo 展开态：左侧评级与指标，右侧换算、病历与分享按钮
            gradeBannerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(SULayoutConstants.verticalSpacing)
                make.leading.equalToSuperview().offset(SULayoutConstants.horizontalPadding)
                make.width.equalTo(layout.leftWidth)
            }
            metricsGridView.snp.remakeConstraints { make in
                make.top.equalTo(gradeBannerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.equalToSuperview().offset(SULayoutConstants.horizontalPadding)
                make.width.equalTo(layout.leftWidth)
                make.bottom.lessThanOrEqualToSuperview().offset(-SULayoutConstants.sectionSpacing)
            }
            metaphorCardView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(SULayoutConstants.verticalSpacing)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
                make.width.equalTo(layout.rightWidth)
            }
            diagnosisCardView.snp.remakeConstraints { make in
                make.top.equalTo(metaphorCardView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
                make.width.equalTo(layout.rightWidth)
            }
            shareButton.snp.remakeConstraints { make in
                make.top.equalTo(diagnosisCardView.snp.bottom).offset(SULayoutConstants.verticalSpacing * 2)
                make.trailing.equalToSuperview().offset(-SULayoutConstants.horizontalPadding)
                make.width.equalTo(layout.rightWidth)
                make.height.equalTo(SULayoutConstants.primaryButtonHeight)
                make.bottom.equalToSuperview().offset(-SULayoutConstants.sectionSpacing * 2)
            }
        } else {
            // 经典单列排版
            gradeBannerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(SULayoutConstants.verticalSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            metricsGridView.snp.remakeConstraints { make in
                make.top.equalTo(gradeBannerView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            metaphorCardView.snp.remakeConstraints { make in
                make.top.equalTo(metricsGridView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            diagnosisCardView.snp.remakeConstraints { make in
                make.top.equalTo(metaphorCardView.snp.bottom).offset(SULayoutConstants.verticalSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            }
            shareButton.snp.remakeConstraints { make in
                make.top.equalTo(diagnosisCardView.snp.bottom).offset(SULayoutConstants.sectionSpacing)
                make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 2)
                make.height.equalTo(SULayoutConstants.primaryButtonHeight)
                make.bottom.equalToSuperview().offset(-SULayoutConstants.sectionSpacing * 2)
            }
        }
    }
}
