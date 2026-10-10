//
//  SUPostureReliefGuideViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

// MARK: - 单个减负动作/指南卡片组件
private final class SUReliefActionCardView: UIView {

    private let themeColor: UIColor

    // 顶部 Header 元素
    private let iconBadgeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        if let descriptor = UIFont.systemFont(ofSize: 16, weight: .bold).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            label.font = .systemFont(ofSize: 16, weight: .bold)
        }
        label.textColor = .label
        return label
    }()

    private let tagBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }()

    private let timeCapsuleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10.5, weight: .semibold)
        label.textColor = .tertiaryLabel
        label.textAlignment = .right
        return label
    }()

    // 正文指引列表（支持小圆点悬挂缩进）
    private let stepsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()

    private let mainContentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        return stack
    }()

    // AI 定制建议小贴片
    private let aiTipContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.isHidden = true
        return view
    }()

    private let aiTipHeaderIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        iv.image = UIImage(systemName: "sparkles", withConfiguration: config)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let aiTipHeaderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.text = "AI 私教针对定制"
        return label
    }()

    private let aiTipContentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12.5, weight: .medium)
        label.textColor = UIColor.label.withAlphaComponent(0.9)
        label.numberOfLines = 0
        return label
    }()

    init(
        iconName: String,
        themeColor: UIColor,
        title: String,
        tag: String,
        timeBadge: String,
        steps: String
    ) {
        self.themeColor = themeColor
        super.init(frame: .zero)

        setupCardStyle()
        setupSubviews()
        setupConstraints()

        // 填充内容
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        iconImageView.tintColor = themeColor
        iconBadgeView.backgroundColor = themeColor.withAlphaComponent(0.12)

        titleLabel.text = title
        tagBadgeLabel.text = "  \(tag)  "
        tagBadgeLabel.textColor = themeColor
        tagBadgeLabel.backgroundColor = themeColor.withAlphaComponent(0.08)

        timeCapsuleLabel.text = timeBadge

        // 构建支持悬挂缩进的小圆点列表
        configureSteps(steps)

        aiTipHeaderIcon.tintColor = themeColor
        aiTipHeaderLabel.textColor = themeColor
        aiTipContainerView.backgroundColor = themeColor.withAlphaComponent(0.05)
        aiTipContainerView.layer.borderColor = themeColor.withAlphaComponent(0.15).cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCardStyle() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        layer.cornerCurve = .continuous
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.withAlphaComponent(0.18).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
    }

    private func setupSubviews() {
        addSubview(iconBadgeView)
        iconBadgeView.addSubview(iconImageView)

        addSubview(titleLabel)
        addSubview(tagBadgeLabel)
        addSubview(timeCapsuleLabel)

        addSubview(mainContentStackView)
        mainContentStackView.addArrangedSubview(stepsStackView)
        mainContentStackView.addArrangedSubview(aiTipContainerView)

        aiTipContainerView.addSubview(aiTipHeaderIcon)
        aiTipContainerView.addSubview(aiTipHeaderLabel)
        aiTipContainerView.addSubview(aiTipContentLabel)
    }

    private func setupConstraints() {
        iconBadgeView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.size.equalTo(32)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconBadgeView.snp.centerY)
            make.leading.equalTo(iconBadgeView.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(timeCapsuleLabel.snp.leading).offset(-8)
        }

        timeCapsuleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconBadgeView.snp.centerY)
            make.trailing.equalToSuperview().offset(-16)
        }

        tagBadgeLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBadgeView.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(20)
        }

        mainContentStackView.snp.makeConstraints { make in
            make.top.equalTo(tagBadgeLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        aiTipHeaderIcon.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(10)
            make.size.equalTo(12)
        }

        aiTipHeaderLabel.snp.makeConstraints { make in
            make.centerY.equalTo(aiTipHeaderIcon.snp.centerY)
            make.leading.equalTo(aiTipHeaderIcon.snp.trailing).offset(4)
        }

        aiTipContentLabel.snp.makeConstraints { make in
            make.top.equalTo(aiTipHeaderIcon.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    /// 解析列表并构建完美悬挂缩进（Hanging Indent）条目
    private func configureSteps(_ steps: String) {
        stepsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let lines = steps.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isBullet = trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("·")
            let cleanText = isBullet ? trimmed.replacingOccurrences(of: "^[•\\-·]\\s*", with: "", options: .regularExpression) : trimmed

            let rowView = UIView()

            let dotView = UIView()
            dotView.backgroundColor = themeColor
            dotView.layer.cornerRadius = 2.5
            dotView.layer.cornerCurve = .continuous
            dotView.isHidden = !isBullet
            rowView.addSubview(dotView)

            let label = UILabel()
            label.numberOfLines = 0
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 3.5
            label.attributedText = NSAttributedString(
                string: cleanText,
                attributes: [
                    .paragraphStyle: paragraphStyle,
                    .font: UIFont.systemFont(ofSize: 13.5, weight: .regular),
                    .foregroundColor: UIColor.secondaryLabel
                ]
            )
            rowView.addSubview(label)

            dotView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(7)
                make.leading.equalToSuperview().offset(2)
                make.size.equalTo(5)
            }

            label.snp.makeConstraints { make in
                make.top.bottom.trailing.equalToSuperview()
                if isBullet {
                    make.leading.equalTo(dotView.snp.trailing).offset(9)
                } else {
                    make.leading.equalToSuperview()
                }
            }

            stepsStackView.addArrangedSubview(rowView)
        }
    }

    func setAITip(_ tip: String) {
        guard !tip.isEmpty else { return }
        aiTipContainerView.isHidden = false

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3.5
        aiTipContentLabel.attributedText = NSAttributedString(
            string: tip,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.systemFont(ofSize: 12.5, weight: .medium),
                .foregroundColor: UIColor.label.withAlphaComponent(0.9)
            ]
        )

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }

    func updateDynamicColors() {
        layer.borderColor = UIColor.separator.withAlphaComponent(0.18).cgColor
        aiTipContainerView.layer.borderColor = themeColor.withAlphaComponent(0.15).cgColor
    }
}

