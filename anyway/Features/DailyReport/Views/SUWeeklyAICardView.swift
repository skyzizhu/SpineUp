//
//  SUWeeklyAICardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// AI 专属体态伴侣周度复盘卡片
final class SUWeeklyAICardView: UIView {

    private let titleIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        iv.image = UIImage(systemName: "sparkles", withConfiguration: config)
        iv.tintColor = .systemPurple
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("weekly_ai_title", default: "AI 专属伴侣周度深度复盘")
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let personaBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemPurple
        label.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }()

    // 对话气泡卡片
    private let bubbleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.06)
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusMedium
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let quoteLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // 等重冲击比喻小横幅
    private let metaphorContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.08)
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
        return view
    }()

    private let metaphorIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .heavy)
        iv.image = UIImage(systemName: "scalemass.fill", withConfiguration: config)
        iv.tintColor = .systemOrange
        return iv
    }()

    private let metaphorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .systemOrange
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0 && bounds.height > 0 {
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: SULayoutConstants.cornerRadiusLarge
            ).cgPath
        }
    }

    private func setupCard() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 16
    }

    private func setupSubviews() {
        addSubview(titleIconImageView)
        addSubview(titleLabel)
        addSubview(personaBadgeLabel)
        addSubview(bubbleContainerView)
        bubbleContainerView.addSubview(quoteLabel)

        addSubview(metaphorContainerView)
        metaphorContainerView.addSubview(metaphorIconImageView)
        metaphorContainerView.addSubview(metaphorLabel)
    }

    private func setupConstraints() {
        titleIconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(18)
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleIconImageView.snp.centerY)
            make.leading.equalTo(titleIconImageView.snp.trailing).offset(8)
        }

        personaBadgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.trailing.equalToSuperview().offset(-18)
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(64)
        }

        bubbleContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleIconImageView.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(18)
        }

        quoteLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }

        metaphorContainerView.snp.makeConstraints { make in
            make.top.equalTo(bubbleContainerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().offset(-18)
            make.height.equalTo(38)
        }

        metaphorIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        metaphorLabel.snp.makeConstraints { make in
            make.leading.equalTo(metaphorIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with report: SUWeeklyReport) {
        personaBadgeLabel.text = " \(report.persona.displayName) "
        quoteLabel.attributedText = buildFormattedAttributedString(from: report.aiPersonaSummary)
        metaphorLabel.text = String(format: SULocalized("weekly_metaphor_fmt", default: "本周减负量: %@"), report.equivalentItemName)
    }

    private func buildFormattedAttributedString(from text: String) -> NSAttributedString {
        var cleanedText = text
        // 移除标题前的装饰 icon / emoji
        cleanedText = cleanedText.replacingOccurrences(of: "【⚠️ ", with: "【")
        cleanedText = cleanedText.replacingOccurrences(of: "【💡 ", with: "【")
        cleanedText = cleanedText.replacingOccurrences(of: "【🖥 ", with: "【")
        // 规整多余连续空行，由段落样式统一精确控制间距
        cleanedText = cleanedText.replacingOccurrences(of: "\n\n", with: "\n")

        let baseParagraphStyle = NSMutableParagraphStyle()
        baseParagraphStyle.lineSpacing = 3.5
        baseParagraphStyle.paragraphSpacing = 0

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13.5, weight: .regular),
            .foregroundColor: UIColor.label,
            .paragraphStyle: baseParagraphStyle
        ]

        let attrString = NSMutableAttributedString(string: cleanedText, attributes: baseAttributes)

        let highlightPatterns: [(String, UIColor)] = [
            ("【核心定性】", .systemPurple),
            ("【数据全景】", .systemBlue),
            ("【潜在健康危害与长期后果】", .systemRed),
            ("【科学规避与精准改善微操】", .systemGreen),
            ("【工位人体工学改造建议】", .systemTeal),
            ("【毒舌搭子结语】", .systemOrange),
            ("【傲娇猫猫结语】", .systemOrange),
            ("【体态私教结语】", .systemIndigo),
            ("【元气后辈结语】", .systemPink),
            ("【宠物结语】", .systemOrange)
        ]

        let nsString = cleanedText as NSString
        for (pattern, color) in highlightPatterns {
            var searchRange = NSRange(location: 0, length: nsString.length)
            while searchRange.location < nsString.length {
                let foundRange = nsString.range(of: pattern, options: [], range: searchRange)
                if foundRange.location != NSNotFound {
                    let headerStyle = NSMutableParagraphStyle()
                    headerStyle.paragraphSpacingBefore = (foundRange.location == 0 ? 0 : 10.0)
                    headerStyle.paragraphSpacing = 4.0
                    headerStyle.lineSpacing = 3.0

                    attrString.addAttributes([
                        .font: UIFont.systemFont(ofSize: 14.5, weight: .bold),
                        .foregroundColor: color,
                        .paragraphStyle: headerStyle
                    ], range: foundRange)

                    let nextLocation = foundRange.location + foundRange.length
                    searchRange = NSRange(location: nextLocation, length: nsString.length - nextLocation)
                } else {
                    break
                }
            }
        }

        return attrString
    }
}
