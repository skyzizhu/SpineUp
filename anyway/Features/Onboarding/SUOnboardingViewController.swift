//
//  SUOnboardingViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit
import CoreMotion

/// 首次启动引导流控制器 —— 包含产品概念、权限申请说明、佩戴引导与校准教学
final class SUOnboardingViewController: SUBaseViewController {

    var onOnboardingCompleted: (() -> Void)?

    private var currentPage: Int = 0

    private struct PageData {
        let title: String
        let subtitle: String
        let iconName: String
        let buttonTitle: String
    }

    private var pages: [PageData] {
        return [
            PageData(
                title: SULocalized("onboarding_title_1", default: "让 AirPods 成为你的\n全天候脊椎守护兽"),
                subtitle: SULocalized("onboarding_sub_1", default: "【SpineUp 能为你做什么】\n• 告别久坐低头族：实时监测头部俯仰与前倾姿态，将前倾倾角精准换算为颈椎额外受力当量（低头 60° 相当于颈椎承受 27kg 压迫！），预防富贵包与体态僵硬。\n• 拟人化桌宠陪伴：元气宠物在后台默默守护，体态不良时即时化身软泥怪提醒，拒绝枯燥说教。\n\n【需要连接什么设备】\n• 支援空间音频的 Apple 耳机：AirPods Pro（全部代际）、AirPods 3/4、AirPods Max 及兼容 Beats 耳机。\n• 零额外硬件负担：无需额外购买专用穿戴硬件，佩戴日常听歌开会的耳机即可无感开启守护。"),
                iconName: "airpodspro",
                buttonTitle: SULocalized("onboarding_btn_1", default: "了解运动权限与核心原理")
            ),
            PageData(
                title: SULocalized("onboarding_title_2", default: "开启耳机运动权限\n实现毫秒级空间感知"),
                subtitle: SULocalized("onboarding_sub_2", default: "【为什么需要运动传感器权限】\n• 空间姿态核心驱动：SpineUp 需要访问 iOS「运动与健身」权限，调用耳机内置陀螺仪与加速度计，以 60Hz 采样率感知头部细微前倾与偏转。\n\n【连接后能做什么】\n• 毫秒级防低头预警：当头部前倾超出设定阈值时，通过轻柔触感、提示音或宠物语音轻声唤醒，在专注工作中无感重置健康坐姿。\n• 100% 设备端本地运算：所有传感器运动轨迹均在 iPhone 本地即时计算，绝不上传私密运动数据，完全保障隐私安全。"),
                iconName: "gyroscope",
                buttonTitle: SULocalized("onboarding_btn_2", default: "开启耳机运动权限并继续")
            ),
            PageData(
                title: SULocalized("onboarding_title_3", default: "戴上耳机一键校准\n开启趣味减负之旅"),
                subtitle: SULocalized("onboarding_sub_3", default: "【如何使用与零点校准】\n• 戴好耳机端坐舒展：双耳戴上 AirPods，调整到您感觉自然、舒适挺拔的坐姿或站姿。\n• 一键锁定专属零点：轻点「一键校准」即可锁定基准，随时自适应不同办公椅与工位环境。\n\n【连接后还可以做什么】\n• 30 秒微操减负回血：疲劳时跟随宠物做一次「收下巴」或「W展肩」微操，即刻卸下颈椎额外负荷并赚取能量币。\n• 每日体态病历诊断：下班生成当日挺拔优秀率、疲劳时段与生活化承重比喻，见证脊椎每一天的蜕变！"),
                iconName: "figure.stand",
                buttonTitle: SULocalized("onboarding_btn_3", default: "开启我的脊椎守护")
            )
        ]
    }

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = false
        return sv
    }()

    private let contentView = UIView()

    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        view.layer.cornerRadius = 24
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemBlue
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let detailCardView = SUOnboardingDetailCardView()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .systemBlue
        pc.pageIndicatorTintColor = .systemGray4
        pc.isUserInteractionEnabled = false
        return pc
    }()

    private let actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        let button = UIButton(configuration: config)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.5, weight: .semibold)
        button.layer.shadowColor = UIColor.systemBlue.cgColor
        button.layer.shadowOpacity = 0.28
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.masksToBounds = false
        return button
    }()

    override func setupSubviews() {
        super.setupSubviews()
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        iconContainerView.addSubview(iconImageView)
        contentView.addSubview(iconContainerView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailCardView)

        view.addSubview(pageControl)
        view.addSubview(actionButton)

        pageControl.numberOfPages = pages.count
        updatePageContent()
    }

    override func setupConstraints() {
        super.setupConstraints()

        actionButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(SULayoutConstants.horizontalPadding * 1.5)
            make.height.equalTo(SULayoutConstants.primaryButtonHeight)
        }

        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(actionButton.snp.top).offset(-14)
            make.centerX.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(pageControl.snp.top).offset(-10)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        iconContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(44)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainerView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        detailCardView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    override func setupBindings() {
        super.setupBindings()
        actionButton.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)
    }

    private func updatePageContent() {
        let data = pages[currentPage]
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        iconImageView.image = UIImage(systemName: data.iconName, withConfiguration: config)

        let titleStyle = NSMutableParagraphStyle()
        titleStyle.lineSpacing = 4.0
        titleStyle.alignment = .center
        titleLabel.attributedText = NSAttributedString(
            string: data.title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.label,
                .paragraphStyle: titleStyle
            ]
        )

        detailCardView.configure(with: data.subtitle)
        actionButton.setTitle(data.buttonTitle, for: .normal)
        pageControl.currentPage = currentPage
    }

    @objc private func didTapAction() {
        if currentPage == 1 {
            // 触发系统耳机运动传感器权限弹窗
            #if targetEnvironment(simulator)
            let motionService: SUMotionServiceProtocol = SUMockMotionManager()
            #else
            let motionService: SUMotionServiceProtocol = SUHeadphoneMotionManager()
            #endif
            motionService.requestMotionAuthorization(completion: nil)
        }

        if currentPage < pages.count - 1 {
            currentPage += 1
            UIView.transition(with: view, duration: 0.35, options: .transitionCrossDissolve, animations: {
                self.updatePageContent()
            })
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        SUUserDefaultsManager.shared.hasCompletedOnboarding = true
        onOnboardingCompleted?()
        dismiss(animated: true)
    }
}