// MARK: - 主视图控制器
/// 30 秒办公室减负微操与 AI 定制人体工学指南
final class SUPostureReliefGuideViewController: SUBaseViewController {

    private let pitchDeg: Double
    private let extraLoadKg: Double
    private let session: SUPostureSession
    private let persona: SUPetPersona

    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 30
    private var isPracticing: Bool = false

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let contentView = UIView()

    // 顶部 AI 急救处方 Header 卡片
    private let headerCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.08)
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.2).cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.03
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 10
        return view
    }()

    private let aiPrescriptionBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.14)
        view.layer.cornerRadius = 8
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let aiPrescriptionBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("ai_prescription_badge", default: "✨ AI 专属急救处方 · 毫秒级卸荷")
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemGreen
        return label
    }()

    private let loadOffsetPillLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10.5, weight: .bold)
        label.textColor = .systemGreen
        label.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }()

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("relief_guide_header_title", default: "30秒办公室减负微操")
        if let descriptor = UIFont.systemFont(ofSize: 20, weight: .heavy).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            label.font = .systemFont(ofSize: 20, weight: .heavy)
        }
        label.textColor = .label
        return label
    }()

    private let diagnosisContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.label.withAlphaComponent(0.03)
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let headerSubLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("relief_guide_header_sub", default: "坐着就能做 · 不尴尬 · 毫秒级卸下颈椎额外承重")
        label.font = .systemFont(ofSize: 12.5, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // 动作 1：麦肯基收下巴
    private let action1Card = SUReliefActionCardView(
        iconName: "figure.mind.and.body",
        themeColor: .systemOrange,
        title: SULocalized("relief_action1_title", default: "1. 麦肯基收下巴（Chin Tuck）"),
        tag: SULocalized("relief_action1_tag", default: "告别乌龟颈 & 激活颈深肌"),
        timeBadge: "15 秒",
        steps: SULocalized("relief_action1_steps", default: "• 坐正平视正前方，背部放松微靠。\n• 食指轻触下巴，水平向后平行推送（挤出双下巴感）。\n• 感受后颈温和拉伸，保持 3 秒，重复 5~8 次。")
    )

    // 动作 2：W 展肩夹背
    private let action2Card = SUReliefActionCardView(
        iconName: "figure.flexibility",
        themeColor: .systemBlue,
        title: SULocalized("relief_action2_title", default: "2. W 展肩夹背法（W-Stretches）"),
        tag: SULocalized("relief_action2_tag", default: "打开胸椎 & 击碎富贵包"),
        timeBadge: "15 秒",
        steps: SULocalized("relief_action2_steps", default: "• 双臂大臂贴紧肋侧，小臂向上屈起呈「W」形。\n• 双肩自然下沉缓慢展开，将两块肩胛骨往中间夹紧。\n• 配合深吸气停留 5 秒后呼气放松，重复 4~6 次。")
    )

    // 建议 3：工位环境优化
    private let action3Card = SUReliefActionCardView(
        iconName: "desktopcomputer",
        themeColor: .systemIndigo,
        title: SULocalized("relief_action3_title", default: "3. 工位人体工学黄金原则"),
        tag: SULocalized("relief_action3_tag", default: "物理根源消除低头诱因"),
        timeBadge: "日常习惯",
        steps: SULocalized("relief_action3_steps", default: "• 视线平齐：笔记本用支架垫高，屏幕上 1/3 与视线平行。\n• 手肘 90°：调节工位椅高度，手肘呈直角自然搭放桌面。\n• 腰部支撑：臀部坐满椅底，腰部悬空处加一个小靠垫。")
    )

    // 桌宠专属寄语卡片
    private let petEncouragementCard: UIView = {
        let view = UIView()
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.isHidden = true
        return view
    }()

    private let petIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let petNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        return label
    }()

    private let petEncouragementLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // 底部打卡互动按钮
    private let practiceButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(SULocalized("relief_btn_start", default: "开始 30 秒微操 (+5 骨气能量)"), for: .normal)
        if let descriptor = UIFont.systemFont(ofSize: 16.5, weight: .bold).fontDescriptor.withDesign(.rounded) {
            btn.titleLabel?.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            btn.titleLabel?.font = .systemFont(ofSize: 16.5, weight: .bold)
        }
        btn.backgroundColor = .systemGreen
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = SULayoutConstants.primaryButtonHeight / 2.0
        btn.layer.cornerCurve = .continuous
        btn.layer.shadowColor = UIColor.systemGreen.cgColor
        btn.layer.shadowOpacity = 0.32
        btn.layer.shadowOffset = CGSize(width: 0, height: 6)
        btn.layer.shadowRadius = 14
        return btn
    }()

    // MARK: - Initializer

    init(
        pitchDeg: Double = 0.0,
        extraLoadKg: Double = 0.0,
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

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = SULocalized("relief_guide_title", default: "身体保护与微操建议")

        // 导航栏右侧原生圆形关闭按钮
        let closeBtn = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose)
        )
        navigationItem.rightBarButtonItem = closeBtn

        setupPetCardStyle()

        if extraLoadKg > 0.0 {
            let state = SUPostureState.state(forPitchDeg: pitchDeg)
            loadOffsetPillLabel.text = String(format: "  对冲 +%.1fkg 剪切应力  ", extraLoadKg)
            loadOffsetPillLabel.textColor = state.themeColor
            loadOffsetPillLabel.backgroundColor = state.badgeBackgroundColor
            loadOffsetPillLabel.isHidden = false
        } else {
            loadOffsetPillLabel.isHidden = true
        }

        // 异步请求 AI 个性化减负处方
        Task { [weak self] in
            guard let self = self else { return }
            let plan = await SUAIPostureAdvisor.shared.generateReliefPrescription(
                pitchDeg: self.pitchDeg,
                extraLoadKg: self.extraLoadKg,
                session: self.session,
                persona: self.persona
            )

            await MainActor.run {
                self.headerSubLabel.text = plan.quickDiagnosis
                self.action1Card.setAITip(plan.action1CustomTip)
                self.action2Card.setAITip(plan.action2CustomTip)
                self.action3Card.setAITip(plan.ergonomicCustomTip)

                if !plan.petEncouragement.isEmpty {
                    self.petEncouragementLabel.text = plan.petEncouragement
                    self.petEncouragementCard.isHidden = false
                }
            }
        }

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateDynamicBorderColors()
        }
    }

    private func setupPetCardStyle() {
        let personaColor = personaThemeColor(for: persona)
        petEncouragementCard.backgroundColor = personaColor.withAlphaComponent(0.06)
        petEncouragementCard.layer.borderColor = personaColor.withAlphaComponent(0.18).cgColor

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        petIconImageView.image = UIImage(systemName: persona.iconSystemName, withConfiguration: iconConfig)
        petIconImageView.tintColor = personaColor

        petNameLabel.text = persona.displayName + " · 陪伴指引"
        petNameLabel.textColor = personaColor
    }

    override func setupSubviews() {
        super.setupSubviews()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 组装 Header 卡片
        contentView.addSubview(headerCard)
        headerCard.addSubview(aiPrescriptionBadgeView)
        aiPrescriptionBadgeView.addSubview(aiPrescriptionBadgeLabel)
        headerCard.addSubview(loadOffsetPillLabel)
        headerCard.addSubview(headerTitleLabel)
        headerCard.addSubview(diagnosisContainerView)
        diagnosisContainerView.addSubview(headerSubLabel)

        // 组装动作指南卡片
        contentView.addSubview(action1Card)
        contentView.addSubview(action2Card)
        contentView.addSubview(action3Card)

        // 组装桌宠寄语卡片
        contentView.addSubview(petEncouragementCard)
        petEncouragementCard.addSubview(petIconImageView)
        petEncouragementCard.addSubview(petNameLabel)
        petEncouragementCard.addSubview(petEncouragementLabel)

        // 悬浮底部按钮
        view.addSubview(practiceButton)
        view.bringSubviewToFront(practiceButton)
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

        // Header 卡片约束
        headerCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        aiPrescriptionBadgeView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.height.equalTo(22)
        }

        aiPrescriptionBadgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }

        loadOffsetPillLabel.snp.makeConstraints { make in
            make.centerY.equalTo(aiPrescriptionBadgeView.snp.centerY)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(20)
        }

        headerTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(aiPrescriptionBadgeView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        diagnosisContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }

        headerSubLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        // 动作卡片约束
        action1Card.snp.makeConstraints { make in
            make.top.equalTo(headerCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        action2Card.snp.makeConstraints { make in
            make.top.equalTo(action1Card.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        action3Card.snp.makeConstraints { make in
            make.top.equalTo(action2Card.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        // 桌宠寄语卡片约束
        petEncouragementCard.snp.makeConstraints { make in
            make.top.equalTo(action3Card.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.bottom.equalToSuperview().offset(-96)
        }

        petIconImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
            make.size.equalTo(18)
        }

        petNameLabel.snp.makeConstraints { make in
            make.centerY.equalTo(petIconImageView.snp.centerY)
            make.leading.equalTo(petIconImageView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-14)
        }

        petEncouragementLabel.snp.makeConstraints { make in
            make.top.equalTo(petIconImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }

        // 悬浮底部按钮约束
        practiceButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(SULayoutConstants.horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
            make.height.equalTo(SULayoutConstants.primaryButtonHeight)
        }
    }

    override func setupBindings() {
        super.setupBindings()
        practiceButton.addTarget(self, action: #selector(didTapPracticeButton), for: .touchUpInside)
        practiceButton.addTarget(self, action: #selector(handleButtonTouchDown), for: .touchDown)
        practiceButton.addTarget(self, action: #selector(handleButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func handleButtonTouchDown() {
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.practiceButton.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            self.practiceButton.alpha = 0.92
        }
    }

    @objc private func handleButtonTouchUp() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction]) {
            self.practiceButton.transform = .identity
            self.practiceButton.alpha = 1.0
        }
    }

    @objc private func didTapPracticeButton() {
        SUAudioFeedbackManager.shared.triggerHapticSelection()

        let practiceVC = SUPostureReliefPracticeViewController(persona: persona)
        practiceVC.onPracticeCompleted = { [weak self] in
            guard let self = self else { return }
            self.isPracticing = false
            self.practiceButton.isEnabled = true
            self.practiceButton.backgroundColor = .systemGreen
            self.practiceButton.layer.shadowColor = UIColor.systemGreen.cgColor
            self.practiceButton.setTitle(SULocalized("relief_btn_completed", default: "🎉 完成！获得 +5 骨气能量"), for: .normal)
            SUAudioFeedbackManager.shared.triggerHapticSuccess()
        }

        practiceVC.modalPresentationStyle = .pageSheet
        if let sheet = practiceVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
        present(practiceVC, animated: true)
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    private func updateDynamicBorderColors() {
        headerCard.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.2).cgColor
        action1Card.updateDynamicColors()
        action2Card.updateDynamicColors()
        action3Card.updateDynamicColors()

        let personaColor = personaThemeColor(for: persona)
        petEncouragementCard.layer.borderColor = personaColor.withAlphaComponent(0.18).cgColor
    }

    private func personaThemeColor(for persona: SUPetPersona) -> UIColor {
        switch persona {
        case .worker: return .systemOrange
        case .cat:    return .systemPurple
        case .coach:  return .systemGreen
        }
    }

    deinit {
        countdownTimer?.invalidate()
    }
}
