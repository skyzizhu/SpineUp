//
//  SUPetSpeechBubbleView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// 宠物拟人对话台词气泡 —— 极简高斯模糊气泡、打字机/淡入动画、支持点击重播语音
final class SUPetSpeechBubbleView: UIView {

    // MARK: - UI 控件
    private let blurContainerView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blur = UIVisualEffectView(effect: effect)
        blur.layer.cornerRadius = 18
        blur.layer.cornerCurve = .continuous
        blur.layer.masksToBounds = true
        blur.layer.borderWidth = 0.5
        blur.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        return blur
    }()

    private let speakerIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        iv.image = UIImage(systemName: "speaker.wave.2.fill", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .natural
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let bubbleTailIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
        view.layer.cornerRadius = 3
        view.layer.cornerCurve = .continuous
        return view
    }()

    // MARK: - 回调
    var onBubbleTapped: (() -> Void)?

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        // 微柔和阴影，增加悬浮质感
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12

        addSubview(blurContainerView)
        blurContainerView.contentView.addSubview(speakerIconImageView)
        blurContainerView.contentView.addSubview(textLabel)

        blurContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        speakerIconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(18)
        }

        textLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalTo(speakerIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()

        // 弹性微动效反馈
        UIView.animate(withDuration: 0.12, animations: {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, animations: {
                self.transform = .identity
            })
        }

        onBubbleTapped?()
    }

    /// 设置显示文本与图标着色
    func configure(text: String, iconColor: UIColor = .systemOrange) {
        guard !text.isEmpty else {
            hideAnimated()
            return
        }

        speakerIconImageView.tintColor = iconColor
        textLabel.text = text

        // 弹性平滑淡入
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.88, y: 0.88).translatedBy(x: 0, y: 10)
        isHidden = false

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.6, options: [.allowUserInteraction], animations: {
            self.alpha = 1.0
            self.transform = .identity
        })
    }

    /// 隐藏气泡
    func hideAnimated() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            self.isHidden = true
        }
    }
}