// MARK: - 引导页结构化特性卡片 (Apple HIG 现代卡片排版)

final class SUOnboardingDetailCardView: UIView {

    private struct ParsedSection {
        let title: String?
        let items: [ParsedItem]
    }

    private struct ParsedItem {
        let title: String?
        let detail: String
    }

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        layer.borderWidth = 0.0

        // 淡雅柔和的弥散微阴影 (Clean, subtle ambient shadow)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 16
        layer.masksToBounds = false

        addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 22, left: 20, bottom: 22, right: 20))
        }
    }

    func configure(with rawText: String) {
        contentStackView.arrangedSubviews.forEach { view in
            contentStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let sections = parseSections(from: rawText)
        for (index, section) in sections.enumerated() {
            let sectionView = buildSectionView(for: section)
            contentStackView.addArrangedSubview(sectionView)

            if index < sections.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor.separator.withAlphaComponent(0.15)
                divider.snp.makeConstraints { make in
                    make.height.equalTo(0.35)
                }
                contentStackView.addArrangedSubview(divider)
            }
        }
    }

    private func buildSectionView(for section: ParsedSection) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 12
        container.alignment = .fill
        container.distribution = .fill

        let theme = themeFor(header: section.title)

        // 1. 结构化模块标题头 (纯净聚焦无冗余标签)
        if let titleText = section.title {
            let headerStack = UIStackView()
            headerStack.axis = .horizontal
            headerStack.spacing = 10
            headerStack.alignment = .center

            // 图标徽章容器
            let iconBadge = UIView()
            iconBadge.backgroundColor = theme.tint.withAlphaComponent(0.12)
            iconBadge.layer.cornerRadius = 8
            iconBadge.layer.cornerCurve = .continuous
            iconBadge.snp.makeConstraints { make in
                make.width.height.equalTo(26)
            }

            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            let iconView = UIImageView(image: UIImage(systemName: theme.icon, withConfiguration: symbolConfig))
            iconView.tintColor = theme.tint
            iconView.contentMode = .scaleAspectFit
            iconBadge.addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            headerStack.addArrangedSubview(iconBadge)

            // 标题文字
            let titleLabel = UILabel()
            titleLabel.text = titleText
            titleLabel.font = UIFont.systemFont(ofSize: 15.5, weight: .bold)
            titleLabel.textColor = .label
            headerStack.addArrangedSubview(titleLabel)

            container.addArrangedSubview(headerStack)
        }

        // 2. 逐条说明列表项
        let itemsStack = UIStackView()
        itemsStack.axis = .vertical
        itemsStack.spacing = 12
        itemsStack.alignment = .fill
        itemsStack.distribution = .fill

        for item in section.items {
            let rowView = UIView()

            let dot = UIView()
            dot.backgroundColor = theme.tint.withAlphaComponent(0.85)
            dot.layer.cornerRadius = 2.5
            rowView.addSubview(dot)

            let label = UILabel()
            label.numberOfLines = 0
            label.attributedText = formatItemText(title: item.title, detail: item.detail, tint: theme.tint)
            rowView.addSubview(label)

            dot.snp.makeConstraints { make in
                make.width.height.equalTo(5)
                make.leading.equalToSuperview()
                make.top.equalTo(label.snp.top).offset(7)
            }

            label.snp.makeConstraints { make in
                make.top.bottom.trailing.equalToSuperview()
                make.leading.equalTo(dot.snp.trailing).offset(10)
            }

            itemsStack.addArrangedSubview(rowView)
        }

        container.addArrangedSubview(itemsStack)
        return container
    }

    private func formatItemText(title: String?, detail: String, tint: UIColor) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4.0
        paragraphStyle.paragraphSpacing = 2.0

        let fullAttr = NSMutableAttributedString()

        if let title = title, !title.isEmpty {
            let titleAttr = NSAttributedString(
                string: "\(title)  ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 13.5, weight: .semibold),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: paragraphStyle
                ]
            )
            fullAttr.append(titleAttr)
        }

        let detailAttr = NSMutableAttributedString(
            string: detail,
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: paragraphStyle
            ]
        )

        // 关键指标数值微强调高亮（如 60°、27kg、60Hz、100%、30 秒）
        let pattern = #"(\d+(\.\d+)?(°|kg|Hz|%|秒)|\b100%\b|\b60°\b|\b27kg\b|\b60Hz\b|\b30\s*秒)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: detail, options: [], range: NSRange(location: 0, length: detail.utf16.count))
            for match in matches {
                detailAttr.addAttributes([
                    .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                    .foregroundColor: UIColor.label
                ], range: match.range)
            }
        }

        fullAttr.append(detailAttr)
        return fullAttr
    }

    private func parseSections(from rawText: String) -> [ParsedSection] {
        let rawBlocks = rawText.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var result: [ParsedSection] = []

        for block in rawBlocks {
            let lines = block.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !lines.isEmpty else { continue }

            var sectionTitle: String? = nil
            var itemLines: [String] = []

            let firstLine = lines[0]
            if (firstLine.hasPrefix("【") && firstLine.hasSuffix("】")) ||
               (firstLine.hasPrefix("[") && firstLine.hasSuffix("]")) {
                let dropLeading = firstLine.dropFirst()
                sectionTitle = String(dropLeading.dropLast()).trimmingCharacters(in: .whitespaces)
                itemLines = Array(lines.dropFirst())
            } else {
                itemLines = lines
            }

            var items: [ParsedItem] = []
            for line in itemLines {
                var cleaned = line
                while cleaned.hasPrefix("•") || cleaned.hasPrefix("-") || cleaned.hasPrefix("·") || cleaned.hasPrefix("*") || cleaned.hasPrefix(" ") {
                    cleaned = String(cleaned.dropFirst())
                }
                cleaned = cleaned.trimmingCharacters(in: .whitespaces)
                guard !cleaned.isEmpty else { continue }

                if let colonRange = cleaned.range(of: "：") {
                    let titlePart = String(cleaned[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let descPart = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    items.append(ParsedItem(title: titlePart.isEmpty ? nil : titlePart, detail: descPart))
                } else if let colonRange = cleaned.range(of: ": ") {
                    let titlePart = String(cleaned[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let descPart = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    items.append(ParsedItem(title: titlePart.isEmpty ? nil : titlePart, detail: descPart))
                } else if let dashRange = cleaned.range(of: " — ") {
                    let titlePart = String(cleaned[..<dashRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let descPart = String(cleaned[dashRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    items.append(ParsedItem(title: titlePart.isEmpty ? nil : titlePart, detail: descPart))
                } else {
                    items.append(ParsedItem(title: nil, detail: cleaned))
                }
            }

            if sectionTitle != nil || !items.isEmpty {
                result.append(ParsedSection(title: sectionTitle, items: items))
            }
        }

        return result
    }

    private func themeFor(header: String?) -> (icon: String, badge: String?, tint: UIColor) {
        guard let header = header?.lowercased() else {
            return ("sparkles", nil, .systemBlue)
        }
        if header.contains("连接后能做") || header.contains("once connected") {
            return ("bell.badge.fill", SULocalized("onboarding_badge_alert", default: "预警与隐私"), .systemGreen)
        } else if header.contains("还可以") || header.contains("more") || header.contains("陪伴") {
            return ("figure.mind.and.body", SULocalized("onboarding_badge_lifestyle", default: "健康陪伴"), .systemPurple)
        } else if header.contains("校准") || header.contains("calibrate") || header.contains("使用") || header.contains("how") {
            return ("scope", SULocalized("onboarding_badge_calibrate", default: "零点校准"), .systemOrange)
        } else if header.contains("权限") || header.contains("permission") || header.contains("为什么") || header.contains("why") {
            return ("shield.lefthalf.filled", SULocalized("onboarding_badge_permission", default: "传感器权限"), .systemTeal)
        } else if header.contains("设备") || header.contains("connect") || header.contains("耳机") {
            return ("airpodspro", SULocalized("onboarding_badge_devices", default: "兼容设备"), .systemIndigo)
        } else if header.contains("做什么") || header.contains("what") || header.contains("功能") {
            return ("sparkles", SULocalized("onboarding_badge_features", default: "核心功能"), .systemBlue)
        } else if header.contains("安全") || header.contains("隐私") || header.contains("privacy") {
            return ("lock.shield.fill", SULocalized("onboarding_badge_privacy", default: "隐私安全"), .systemGreen)
        } else {
            return ("star.fill", nil, .systemBlue)
        }
    }
}
