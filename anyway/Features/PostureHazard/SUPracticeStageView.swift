//
//  SUPracticeStageView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit
import AVFoundation

/// 30 秒微操拟人桌宠核心舞台视图 —— 封装桌宠动作示范、气泡台词引导、AI 摄像头画中画 (PiP) 与分屏避让动效
final class SUPracticeStageView: UIView {

    // MARK: - UI 控件
    private let stageCardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.45)
        view.layer.cornerRadius = 24
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0
        return view
    }()

    private let petContainerView = SUPracticePetContainerView()
    private let speechBubbleView = SUPetSpeechBubbleView()

    // MARK: - AI 摄像头悬浮画中画 (PiP)
    private let cameraPipContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1.8
        view.layer.borderColor = UIColor.systemGreen.cgColor
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = true
        view.alpha = 0.0
        view.isHidden = true
        return view
    }()

    private let cameraLiveBadge: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        view.layer.cornerRadius = 8
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let cameraLiveDot: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 3
        return view
    }()

    private let cameraLiveLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.font = .systemFont(ofSize: 9, weight: .bold)
        label.textColor = .white
        label.text = "LIVE AI"
        return label
    }()

    private let cameraStatusBadgeLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.font = .systemFont(ofSize: 9.5, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        label.layer.cornerRadius = 7
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.text = SULocalized("practice_cam_standby", default: "姿态分析中")
        return label
    }()

    private weak var currentPreviewLayer: CALayer?

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
        return CGSize(width: UIView.noIntrinsicMetric, height: 320)
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(stageCardView)
        stageCardView.addSubview(petContainerView)
        stageCardView.addSubview(speechBubbleView)

        stageCardView.addSubview(cameraPipContainerView)
        cameraPipContainerView.addSubview(cameraLiveBadge)
        cameraLiveBadge.addSubview(cameraLiveDot)
        cameraLiveBadge.addSubview(cameraLiveLabel)
        cameraPipContainerView.addSubview(cameraStatusBadgeLabel)

        stageCardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 拟人桌宠在核心舞台中 100% 水平与垂直绝对几何居中
        petContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 260, height: 250))
        }

        speechBubbleView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-12)
        }

        cameraPipContainerView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalToSuperview().offset(14)
            make.width.equalTo(92)
            make.height.equalTo(126)
        }

        cameraLiveBadge.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(6)
            make.height.equalTo(18)
        }

        cameraLiveDot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(6)
            make.centerY.equalToSuperview()
            make.size.equalTo(6)
        }

        cameraLiveLabel.snp.makeConstraints { make in
            make.leading.equalTo(cameraLiveDot.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
        }

        cameraStatusBadgeLabel.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview().inset(6)
            make.height.equalTo(20)
        }

        setupPipDragGesture()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let preview = currentPreviewLayer {
            preview.frame = cameraPipContainerView.bounds
        }
    }

    // MARK: - 拟人桌宠示范
    func attachPet(to parent: UIViewController) {
        petContainerView.attach(to: parent)
    }

    func configurePet(
        action: SUPracticeActionType,
        persona: SUPetPersona,
        breathPhase: SUPracticeBreathPhase,
        isMatchingPose: Bool
    ) {
        petContainerView.configure(
            action: action,
            persona: persona,
            breathPhase: breathPhase,
            isMatchingPose: isMatchingPose
        )
    }

    func configureSpeechBubble(text: String, iconColor: UIColor? = nil) {
        if let color = iconColor {
            speechBubbleView.configure(text: text, iconColor: color)
        } else {
            speechBubbleView.configure(text: text)
        }
    }

    // MARK: - AI 摄像头 PiP 与动效
    func setCameraModeActive(_ active: Bool, animated: Bool = true) {
        if active {
            cameraPipContainerView.isHidden = false
            stageCardView.bringSubviewToFront(cameraPipContainerView)
            let animations = {
                // 用户要求：视觉 UI 出现后，整个宠物不要移动或者变化大小，保持在舞台中心正常示范
                self.petContainerView.transform = .identity
                self.cameraPipContainerView.alpha = 1.0
            }
            if animated {
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3, animations: animations)
            } else {
                animations()
            }
        } else {
            let animations = {
                self.petContainerView.transform = .identity
                self.cameraPipContainerView.alpha = 0.0
            }
            let completion: (Bool) -> Void = { _ in
                self.cameraPipContainerView.isHidden = true
                self.cameraPipContainerView.transform = .identity
            }
            if animated {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3, animations: animations, completion: completion)
            } else {
                animations()
                completion(true)
            }
        }
    }

    // MARK: - 可拖拽 LIVE AI 画中画手势 (限制在舞台内部移动，绝不移出舞台)
    private var dragStartTranslation: CGPoint = .zero

    private func setupPipDragGesture() {
        cameraPipContainerView.isUserInteractionEnabled = true
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePipPan(_:)))
        cameraPipContainerView.addGestureRecognizer(panGesture)
    }

    @objc private func handlePipPan(_ gesture: UIPanGestureRecognizer) {
        guard !cameraPipContainerView.isHidden else { return }

        switch gesture.state {
        case .began:
            stageCardView.bringSubviewToFront(cameraPipContainerView)
            dragStartTranslation = CGPoint(
                x: cameraPipContainerView.transform.tx,
                y: cameraPipContainerView.transform.ty
            )
            UIView.animate(withDuration: 0.15) {
                self.cameraPipContainerView.transform = CGAffineTransform(
                    translationX: self.dragStartTranslation.x,
                    y: self.dragStartTranslation.y
                ).scaledBy(x: 1.04, y: 1.04)
            }

        case .changed:
            let translation = gesture.translation(in: stageCardView)
            let proposedTx = dragStartTranslation.x + translation.x
            let proposedTy = dragStartTranslation.y + translation.y

            let pipBounds = cameraPipContainerView.bounds
            guard pipBounds.width > 0, pipBounds.height > 0 else { return }

            let stageBounds = stageCardView.bounds
            let margin: CGFloat = 8.0

            let baseCenterX = cameraPipContainerView.center.x
            let baseCenterY = cameraPipContainerView.center.y

            let halfWidth = pipBounds.width / 2.0
            let halfHeight = pipBounds.height / 2.0

            let minTx = margin + halfWidth - baseCenterX
            let maxTx = max(minTx, stageBounds.width - margin - halfWidth - baseCenterX)

            let minTy = margin + halfHeight - baseCenterY
            let maxTy = max(minTy, stageBounds.height - margin - halfHeight - baseCenterY)

            let clampedTx = min(max(proposedTx, minTx), maxTx)
            let clampedTy = min(max(proposedTy, minTy), maxTy)

            self.cameraPipContainerView.transform = CGAffineTransform(
                translationX: clampedTx,
                y: clampedTy
            ).scaledBy(x: 1.04, y: 1.04)

        case .ended, .cancelled:
            let translation = gesture.translation(in: stageCardView)
            let proposedTx = dragStartTranslation.x + translation.x
            let proposedTy = dragStartTranslation.y + translation.y

            let pipBounds = cameraPipContainerView.bounds
            let stageBounds = stageCardView.bounds
            let margin: CGFloat = 8.0

            let baseCenterX = cameraPipContainerView.center.x
            let baseCenterY = cameraPipContainerView.center.y

            let halfWidth = pipBounds.width / 2.0
            let halfHeight = pipBounds.height / 2.0

            let minTx = margin + halfWidth - baseCenterX
            let maxTx = max(minTx, stageBounds.width - margin - halfWidth - baseCenterX)

            let minTy = margin + halfHeight - baseCenterY
            let maxTy = max(minTy, stageBounds.height - margin - halfHeight - baseCenterY)

            let clampedTx = min(max(proposedTx, minTx), maxTx)
            let clampedTy = min(max(proposedTy, minTy), maxTy)

            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4) {
                self.cameraPipContainerView.transform = CGAffineTransform(
                    translationX: clampedTx,
                    y: clampedTy
                )
            }

            SUAudioFeedbackManager.shared.triggerHapticSelection()

        default:
            break
        }
    }

    func attachCameraPreview(layer: CALayer) {
        detachCameraPreview()
        self.currentPreviewLayer = layer
        layer.frame = cameraPipContainerView.bounds
        cameraPipContainerView.layer.insertSublayer(layer, at: 0)
    }

    func detachCameraPreview() {
        cameraPipContainerView.layer.sublayers?.filter { $0 is AVCaptureVideoPreviewLayer }.forEach { $0.removeFromSuperlayer() }
        currentPreviewLayer = nil
    }

    func updateCameraStatus(tip: String, isMatched: Bool) {
        cameraStatusBadgeLabel.text = tip
        cameraPipContainerView.layer.borderColor = isMatched ? UIColor.systemGreen.cgColor : UIColor.systemOrange.cgColor
        cameraLiveDot.backgroundColor = isMatched ? .systemGreen : .systemOrange
    }

    func updatePoseMatchHighlight(_ isMatched: Bool) {
        stageCardView.layer.borderWidth = 0
        stageCardView.backgroundColor = isMatched ?
            UIColor.systemGreen.withAlphaComponent(0.08) :
            UIColor.secondarySystemBackground.withAlphaComponent(0.45)
    }
}
