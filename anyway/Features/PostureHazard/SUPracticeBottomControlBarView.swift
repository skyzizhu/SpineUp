//
//  SUPracticeBottomControlBarView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 30 秒微操底部悬浮控制栏 —— 封装暂停/继续微操切换按钮与提前打卡/领奖完成主按钮
final class SUPracticeBottomControlBarView: UIView {

    // MARK: - 回调
    var onPauseResumeTapped: (() -> Void)?
    var onPrimaryActionTapped: (() -> Void)?

    // MARK: - UI 控件
    private let pauseButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        btn.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .secondaryLabel
        btn.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.85)
        btn.layer.cornerRadius = 24
        btn.layer.cornerCurve = .continuous
        return btn
    }()

    private let primaryActionButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(SULocalized("practice_btn_finish_early", default: "提前完成并打卡"), for: .normal)
        if let desc = UIFont.systemFont(ofSize: 16, weight: .bold).fontDescriptor.withDesign(.rounded) {
            btn.titleLabel?.font = UIFont(descriptor: desc, size: 0)
        } else {
            btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        }
        btn.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        btn.setTitleColor(.systemGreen, for: .normal)
        btn.layer.cornerRadius = 24
        btn.layer.cornerCurve = .continuous
        return btn
    }()

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(pauseButton)
        addSubview(primaryActionButton)

        pauseButton.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(48)
        }

        primaryActionButton.snp.makeConstraints { make in
            make.leading.equalTo(pauseButton.snp.trailing).offset(12)
            make.trailing.centerY.equalToSuperview()
            make.height.equalTo(48)
        }

        pauseButton.addTarget(self, action: #selector(didTapPause), for: .touchUpInside)
        primaryActionButton.addTarget(self, action: #selector(didTapPrimary), for: .touchUpInside)
    }

    @objc private func didTapPause() {
        onPauseResumeTapped?()
    }

    @objc private func didTapPrimary() {
        onPrimaryActionTapped?()
    }

    // MARK: - 状态更新
    func setPaused(_ isPaused: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        let iconName = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
    }

    func setCompletedState(title: String) {
        pauseButton.isHidden = true
        primaryActionButton.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        primaryActionButton.backgroundColor = .systemGreen
        primaryActionButton.setTitleColor(.white, for: .normal)
        primaryActionButton.setTitle(title, for: .normal)
        primaryActionButton.layer.shadowColor = UIColor.systemGreen.cgColor
        primaryActionButton.layer.shadowOpacity = 0.35
        primaryActionButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        primaryActionButton.layer.shadowRadius = 12

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.layoutIfNeeded()
            self.primaryActionButton.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.primaryActionButton.transform = .identity
            }
        }
    }
}
