//
//  SUPostureGaugeView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 独立封装视图：坐姿角度仪表与物理负荷指示卡片（美观、大气、空间层级通透版）
final class SUPostureGaugeView: UIView {

    private let containerCard: SULiquidGlassView = {
        let view = SULiquidGlassView(cornerRadius: SULayoutConstants.cornerRadiusMedium)
        view.showsBorder = false
        view.layer.borderWidth = 0.0
        return view
    }()

    // MARK: - 顶部状态栏：卡片主题标题与减负按钮
    private let cardHeaderContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private let cardHeaderIconView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        iv.image = UIImage(systemName: "waveform.path.ecg", withConfiguration: config)
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let cardHeaderTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("gauge_card_title", default: "实时颈椎力学")
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let reliefGuideButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
        config.baseForegroundColor = .systemGreen
        var titleAttr = AttributedString(SULocalized("gauge_relief_btn_title", default: "减负微操 💡"))
        
        titleAttr.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        
        config.attributedTitle = titleAttr
        return UIButton(configuration: config)
    }()

    // MARK: - 中间核心指标：左侧大字负荷与右侧实时角度/状态
    private let loadCardContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.label.withAlphaComponent(0.04)
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.0
        return view
    }()

    private let loadTitleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("metrics_extra_load", default: "颈椎额外承重")
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let aiHazardBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("ai_perspective_tag", default: "AI透视 ↗")
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = .systemBlue
        return label
    }()

    private let loadValueLabel: UILabel = {
        let label = UILabel()
        label.text = "+0.0 kg"
        if let descriptor = UIFont.systemFont(ofSize: 22, weight: .heavy).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 22)
        } else {
            label.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        }
        label.textColor = .systemGreen
        return label
    }()

    // MARK: - 右侧体态评估状态胶囊 (不重复显示低头角度，专注医学评估与体态建议)
    private let statusBadgeContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.25).cgColor
        view.layer.masksToBounds = true
        return view
    }()

    private let statusHintLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("gauge_status_ideal_short", default: "零负担 · 完美体态")
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .systemGreen
        label.textAlignment = .center
        return label
    }()

    // MARK: - 底部进度条与三等分标尺
    private let angleProgressTrack: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemFill
        view.layer.cornerRadius = 5
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        return view
    }()

    private let angleProgressBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 5
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.systemGreen.cgColor
        view.layer.shadowOpacity = 0.35
        view.layer.shadowOffset = CGSize(width: 0, height: 1.5)
        view.layer.shadowRadius = 3
        return view
    }()

    private let scaleStartLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("gauge_scale_start", default: "0° 精神挺拔")
        label.font = UIFont.systemFont(ofSize: 10.5, weight: .semibold)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let scaleMidLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("gauge_scale_mid", default: "15° 轻微前倾")
        label.font = UIFont.systemFont(ofSize: 10.5, weight: .semibold)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    private let scaleEndLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("gauge_scale_end", default: "30°+ 严重驼背")
        label.font = UIFont.systemFont(ofSize: 10.5, weight: .semibold)
        label.textColor = .tertiaryLabel
        label.textAlignment = .right
        return label
    }()

    // MARK: - 交互回调与记忆值
    var onHazardDetailTapped: (() -> Void)?
    var onReliefGuideTapped: (() -> Void)?

    private var smoothedPitchDeg: Double = 0.0

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(containerCard)

        // 顶部行：左侧卡片标题与右侧减负按钮
        containerCard.contentView.addSubview(cardHeaderContainerView)
        cardHeaderContainerView.addSubview(cardHeaderIconView)
        cardHeaderContainerView.addSubview(cardHeaderTitleLabel)

        containerCard.contentView.addSubview(reliefGuideButton)

        // 中间主体
        containerCard.contentView.addSubview(loadCardContainer)
        loadCardContainer.addSubview(loadTitleLabel)
        loadCardContainer.addSubview(aiHazardBadgeLabel)
        loadCardContainer.addSubview(loadValueLabel)

        containerCard.contentView.addSubview(statusBadgeContainer)
        statusBadgeContainer.addSubview(statusHintLabel)

        // 底部条与标尺
        containerCard.contentView.addSubview(angleProgressTrack)
        angleProgressTrack.addSubview(angleProgressBar)

        containerCard.contentView.addSubview(scaleStartLabel)
        containerCard.contentView.addSubview(scaleMidLabel)
        containerCard.contentView.addSubview(scaleEndLabel)

        // 交互手势与事件
        reliefGuideButton.addTarget(self, action: #selector(didTapRelief), for: .touchUpInside)

        let loadTap = UITapGestureRecognizer(target: self, action: #selector(didTapHazard))
        loadCardContainer.addGestureRecognizer(loadTap)
        loadCardContainer.isUserInteractionEnabled = true

        let statusTap = UITapGestureRecognizer(target: self, action: #selector(didTapHazard))
        statusBadgeContainer.addGestureRecognizer(statusTap)
        statusBadgeContainer.isUserInteractionEnabled = true
    }

    private func setupConstraints() {
        containerCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 顶部行：左侧卡片标题与右侧减负按钮，互不干扰、宽敞通透
        cardHeaderContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(24)
        }

        cardHeaderIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }

        cardHeaderTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(cardHeaderIconView.snp.trailing).offset(6)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        reliefGuideButton.snp.makeConstraints { make in
            make.centerY.equalTo(cardHeaderContainerView)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(24)
        }

        // 中间行：左侧负荷卡片与右侧角度徽标
        loadCardContainer.snp.makeConstraints { make in
            make.top.equalTo(cardHeaderContainerView.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(155)
            make.height.equalTo(52)
        }

        loadTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.equalToSuperview().offset(10)
        }

        aiHazardBadgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(loadTitleLabel)
            make.leading.equalTo(loadTitleLabel.snp.trailing).offset(4)
        }

        loadValueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-6)
        }

        statusBadgeContainer.snp.makeConstraints { make in
            make.centerY.equalTo(loadCardContainer)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.greaterThanOrEqualTo(loadCardContainer.snp.trailing).offset(10)
            make.height.equalTo(28)
        }

        statusHintLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        // 底部进度条与标尺
        angleProgressTrack.snp.makeConstraints { make in
            make.top.equalTo(loadCardContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(10)
        }

        angleProgressBar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }

        scaleStartLabel.snp.makeConstraints { make in
            make.top.equalTo(angleProgressTrack.snp.bottom).offset(8)
            make.leading.equalTo(angleProgressTrack)
        }

        scaleMidLabel.snp.makeConstraints { make in
            make.centerY.equalTo(scaleStartLabel)
            make.centerX.equalTo(angleProgressTrack)
        }

        scaleEndLabel.snp.makeConstraints { make in
            make.centerY.equalTo(scaleStartLabel)
            make.trailing.equalTo(angleProgressTrack)
        }
    }

    // MARK: - 数据渲染与动态更新

    func configure(with reading: SUPostureReading, connectionState: SUHeadphoneConnectionState) {
        if !connectionState.isWorking {
            smoothedPitchDeg = 0.0
            loadValueLabel.text = "-- kg"
            let tintColor = connectionState.themeColor
            statusHintLabel.text = connectionState.displayTitle
            loadValueLabel.textColor = tintColor
            statusHintLabel.textColor = tintColor
            statusBadgeContainer.backgroundColor = tintColor.withAlphaComponent(0.12)
            statusBadgeContainer.layer.borderColor = tintColor.withAlphaComponent(0.25).cgColor
            angleProgressBar.backgroundColor = tintColor
            angleProgressBar.layer.shadowColor = tintColor.cgColor
            angleProgressBar.snp.remakeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalTo(0)
            }
            return
        }

        let rawPitch = max(0.0, reading.relativePitchDeg)
        if smoothedPitchDeg == 0.0 || abs(rawPitch - smoothedPitchDeg) > 4.0 {
            smoothedPitchDeg = rawPitch
        } else {
            smoothedPitchDeg = smoothedPitchDeg * 0.6 + rawPitch * 0.4
        }

        loadValueLabel.text = String(format: "+%.1f kg", reading.extraLoadKg)

        // 统一体态状态颜色与医学评估简评
        let state = reading.state
        let tintColor = state.themeColor

        statusHintLabel.text = state.evaluationSummary
        loadValueLabel.textColor = tintColor
        statusHintLabel.textColor = tintColor
        statusBadgeContainer.backgroundColor = state.badgeBackgroundColor
        statusBadgeContainer.layer.borderColor = state.badgeBorderColor.cgColor
        angleProgressBar.backgroundColor = tintColor
        angleProgressBar.layer.shadowColor = tintColor.cgColor

        // 进度条百分比 (0° ~ 30° 线性对齐标尺刻度：0° 挺拔 -> 15° 临界居中 -> 30°+ 警报右端)
        let maxAngle: Double = 30.0
        let ratio = min(1.0, max(0.0, rawPitch / maxAngle))
        angleProgressBar.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(angleProgressTrack.snp.width).multipliedBy(CGFloat(max(0.001, ratio)))
        }
    }

    /// 动态刷新多语言文案
    func refreshLocalizedStrings() {
        cardHeaderTitleLabel.text = SULocalized("gauge_card_title", default: "实时颈椎力学")
        loadTitleLabel.text = SULocalized("metrics_extra_load", default: "颈椎额外承重")
        aiHazardBadgeLabel.text = SULocalized("ai_perspective_tag", default: "AI透视 ↗")
        scaleStartLabel.text = SULocalized("gauge_scale_start", default: "0° 精神挺拔")
        scaleMidLabel.text = SULocalized("gauge_scale_mid", default: "15° 轻微前倾")
        scaleEndLabel.text = SULocalized("gauge_scale_end", default: "30°+ 严重驼背")
        if var config = reliefGuideButton.configuration {
            var titleAttr = AttributedString(SULocalized("gauge_relief_btn_title", default: "减负微操 💡"))
            titleAttr.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            config.attributedTitle = titleAttr
            reliefGuideButton.configuration = config
        }
    }

    @objc private func didTapHazard() {
        SUAudioFeedbackManager.shared.triggerHapticLightTap()
        onHazardDetailTapped?()
    }

    @objc private func didTapRelief() {
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        onReliefGuideTapped?()
    }
}
