//
//  SUPostureHazardSheetViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 颈椎承重与 AI 深度体态危害透视弹窗控制器 —— 现代化 Apple Health / 医疗可视化高美感架构
final class SUPostureHazardSheetViewController: SUBaseViewController {

    private let pitchDeg: Double
    private let extraLoadKg: Double
    private let session: SUPostureSession
    private let persona: SUPetPersona

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let contentView = UIView()

    // MARK: 1. 顶部力学冲击核心卡片 (Hero Card)
    private let metricCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.04
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 10
        return view
    }()

    private let aiTagBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.10)
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let aiTagLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("ai_tag_title", default: "✨ AI 实时体态力学推演")
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemIndigo
        return label
    }()

    private let severityBadgeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let severityBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        return label
    }()

    // 左右双列核心数值 (居中对齐)
    private let statsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.tertiarySystemGroupedBackground.withAlphaComponent(0.55)
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let angleTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("hazard_angle_title", default: "当前前倾角度")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let angleValueLabel: UILabel = {
        let label = UILabel()
        if let descriptor = UIFont.systemFont(ofSize: 26, weight: .heavy).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 26)
        } else {
            label.font = .systemFont(ofSize: 26, weight: .heavy)
        }
        label.textAlignment = .center
        return label
    }()

    private let statsDividerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.separator.withAlphaComponent(0.25)
        return view
    }()

    private let loadTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("hazard_load_title", default: "颈椎额外承重")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let loadValueLabel: UILabel = {
        let label = UILabel()
        if let descriptor = UIFont.systemFont(ofSize: 26, weight: .heavy).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 26)
        } else {
            label.font = .systemFont(ofSize: 26, weight: .heavy)
        }
        label.textAlignment = .center
        return label
    }()

    // 生动力学比喻横幅
    private let metaphorContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.08)
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let metaphorIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        iv.image = UIImage(systemName: "scalemass.fill", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let metricComparisonLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // MARK: 2. 拟人桌宠连线督导卡片
    private let petCommentCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 18
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let petAvatarContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        view.layer.cornerRadius = 17
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let petIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemOrange
        return iv
    }()

    private let petHeaderTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13.5, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let petLiveDotView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 3.5
        return view
    }()

    private let petLiveTagLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("hazard_pet_live_tag", default: "实时督导")
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let petBubbleContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.06)
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let petCommentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // MARK: 3. 颜值与体态杀手卡片 (结构化清单)
    private let appearanceCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let appearanceIconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let appearanceIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        iv.image = UIImage(systemName: "face.dashed", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let appearanceHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("hazard_appearance_title", default: "颜值与体态退行透视")
        label.font = .systemFont(ofSize: 15.5, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let appearanceBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("hazard_appearance_tag", default: "无形毁容")
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemOrange
        label.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.cornerCurve = .continuous
        label.clipsToBounds = true
        return label
    }()

    private let appearanceStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fill
        return stack
    }()

    // MARK: 4. 生理损伤时间轴演变 (时间轴步进卡片)
    private let timelineCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let timelineIconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let timelineIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        iv.image = UIImage(systemName: "clock.badge.exclamationmark", withConfiguration: config)
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let timelineHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("hazard_timeline_title", default: "损伤时间轴演变")
        label.font = .systemFont(ofSize: 15.5, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let timelineBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("hazard_timeline_tag", default: "不可逆退行")
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemRed
        label.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.cornerCurve = .continuous
        label.clipsToBounds = true
        return label
    }()

    private let timelineStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fill
        return stack
    }()

    // MARK: 5. 底部主行动操作按钮
    private let actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        var titleAttr = AttributedString(SULocalized("hazard_btn_to_relief", default: "查看减负微操方案"))
        titleAttr.font = .systemFont(ofSize: 16, weight: .bold)
        config.attributedTitle = titleAttr

        let symConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        config.image = UIImage(systemName: "arrow.right.circle.fill", withConfiguration: symConfig)
        config.imagePlacement = .trailing
        config.imagePadding = 8

        let btn = UIButton(configuration: config)
        btn.layer.cornerRadius = 16
        btn.layer.cornerCurve = .continuous
        btn.layer.shadowColor = UIColor.systemGreen.cgColor
        btn.layer.shadowOpacity = 0.25
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 10
        return btn
    }()

    // MARK: - Initializer

    init(
        pitchDeg: Double,
        extraLoadKg: Double,
        session: SUPostureSession = SUPostureSessionManager.shared.getTodaySession(),
        persona: SUPetPersona = SUPetPersonaManager.shared.currentPersona
    ) {
        self.pitchDeg = pitchDeg
        self.extraLoadKg = extraLoadKg
        self.session = session
        self.persona = persona
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.pitchDeg = 0.0
        self.extraLoadKg = 0.0
        self.session = SUPostureSessionManager.shared.getTodaySession()
        self.persona = .worker
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = SULocalized("hazard_sheet_title", default: "颈椎承重与危害透视")

        if navigationController?.viewControllers.first == self {
            let closeBtn = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(didTapClose)
            )
            navigationItem.rightBarButtonItem = closeBtn
        }

        setupStaticData()
        loadAIDiagnosis()
    }

    private func setupStaticData() {
        // 1. 设置数值
        angleValueLabel.text = String(format: "%.1f°", max(0.0, pitchDeg))
        loadValueLabel.text = String(format: "+%.1f kg", max(0.0, extraLoadKg))

        // 2. 根据低头程度渲染警报徽章与统一主题色
        let postureState = SUPostureState.state(forPitchDeg: pitchDeg)
        let themeColor = postureState.themeColor
        let severityText: String
        switch postureState {
        case .severeSlump:
            severityText = SULocalized("hazard_level_severe", default: "高危超负荷 · 立即抬头")
        case .slightSlump:
            severityText = SULocalized("hazard_level_slight", default: "轻度前倾 · 适度微调")
        default:
            severityText = SULocalized("hazard_level_ideal", default: "零负担 · 完美体态")
        }

        angleValueLabel.textColor = themeColor
        loadValueLabel.textColor = themeColor
        severityBadgeView.backgroundColor = postureState.badgeBackgroundColor
        severityBadgeView.layer.borderColor = postureState.badgeBorderColor.cgColor
        severityBadgeLabel.text = severityText
        severityBadgeLabel.textColor = themeColor

        // 3. 桌宠连线卡片初始化
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        petIconImageView.image = UIImage(systemName: persona.iconSystemName, withConfiguration: config)
        petHeaderTitleLabel.text = "\(persona.displayName) · " + SULocalized("hazard_pet_coach_name", default: "实时督导")

        metricComparisonLabel.text = SULocalized("ai_analyzing_hint", default: "✨ AI 正在计算当前姿态力学冲击与体态退行预测...")
    }

    private func loadAIDiagnosis() {
        Task { [weak self] in
            guard let self = self else { return }
            let report = await SUAIPostureAdvisor.shared.analyzeHazard(
                pitchDeg: self.pitchDeg,
                extraLoadKg: self.extraLoadKg,
                session: self.session,
                persona: self.persona
            )

            await MainActor.run {
                self.metricComparisonLabel.text = report.metaphorComparison
                self.updatePetComment(text: report.petComment)
                self.updateAppearanceSection(with: report.appearanceAnalysis)
                self.updateTimelineSection(with: report.timelineProjection)
            }
        }
    }

    private func updatePetComment(text: String) {
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineSpacing = 4.0
        petCommentLabel.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: UIColor.label,
                .paragraphStyle: pStyle
            ]
        )
    }

    // MARK: - 结构化清单与时间轴渲染
    private func parseBulletPoints(_ text: String) -> [(title: String, detail: String)] {
        let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var results: [(title: String, detail: String)] = []
        for rawLine in lines {
            var line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("•") || line.hasPrefix("-") || line.hasPrefix("*") {
                line = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
            if let colonIndex = line.firstIndex(of: "：") {
                let title = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let detail = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                results.append((title, detail))
            } else if let colonIndex = line.firstIndex(of: ":") {
                let title = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let detail = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                results.append((title, detail))
            } else {
                results.append(("", line))
            }
        }
        return results
    }

    private func updateAppearanceSection(with text: String) {
        appearanceStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let items = parseBulletPoints(text)
        guard !items.isEmpty else { return }

        for item in items {
            let itemCard = UIView()
            itemCard.backgroundColor = UIColor.tertiarySystemGroupedBackground.withAlphaComponent(0.65)
            itemCard.layer.cornerRadius = 12
            itemCard.layer.cornerCurve = .continuous

            let titleLabel = UILabel()
            titleLabel.font = .systemFont(ofSize: 13.5, weight: .bold)
            titleLabel.textColor = .label
            titleLabel.text = item.title.isEmpty ? "" : "• \(item.title)"

            let descLabel = UILabel()
            descLabel.numberOfLines = 0
            let pStyle = NSMutableParagraphStyle()
            pStyle.lineSpacing = 3.0
            descLabel.attributedText = NSAttributedString(
                string: item.detail,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12.5, weight: .regular),
                    .foregroundColor: UIColor.secondaryLabel,
                    .paragraphStyle: pStyle
                ]
            )

            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 4

            if !item.title.isEmpty {
                stack.addArrangedSubview(titleLabel)
            }
            stack.addArrangedSubview(descLabel)

            itemCard.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(12)
            }

            appearanceStackView.addArrangedSubview(itemCard)
        }
    }

    private func updateTimelineSection(with text: String) {
        timelineStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let items = parseBulletPoints(text)
        guard !items.isEmpty else { return }

        let stepColors: [UIColor] = [.systemOrange, .systemPink, .systemRed]

        for (index, item) in items.enumerated() {
            let rowView = UIView()

            // 左侧时间轴节点
            let dotView = UIView()
            let tintColor = stepColors[min(index, stepColors.count - 1)]
            dotView.backgroundColor = tintColor
            dotView.layer.cornerRadius = 5
            rowView.addSubview(dotView)

            dotView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(6)
                make.leading.equalToSuperview()
                make.size.equalTo(10)
            }

            // 竖向连接线 (非最后一个节点)
            if index < items.count - 1 {
                let lineView = UIView()
                lineView.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
                rowView.addSubview(lineView)
                lineView.snp.makeConstraints { make in
                    make.top.equalTo(dotView.snp.bottom).offset(4)
                    make.centerX.equalTo(dotView)
                    make.width.equalTo(1.5)
                    make.bottom.equalToSuperview().offset(10)
                }
            }

            // 右侧内容卡片
            let contentContainer = UIView()
            contentContainer.backgroundColor = UIColor.tertiarySystemGroupedBackground.withAlphaComponent(0.65)
            contentContainer.layer.cornerRadius = 12
            contentContainer.layer.cornerCurve = .continuous
            rowView.addSubview(contentContainer)

            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 4

            if !item.title.isEmpty {
                let timeBadge = UILabel()
                timeBadge.font = .systemFont(ofSize: 13, weight: .bold)
                timeBadge.textColor = tintColor
                timeBadge.text = item.title
                stack.addArrangedSubview(timeBadge)
            }

            let descLabel = UILabel()
            descLabel.numberOfLines = 0
            let pStyle = NSMutableParagraphStyle()
            pStyle.lineSpacing = 3.0
            descLabel.attributedText = NSAttributedString(
                string: item.detail,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12.5, weight: .regular),
                    .foregroundColor: UIColor.secondaryLabel,
                    .paragraphStyle: pStyle
                ]
            )
            stack.addArrangedSubview(descLabel)

            contentContainer.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(12)
            }

            contentContainer.snp.makeConstraints { make in
                make.top.bottom.trailing.equalToSuperview()
                make.leading.equalTo(dotView.snp.trailing).offset(12)
            }

            timelineStackView.addArrangedSubview(rowView)
        }
    }

    // MARK: - Layout & Constraints

    override func setupSubviews() {
        super.setupSubviews()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 1. Metric Card
        contentView.addSubview(metricCard)
        metricCard.addSubview(aiTagBadgeView)
        aiTagBadgeView.addSubview(aiTagLabel)
        metricCard.addSubview(severityBadgeView)
        severityBadgeView.addSubview(severityBadgeLabel)

        metricCard.addSubview(statsContainerView)
        statsContainerView.addSubview(angleTitleLabel)
        statsContainerView.addSubview(angleValueLabel)
        statsContainerView.addSubview(statsDividerView)
        statsContainerView.addSubview(loadTitleLabel)
        statsContainerView.addSubview(loadValueLabel)

        metricCard.addSubview(metaphorContainerView)
        metaphorContainerView.addSubview(metaphorIconImageView)
        metaphorContainerView.addSubview(metricComparisonLabel)

        // 2. Pet Comment Card
        contentView.addSubview(petCommentCard)
        petCommentCard.addSubview(petAvatarContainer)
        petAvatarContainer.addSubview(petIconImageView)
        petCommentCard.addSubview(petHeaderTitleLabel)
        petCommentCard.addSubview(petLiveDotView)
        petCommentCard.addSubview(petLiveTagLabel)
        petCommentCard.addSubview(petBubbleContainer)
        petBubbleContainer.addSubview(petCommentLabel)

        // 3. Appearance Card
        contentView.addSubview(appearanceCard)
        appearanceCard.addSubview(appearanceIconContainer)
        appearanceIconContainer.addSubview(appearanceIconImageView)
        appearanceCard.addSubview(appearanceHeaderLabel)
        appearanceCard.addSubview(appearanceBadgeLabel)
        appearanceCard.addSubview(appearanceStackView)

        // 4. Timeline Card
        contentView.addSubview(timelineCard)
        timelineCard.addSubview(timelineIconContainer)
        timelineIconContainer.addSubview(timelineIconImageView)
        timelineCard.addSubview(timelineHeaderLabel)
        timelineCard.addSubview(timelineBadgeLabel)
        timelineCard.addSubview(timelineStackView)

        // 5. Action Button
        contentView.addSubview(actionButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        // 滑动视图铺满全屏，x 从 0 开始，y 从 0 开始，底部从 0 开始，系统自动计算安全区域
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        // 1. Metric Card
        metricCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        aiTagBadgeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.height.equalTo(22)
        }

        aiTagLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }

        severityBadgeView.snp.makeConstraints { make in
            make.centerY.equalTo(aiTagBadgeView)
            make.trailing.equalToSuperview().offset(-14)
            make.height.equalTo(22)
        }

        severityBadgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }

        statsContainerView.snp.makeConstraints { make in
            make.top.equalTo(aiTagBadgeView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(72)
        }

        statsDividerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(14)
            make.width.equalTo(0.5)
        }

        angleTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(6)
            make.trailing.equalTo(statsDividerView.snp.leading).offset(-6)
        }

        angleValueLabel.snp.makeConstraints { make in
            make.top.equalTo(angleTitleLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().offset(6)
            make.trailing.equalTo(statsDividerView.snp.leading).offset(-6)
        }

        loadTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(statsDividerView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-6)
        }

        loadValueLabel.snp.makeConstraints { make in
            make.top.equalTo(loadTitleLabel.snp.bottom).offset(2)
            make.leading.equalTo(statsDividerView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-6)
        }

        metaphorContainerView.snp.makeConstraints { make in
            make.top.equalTo(statsContainerView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }

        metaphorIconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(18)
        }

        metricComparisonLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(metaphorIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-10)
        }

        // 2. Pet Comment Card
        petCommentCard.snp.makeConstraints { make in
            make.top.equalTo(metricCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        petAvatarContainer.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
            make.size.equalTo(34)
        }

        petIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        petHeaderTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(petAvatarContainer)
            make.leading.equalTo(petAvatarContainer.snp.trailing).offset(10)
        }

        petLiveDotView.snp.makeConstraints { make in
            make.centerY.equalTo(petHeaderTitleLabel)
            make.leading.equalTo(petHeaderTitleLabel.snp.trailing).offset(8)
            make.size.equalTo(7)
        }

        petLiveTagLabel.snp.makeConstraints { make in
            make.centerY.equalTo(petLiveDotView)
            make.leading.equalTo(petLiveDotView.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }

        petBubbleContainer.snp.makeConstraints { make in
            make.top.equalTo(petAvatarContainer.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }

        petCommentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        // 3. Appearance Card
        appearanceCard.snp.makeConstraints { make in
            make.top.equalTo(petCommentCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        appearanceIconContainer.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
            make.size.equalTo(28)
        }

        appearanceIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(16)
        }

        appearanceHeaderLabel.snp.makeConstraints { make in
            make.centerY.equalTo(appearanceIconContainer)
            make.leading.equalTo(appearanceIconContainer.snp.trailing).offset(10)
        }

        appearanceBadgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(appearanceHeaderLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.height.equalTo(20)
            make.width.equalTo(58)
        }

        appearanceStackView.snp.makeConstraints { make in
            make.top.equalTo(appearanceIconContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }

        // 4. Timeline Card
        timelineCard.snp.makeConstraints { make in
            make.top.equalTo(appearanceCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        timelineIconContainer.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
            make.size.equalTo(28)
        }

        timelineIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(16)
        }

        timelineHeaderLabel.snp.makeConstraints { make in
            make.centerY.equalTo(timelineIconContainer)
            make.leading.equalTo(timelineIconContainer.snp.trailing).offset(10)
        }

        timelineBadgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(timelineHeaderLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.height.equalTo(20)
            make.width.equalTo(68)
        }

        timelineStackView.snp.makeConstraints { make in
            make.top.equalTo(timelineIconContainer.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }

        // 5. Action Button (位于滑动内容底部，与安全区域平滑对齐)
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(timelineCard.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(SULayoutConstants.primaryButtonHeight)
            make.bottom.equalToSuperview().offset(-36)
        }
    }

    override func setupBindings() {
        super.setupBindings()
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
    }

    @objc private func didTapClose() {
        SUAudioFeedbackManager.shared.triggerHapticLightTap()
        dismiss(animated: true)
    }

    @objc private func didTapActionButton() {
        SUAudioFeedbackManager.shared.triggerHapticLightTap()
        let reliefVC = SUPostureReliefGuideViewController(pitchDeg: pitchDeg, extraLoadKg: extraLoadKg)
        if let nav = navigationController {
            nav.pushViewController(reliefVC, animated: true)
        } else {
            let navVC = SUBaseNavigationController(rootViewController: reliefVC)
            present(navVC, animated: true)
        }
    }
}
