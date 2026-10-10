//
//  SUDiagnosisCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

// MARK: - 处方单虚线撕纸分隔线组件
private final class SUDashedDividerView: UIView {

    private let shapeLayer = CAShapeLayer()

    var dashColor: UIColor = .separator {
        didSet {
            shapeLayer.strokeColor = dashColor.cgColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        shapeLayer.strokeColor = dashColor.cgColor
        shapeLayer.lineWidth = 1.0
        shapeLayer.lineDashPattern = [4, 4]
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: 0, y: bounds.midY), CGPoint(x: bounds.width, y: bounds.midY)])
        shapeLayer.path = path
        shapeLayer.frame = bounds
    }

    func updateColor() {
        shapeLayer.strokeColor = dashColor.cgColor
    }
}

// MARK: - 今日骨气病历单主卡片
/// 今日骨气病历单卡片 —— 仪式感病历档案、临床诊断判定、AI 康复处方、急救减负行动与拟人桌宠寄语
final class SUDiagnosisCardView: UIView {

    // MARK: - 回调接口
    var onReliefGuideTapped: (() -> Void)?

    // MARK: - 状态缓存
    private var currentReport: SUDailyReport?

    // MARK: - 外层容器
    private let container: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.04
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 14
        return view
    }()

    // MARK: - 1. 顶部病历抬头 (Header)
    private let headerIconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.08)
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.18).cgColor
        return view
    }()

    private let headerIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
        iv.image = UIImage(systemName: "cross.case.fill", withConfiguration: config)
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let cardHeaderLabel: UILabel = {
        let label = UILabel()
        label.font = roundedFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 9.0, weight: .semibold)
        label.textColor = .tertiaryLabel
        label.text = "CLINICAL POSTURE ASSESSMENT"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let titleStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }()

    /// 右侧病历档案认证盖章 / 评级胶囊
    private let archiveBadgeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1.0
        return view
    }()

    private let archiveBadgeIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        iv.image = UIImage(systemName: "checkmark.seal.fill", withConfiguration: config)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let archiveBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        return label
    }()

    private let archiveBadgeStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    // MARK: - 2. 处方单打孔分割线
    private let dashedDividerView = SUDashedDividerView()

    // MARK: - 3. 临床诊断区块 (Diagnosis Section)
    private let diagnosisSectionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.label.withAlphaComponent(0.03)
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.12).cgColor
        return view
    }()

    private let diagnosisAccentBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 1.75
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let diagnosisTagIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        iv.image = UIImage(systemName: "waveform.path.ecg", withConfiguration: config)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let diagnosisTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.text = SULocalized("clinical_diagnosis_tag", default: "体态综合判定")
        return label
    }()

    private let diagnosisTagStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private let diagnosisDateBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let diagnosisTitleLabel: UILabel = {
        let label = UILabel()
        label.font = roundedFont(ofSize: 16.5, weight: .bold)
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 4. 康复处方区块 (Prescription Section)
    private let prescriptionSectionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.04)
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.systemIndigo.withAlphaComponent(0.12).cgColor
        return view
    }()

    private let prescriptionTagIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        iv.image = UIImage(systemName: "pills.fill", withConfiguration: config)
        iv.tintColor = .systemIndigo
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let prescriptionTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11.5, weight: .bold)
        label.textColor = .systemIndigo
        label.text = SULocalized("doctor_prescription", default: "AI 拟人处方") + " · 康复指引"
        return label
    }()

    private let prescriptionTagStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private let prescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13.5, weight: .medium)
        label.textColor = UIColor.label.withAlphaComponent(0.85)
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 5. 30 秒急救减负行动按钮 (Interactive Relief Guide Button)
    private let reliefGuideButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.08)
        btn.layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
        btn.layer.cornerCurve = .continuous
        btn.layer.borderWidth = 0.5
        btn.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.2).cgColor
        return btn
    }()

    private let reliefIconContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        view.layer.cornerRadius = 13
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let reliefIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = false
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        iv.image = UIImage(systemName: "bolt.shield.fill", withConfiguration: config)
        iv.tintColor = .systemGreen
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let reliefButtonTitleLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.font = roundedFont(ofSize: 13.5, weight: .bold)
        label.textColor = .systemGreen
        label.text = SULocalized("diagnosis_btn_relief_guide", default: "查看 30 秒急救减负微操")
        return label
    }()

    private let reliefButtonBadgeLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.font = .systemFont(ofSize: 10.5, weight: .bold)
        label.textColor = UIColor.systemGreen.withAlphaComponent(0.8)
        label.text = "即刻舒缓"
        return label
    }()

    private let reliefChevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = false
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        iv.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        iv.tintColor = UIColor.systemGreen.withAlphaComponent(0.6)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let reliefBadgeStackView: UIStackView = {
        let stack = UIStackView()
        stack.isUserInteractionEnabled = false
        stack.axis = .horizontal
        stack.spacing = 3
        stack.alignment = .center
        return stack
    }()

    // MARK: - 6. 拟人桌宠专属寄语卡片 (Pet Persona Quote Card)
    private let petQuoteCardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        return view
    }()

    private let petAvatarContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 13
        view.layer.cornerCurve = .continuous
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

    private let petPersonaSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        return label
    }()

    private let petNameStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private let petQuoteSymbolImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        iv.image = UIImage(systemName: "quote.bubble.fill", withConfiguration: config)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let petQuoteLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13.5, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupInteractions()
        observeTraitChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if container.bounds.width > 0 && container.bounds.height > 0 {
            container.layer.shadowPath = UIBezierPath(
                roundedRect: container.bounds,
                cornerRadius: SULayoutConstants.cornerRadiusLarge
            ).cgPath
        }
    }

    // MARK: - UI 装配
    private func setupUI() {
        addSubview(container)

        // 1. Header 装配
        container.addSubview(headerIconContainer)
        headerIconContainer.addSubview(headerIconImageView)

        titleStackView.addArrangedSubview(cardHeaderLabel)
        titleStackView.addArrangedSubview(headerSubtitleLabel)
        container.addSubview(titleStackView)

        archiveBadgeStackView.addArrangedSubview(archiveBadgeIcon)
        archiveBadgeStackView.addArrangedSubview(archiveBadgeLabel)
        archiveBadgeView.addSubview(archiveBadgeStackView)
        container.addSubview(archiveBadgeView)

        // 2. 撕纸虚线
        container.addSubview(dashedDividerView)

        // 3. 诊断区块装配
        container.addSubview(diagnosisSectionView)
        diagnosisSectionView.addSubview(diagnosisAccentBar)

        diagnosisTagStackView.addArrangedSubview(diagnosisTagIcon)
        diagnosisTagStackView.addArrangedSubview(diagnosisTagLabel)
        diagnosisSectionView.addSubview(diagnosisTagStackView)
        diagnosisSectionView.addSubview(diagnosisDateBadgeLabel)
        diagnosisSectionView.addSubview(diagnosisTitleLabel)

        // 4. 处方区块装配
        container.addSubview(prescriptionSectionView)
        prescriptionTagStackView.addArrangedSubview(prescriptionTagIcon)
        prescriptionTagStackView.addArrangedSubview(prescriptionTagLabel)
        prescriptionSectionView.addSubview(prescriptionTagStackView)
        prescriptionSectionView.addSubview(prescriptionLabel)

        // 5. 急救减负按钮装配
        reliefIconContainer.addSubview(reliefIconImageView)
        reliefGuideButton.addSubview(reliefIconContainer)
        reliefGuideButton.addSubview(reliefButtonTitleLabel)

        reliefBadgeStackView.addArrangedSubview(reliefButtonBadgeLabel)
        reliefBadgeStackView.addArrangedSubview(reliefChevronImageView)
        reliefGuideButton.addSubview(reliefBadgeStackView)
        container.addSubview(reliefGuideButton)

        // 6. 桌宠寄语卡片装配
        petAvatarContainer.addSubview(petIconImageView)
        petQuoteCardView.addSubview(petAvatarContainer)

        petNameStackView.addArrangedSubview(petNameLabel)
        petNameStackView.addArrangedSubview(petPersonaSubtitleLabel)
        petQuoteCardView.addSubview(petNameStackView)
        petQuoteCardView.addSubview(petQuoteSymbolImageView)
        petQuoteCardView.addSubview(petQuoteLabel)
        container.addSubview(petQuoteCardView)
    }

    // MARK: - 约束布局
    private func setupConstraints() {
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Header 约束
        headerIconContainer.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(18)
            make.size.equalTo(36)
        }

        headerIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        titleStackView.snp.makeConstraints { make in
            make.centerY.equalTo(headerIconContainer.snp.centerY)
            make.leading.equalTo(headerIconContainer.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(archiveBadgeView.snp.leading).offset(-8)
        }

        archiveBadgeView.snp.makeConstraints { make in
            make.centerY.equalTo(headerIconContainer.snp.centerY)
            make.trailing.equalToSuperview().offset(-18)
            make.height.equalTo(24)
        }

        archiveBadgeStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }

        // 撕纸虚线约束
        dashedDividerView.snp.makeConstraints { make in
            make.top.equalTo(headerIconContainer.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(1)
        }

        // 诊断区块约束
        diagnosisSectionView.snp.makeConstraints { make in
            make.top.equalTo(dashedDividerView.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(18)
        }

        diagnosisAccentBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.width.equalTo(3.5)
        }

        diagnosisTagStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(diagnosisAccentBar.snp.trailing).offset(10)
        }

        diagnosisDateBadgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(diagnosisTagStackView.snp.centerY)
            make.trailing.equalToSuperview().offset(-14)
            make.leading.greaterThanOrEqualTo(diagnosisTagStackView.snp.trailing).offset(8)
        }

        diagnosisTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(diagnosisTagStackView.snp.bottom).offset(6)
            make.leading.equalTo(diagnosisAccentBar.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-12)
        }

        // 处方区块约束
        prescriptionSectionView.snp.makeConstraints { make in
            make.top.equalTo(diagnosisSectionView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
        }

        prescriptionTagStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(14)
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }

        prescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(prescriptionTagStackView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-12)
        }

        // 急救减负按钮约束
        reliefGuideButton.snp.makeConstraints { make in
            make.top.equalTo(prescriptionSectionView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(46)
        }

        reliefIconContainer.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(26)
        }

        reliefIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(13)
        }

        reliefButtonTitleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(reliefIconContainer.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(reliefBadgeStackView.snp.leading).offset(-6)
        }

        reliefBadgeStackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
        }

        // 桌宠寄语卡片约束
        petQuoteCardView.snp.makeConstraints { make in
            make.top.equalTo(reliefGuideButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().offset(-18)
        }

        petAvatarContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(26)
        }

        petIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(13)
        }

        petNameStackView.snp.makeConstraints { make in
            make.centerY.equalTo(petAvatarContainer.snp.centerY)
            make.leading.equalTo(petAvatarContainer.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(petQuoteSymbolImageView.snp.leading).offset(-8)
        }

        petQuoteSymbolImageView.snp.makeConstraints { make in
            make.centerY.equalTo(petAvatarContainer.snp.centerY)
            make.trailing.equalToSuperview().offset(-12)
            make.size.equalTo(14)
        }

        petQuoteLabel.snp.makeConstraints { make in
            make.top.equalTo(petAvatarContainer.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    // MARK: - 交互绑定
    private func setupInteractions() {
        reliefGuideButton.addTarget(self, action: #selector(didTapReliefGuide), for: .touchUpInside)
        reliefGuideButton.addTarget(self, action: #selector(handleButtonTouchDown), for: .touchDown)
        reliefGuideButton.addTarget(self, action: #selector(handleButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    private func observeTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateDynamicBorderColors()
        }
    }

    // MARK: - 数据渲染
    func configure(with report: SUDailyReport) {
        self.currentReport = report

        // 1. Header 标题处理 (去除非现代感的书名号《》)
        let rawHeader = SULocalized("diagnosis_card_title", default: "今日骨气病历单")
        cardHeaderLabel.text = cleanBookQuotes(rawHeader)

        // 2. 评级主题色与右侧印章
        let grade = report.session.grade
        let gradeColor = gradeThemeColor(for: grade)

        archiveBadgeView.backgroundColor = gradeColor.withAlphaComponent(0.08)
        archiveBadgeView.layer.borderColor = gradeColor.withAlphaComponent(0.35).cgColor
        archiveBadgeIcon.tintColor = gradeColor
        archiveBadgeLabel.textColor = gradeColor
        let archiveFormat = SULocalized("report_archive_stamp", default: "评级 %@ · 认证")
        archiveBadgeLabel.text = String(format: archiveFormat, grade)

        // 3. 诊断结论区块
        diagnosisAccentBar.backgroundColor = gradeColor
        diagnosisTagIcon.tintColor = gradeColor
        diagnosisTagLabel.textColor = gradeColor
        diagnosisDateBadgeLabel.text = report.dateFormattedText.isEmpty ? SUPostureSessionManager.todayDateString() : report.dateFormattedText
        diagnosisTitleLabel.text = report.diagnosisTitle
        diagnosisTitleLabel.textColor = gradeColor

        // 4. 康复处方区块
        let prescriptionStyle = NSMutableParagraphStyle()
        prescriptionStyle.lineSpacing = 4.0
        prescriptionLabel.attributedText = NSAttributedString(
            string: report.doctorPrescription,
            attributes: [
                .paragraphStyle: prescriptionStyle,
                .font: UIFont.systemFont(ofSize: 13.5, weight: .medium),
                .foregroundColor: UIColor.label.withAlphaComponent(0.85)
            ]
        )

        // 5. 急救减负按钮文案
        let rawBtnTitle = SULocalized("diagnosis_btn_relief_guide", default: "查看 30 秒急救减负微操 →")
        reliefButtonTitleLabel.text = rawBtnTitle.replacingOccurrences(of: " →", with: "").replacingOccurrences(of: "→", with: "")

        // 6. 拟人桌宠寄语卡片
        let persona = report.persona
        let personaColor = personaThemeColor(for: persona)

        let personaIconConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        petIconImageView.image = UIImage(systemName: persona.iconSystemName, withConfiguration: personaIconConfig)
        petIconImageView.tintColor = personaColor
        petAvatarContainer.backgroundColor = personaColor.withAlphaComponent(0.12)

        petNameLabel.text = persona.displayName
        petNameLabel.textColor = personaColor
        petPersonaSubtitleLabel.text = "· " + persona.subtitle
        petPersonaSubtitleLabel.textColor = personaColor.withAlphaComponent(0.7)

        petQuoteSymbolImageView.tintColor = personaColor.withAlphaComponent(0.3)
        petQuoteCardView.backgroundColor = personaColor.withAlphaComponent(0.06)
        petQuoteCardView.layer.borderColor = personaColor.withAlphaComponent(0.18).cgColor

        let quoteParagraphStyle = NSMutableParagraphStyle()
        quoteParagraphStyle.lineSpacing = 3.5
        let formattedQuote = "「\(report.personaComment)」"
        petQuoteLabel.attributedText = NSAttributedString(
            string: formattedQuote,
            attributes: [
                .paragraphStyle: quoteParagraphStyle,
                .font: UIFont.systemFont(ofSize: 13.5, weight: .medium),
                .foregroundColor: UIColor.label
            ]
        )

        updateDynamicBorderColors()
    }

    /// 动态刷新多语言文案
    func refreshLocalizedStrings() {
        let rawHeader = SULocalized("diagnosis_card_title", default: "今日骨气病历单")
        cardHeaderLabel.text = cleanBookQuotes(rawHeader)
        headerSubtitleLabel.text = SULocalized("diagnosis_header_subtitle", default: "CLINICAL POSTURE ASSESSMENT")

        diagnosisTagLabel.text = SULocalized("clinical_diagnosis_tag", default: "体态综合判定")
        prescriptionTagLabel.text = SULocalized("doctor_prescription", default: "AI 拟人处方") + " · 康复指引"

        let rawBtnTitle = SULocalized("diagnosis_btn_relief_guide", default: "查看 30 秒急救减负微操 →")
        reliefButtonTitleLabel.text = rawBtnTitle.replacingOccurrences(of: " →", with: "").replacingOccurrences(of: "→", with: "")
        reliefButtonBadgeLabel.text = SULocalized("relief_guide_badge", default: "即刻舒缓")

        if let report = currentReport {
            configure(with: report)
        }
    }

    // MARK: - 动态配色适配 (深色/浅色模式)
    private func updateDynamicBorderColors() {
        container.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        dashedDividerView.dashColor = UIColor.separator.withAlphaComponent(0.35)
        diagnosisSectionView.layer.borderColor = UIColor.separator.withAlphaComponent(0.12).cgColor
        prescriptionSectionView.layer.borderColor = UIColor.systemIndigo.withAlphaComponent(0.15).cgColor
        reliefGuideButton.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.2).cgColor

        if let report = currentReport {
            let gradeColor = gradeThemeColor(for: report.session.grade)
            archiveBadgeView.layer.borderColor = gradeColor.withAlphaComponent(0.35).cgColor

            let personaColor = personaThemeColor(for: report.persona)
            petQuoteCardView.layer.borderColor = personaColor.withAlphaComponent(0.18).cgColor
        }
    }

    // MARK: - 颜色与字体辅助方法
    private func gradeThemeColor(for grade: String) -> UIColor {
        switch grade {
        case "S": return .systemGreen
        case "A": return .systemTeal
        case "B": return .systemOrange
        default:  return .systemRed
        }
    }

    private func personaThemeColor(for persona: SUPetPersona) -> UIColor {
        switch persona {
        case .worker: return .systemOrange
        case .cat:    return .systemPurple
        case .coach:  return .systemGreen
        }
    }

    private func cleanBookQuotes(_ text: String) -> String {
        return text.replacingOccurrences(of: "《", with: "").replacingOccurrences(of: "》", with: "")
    }

    // MARK: - 按钮动效与点击处理
    @objc private func didTapReliefGuide() {
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        onReliefGuideTapped?()
    }

    @objc private func handleButtonTouchDown() {
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.reliefGuideButton.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            self.reliefGuideButton.alpha = 0.88
        }
    }

    @objc private func handleButtonTouchUp() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction]) {
            self.reliefGuideButton.transform = .identity
            self.reliefGuideButton.alpha = 1.0
        }
    }
}

// MARK: - 字体辅助函数
private func roundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
    if let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.rounded) {
        return UIFont(descriptor: descriptor, size: 0)
    }
    return .systemFont(ofSize: size, weight: weight)
}
