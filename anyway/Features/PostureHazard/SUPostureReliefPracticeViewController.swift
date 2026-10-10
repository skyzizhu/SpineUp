//
//  SUPostureReliefPracticeViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit
import AVFoundation
import CoreMotion
import os

/// 30 秒办公室减负微操全屏沉浸带练视窗 —— 拟人桌宠动作示范、气泡台词实时引导、AirPods/AI 视觉多模态姿态感知与礼花打卡
final class SUPostureReliefPracticeViewController: SUBaseViewController {

    // MARK: - 回调
    var onPracticeCompleted: (() -> Void)?

    // MARK: - 状态属性
    private let persona: SUPetPersona
    private var currentAction: SUPracticeActionType = .chinTuck
    private var remainingSeconds: Int = 30
    private var subsecondAccumulator: Double = 0.0
    private var isPaused: Bool = false
    private var isCompleted: Bool = false
    private var isCameraModeActive: Bool = false
    private var isMatchingPose: Bool = false
    private var recordedPitchDeg: Double = 0.0

    private var countdownTimer: Timer?
    private var visionManager: SUPracticeVisionManager?
    private let headphoneMotionManager = CMHeadphoneMotionManager()

    // MARK: - 可滑动内容区域 (顶部坐标从 0 开始，底部也是，由系统自动判断安全距离)
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let contentView = UIView()

    // MARK: - 自定义页面核心子组件
    private let topNavBarView = SUPracticeTopNavBarView()
    private let stageView = SUPracticeStageView()
    private let breathingPacerView = SUBreathingPacerView()
    private let infoCardView = SUPracticeActionInfoCardView()
    private let bottomControlBarView = SUPracticeBottomControlBarView()
    private let confettiView = SUConfettiEmitterView()

    // MARK: - 初始化
    init(persona: SUPetPersona = SUPetPersonaManager.shared.currentPersona) {
        self.persona = persona
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.persona = .coach
        super.init(coder: coder)
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        stageView.attachPet(to: self)

        updateActionDisplay(action: .chinTuck, forceSpeech: true)
        breathingPacerView.configureCadence(for: .chinTuck)
        breathingPacerView.updateCountdown(seconds: 30, progress: 1.0, themeColor: SUPracticeActionType.chinTuck.themeColor)

        startPracticeTimer()
        startHeadphoneTracking()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        countdownTimer?.invalidate()
        countdownTimer = nil

        // 同步退出硬件会话，防止在 dismiss 动画过程中因硬件会话未停而发生系统崩溃
        visionManager?.stopSession(synchronously: true)
        stageView.detachCameraPreview()
        headphoneMotionManager.stopDeviceMotionUpdates()
        SUSpeechManager.shared.stop()
    }

    // MARK: - UI 构建
    override func setupSubviews() {
        super.setupSubviews()
        view.backgroundColor = .systemBackground

        // 1. 滑动视图与内容容器
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 2. 将各个独立的自定义组件组装进滚动视图
        contentView.addSubview(topNavBarView)
        contentView.addSubview(stageView)
        contentView.addSubview(breathingPacerView)
        contentView.addSubview(infoCardView)

        // 3. 悬浮底栏与礼花粒子置于顶层
        view.addSubview(bottomControlBarView)
        view.addSubview(confettiView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        // 1. 滑动视图顶部与底部坐标均从 0 开始，由系统自动计算安全区域 (contentInsetAdjustmentBehavior = .automatic)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        // 2. 顶部导航操作栏 (在抓手条下方留出精致舒适的 12pt 间距)
        topNavBarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(34)
        }

        // 3. 拟人桌宠核心示范舞台 (间距 16pt，高度提升至 320pt，内部无边框且桌宠 100% 绝对居中)
        stageView.snp.makeConstraints { make in
            make.top.equalTo(topNavBarView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(320)
        }

        // 4. 呼吸引导律动与倒计时一体化控制条 (高度仅 62pt)
        breathingPacerView.snp.makeConstraints { make in
            make.top.equalTo(stageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(62)
        }

        // 5. 动作说明卡片 (底部留出 84pt 避让悬浮底部控制栏)
        infoCardView.snp.makeConstraints { make in
            make.top.equalTo(breathingPacerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-84)
        }

        // 6. 底部悬浮控制栏 (常驻底部安全区域上方)
        bottomControlBarView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
            make.height.equalTo(48)
        }

        confettiView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 事件绑定
    override func setupBindings() {
        super.setupBindings()

        topNavBarView.onCloseTapped = { [weak self] in
            self?.didTapClose()
        }

        topNavBarView.onModeToggleTapped = { [weak self] in
            self?.didTapModeToggle()
        }

        bottomControlBarView.onPauseResumeTapped = { [weak self] in
            self?.didTapPauseResume()
        }

        bottomControlBarView.onPrimaryActionTapped = { [weak self] in
            self?.didTapPrimaryAction()
        }
    }

    deinit {
        countdownTimer?.invalidate()
        headphoneMotionManager.stopDeviceMotionUpdates()
        visionManager?.stopSession(synchronously: true)
    }

    @objc private func didTapClose() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        headphoneMotionManager.stopDeviceMotionUpdates()

        // 重点：dismiss 前同步停止摄像头会话，彻底避免崩溃
        visionManager?.stopSession(synchronously: true)
        stageView.detachCameraPreview()

        dismiss(animated: true)
    }

    @objc private func didTapModeToggle() {
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        isCameraModeActive.toggle()

        if isCameraModeActive {
            headphoneMotionManager.stopDeviceMotionUpdates()
            topNavBarView.setModeStatus(
                title: SULocalized("practice_mode_ai_vision", default: "🎥 AI 视觉识别中"),
                dotColor: .systemTeal
            )
            startCameraPip()
        } else {
            stopCameraPip()
            topNavBarView.setModeStatus(
                title: SULocalized("practice_mode_headphone", default: "🎧 耳机体态感知"),
                dotColor: .systemGreen
            )
            startHeadphoneTracking()
        }
    }

    @objc private func didTapPauseResume() {
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        isPaused.toggle()
        bottomControlBarView.setPaused(isPaused)

        if isPaused {
            countdownTimer?.invalidate()
            stageView.configureSpeechBubble(text: SULocalized("practice_paused_tip", default: "微操已暂停，随时点击继续~"))
        } else {
            startPracticeTimer()
            let dialogue = currentAction.dialogue(for: persona)
            stageView.configureSpeechBubble(text: dialogue, iconColor: currentAction.themeColor)
        }
    }

    @objc private func didTapPrimaryAction() {
        if isCompleted {
            // 点击领取并退出
            visionManager?.stopSession(synchronously: true)
            stageView.detachCameraPreview()
            dismiss(animated: true) { [weak self] in
                self?.onPracticeCompleted?()
            }
        } else {
            // 提前结束并完成
            completePracticeSession()
        }
    }

    // MARK: - 倒计时驱动与阶段流转
    private func startPracticeTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tickSubsecond(delta: 0.1)
        }
    }

    private func tickSubsecond(delta: Double) {
        guard !isPaused, remainingSeconds > 0 else { return }

        // 1. 毫秒级驱动呼吸律动组件
        breathingPacerView.tick(deltaSeconds: delta)
        let breathPhase = breathingPacerView.currentPhase

        // 2. 将呼吸阶段直接同步至桌宠动作演示
        stageView.configurePet(
            action: currentAction,
            persona: persona,
            breathPhase: breathPhase,
            isMatchingPose: isMatchingPose
        )

        // 3. 累计 1 秒心跳
        subsecondAccumulator += delta
        if subsecondAccumulator >= 1.0 {
            subsecondAccumulator -= 1.0
            tickOneSecond()
        }
    }

    private func tickOneSecond() {
        remainingSeconds -= 1
        let progressFraction = max(0, CGFloat(remainingSeconds) / 30.0)
        breathingPacerView.updateCountdown(
            seconds: remainingSeconds,
            progress: progressFraction,
            themeColor: currentAction.themeColor
        )

        // 阶段转换：在 15 秒时切换到动作 2
        if remainingSeconds == 15 && currentAction == .chinTuck {
            currentAction = .wStretch
            breathingPacerView.configureCadence(for: .wStretch)
            updateActionDisplay(action: .wStretch, forceSpeech: true)
            SUAudioFeedbackManager.shared.triggerHapticLightTap()
        }

        // 最后 3 秒冲刺提示
        if remainingSeconds == 3 {
            let sprintLine = SUPracticeActionType.sprintDialogue(for: persona)
            stageView.configureSpeechBubble(text: sprintLine)
            SUSpeechManager.shared.speak(text: sprintLine, persona: persona, force: true)
        }

        // 完成倒计时
        if remainingSeconds <= 0 {
            countdownTimer?.invalidate()
            completePracticeSession()
        }
    }

    private func updateActionDisplay(action: SUPracticeActionType, forceSpeech: Bool) {
        topNavBarView.configure(stepText: action.stepIndicatorText, themeColor: action.themeColor)

        let progressFraction = max(0, CGFloat(remainingSeconds) / 30.0)
        breathingPacerView.updateCountdown(
            seconds: remainingSeconds,
            progress: progressFraction,
            themeColor: action.themeColor
        )

        // 更新说明卡片
        infoCardView.configure(action: action)

        // 更新拟人桌宠示范动作与视觉管理器
        stageView.configurePet(
            action: action,
            persona: persona,
            breathPhase: breathingPacerView.currentPhase,
            isMatchingPose: isMatchingPose
        )
        visionManager?.setAction(action)

        // 更新台词气泡并触发语音
        let line = action.dialogue(for: persona)
        stageView.configureSpeechBubble(text: line, iconColor: action.themeColor)

        if forceSpeech {
            SUSpeechManager.shared.speak(text: line, persona: persona, force: true)
        }
    }

    // MARK: - AirPods 耳机空间姿态感知
    private func startHeadphoneTracking() {
        guard headphoneMotionManager.isDeviceMotionAvailable else {
            topNavBarView.setModeStatus(
                title: SULocalized("practice_mode_headphone", default: "🎧 耳机体态感知"),
                dotColor: .systemGreen
            )
            return
        }

        headphoneMotionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, !self.isCameraModeActive else { return }
            let basePitchRad = SUCalibrationService.shared.savedBaseline?.pitch ?? 0.0
            // 在 AirPods CoreMotion 空间坐标系中：低头时 pitch 减小
            // 转换为业务语义：正数代表前倾低头，负数代表后仰伸展
            let relativePitchDeg = (basePitchRad - motion.attitude.pitch) * 180.0 / .pi
            self.handleHeadphonePitch(relativePitchDeg: relativePitchDeg)
        }
    }

    private func handleHeadphonePitch(relativePitchDeg: Double) {
        self.recordedPitchDeg = relativePitchDeg

        // 当用户做收下巴动作时：头部后移回缩，保持水平平视 (-6° ~ +6°) 且不低头
        let isUprightGaze = relativePitchDeg >= -6.0 && relativePitchDeg <= 6.0
        let isSlouching = relativePitchDeg > 12.0

        if isUprightGaze && !isSlouching {
            if !self.isMatchingPose {
                self.isMatchingPose = true
                self.topNavBarView.setModeStatus(
                    title: SULocalized("practice_airpods_matched", default: "🎧 AirPods 感知到后颈挺拔回缩！"),
                    dotColor: .systemGreen
                )
                self.stageView.updatePoseMatchHighlight(true)
                self.stageView.configurePet(
                    action: self.currentAction,
                    persona: self.persona,
                    breathPhase: self.breathingPacerView.currentPhase,
                    isMatchingPose: true
                )
                SUAudioFeedbackManager.shared.triggerHapticLightTap()
            }
        } else {
            if self.isMatchingPose {
                self.isMatchingPose = false
                self.topNavBarView.setModeStatus(
                    title: SULocalized("practice_mode_headphone", default: "🎧 耳机体态感知"),
                    dotColor: .systemGreen
                )
                self.stageView.updatePoseMatchHighlight(false)
                self.stageView.configurePet(
                    action: self.currentAction,
                    persona: self.persona,
                    breathPhase: self.breathingPacerView.currentPhase,
                    isMatchingPose: false
                )
            }
        }
    }

    // MARK: - 完成结算
    private func completePracticeSession() {
        guard !isCompleted else { return }
        isCompleted = true

        countdownTimer?.invalidate()
        headphoneMotionManager.stopDeviceMotionUpdates()
        visionManager?.stopSession(synchronously: true)
        stageView.detachCameraPreview()

        breathingPacerView.updateCountdown(seconds: 0, progress: 0.0, themeColor: .systemGreen)

        // 奖励发放与反馈 (本地优先)
        SUSpineEnergyManager.shared.rewardBonusCoins(5)
        SUAudioFeedbackManager.shared.triggerHapticSuccess()
        confettiView.burst()

        // 异步向云端接口上报微操打卡并对齐骨气余额
        let reportedPitch = recordedPitchDeg
        let reportedAction = currentAction == .chinTuck ? "chin_tuck" : "w_stretch"
        Task {
            do {
                let loadKg = max(0.0, SUErgonomicsCalculator.calculateExtraLoadKg(pitchDeg: reportedPitch))
                let res = try await SUAPIClient.shared.relief.claim(
                    actionType: reportedAction,
                    pitchDeg: reportedPitch,
                    extraLoadKg: loadKg,
                    durationSec: 30
                )
                if res.claimed && res.new_balance > 0 {
                    DispatchQueue.main.async {
                        SUSpineEnergyManager.shared.syncBalanceFromCloud(res.new_balance)
                    }
                }
            } catch {
                SULogger.network.debug("Cloud relief claim offline fallback: \(error.localizedDescription)")
            }
        }

        // 更新台词气泡
        let congratsText = SUPracticeActionType.completionDialogue(for: persona)
        stageView.configureSpeechBubble(text: congratsText, iconColor: .systemGreen)
        SUSpeechManager.shared.speak(text: congratsText, persona: persona, force: true)

        // 更新桌宠形象为欢呼状态
        stageView.configurePet(
            action: currentAction,
            persona: persona,
            breathPhase: .inhale,
            isMatchingPose: true
        )

        // 按钮动画变形成大号高光绿色按钮
        bottomControlBarView.setCompletedState(
            title: SULocalized("practice_btn_claim_done", default: "🎉 获得 +5 骨气能量 · 完成")
        )
    }

    // MARK: - AI 摄像头 PiP 控制
    private func startCameraPip() {
        if visionManager == nil {
            let vm = SUPracticeVisionManager()
            vm.onPoseMatched = { [weak self] isMatched, tip in
                DispatchQueue.main.async {
                    guard let self = self, self.isCameraModeActive else { return }
                    self.isMatchingPose = isMatched
                    self.stageView.configurePet(
                        action: self.currentAction,
                        persona: self.persona,
                        breathPhase: self.breathingPacerView.currentPhase,
                        isMatchingPose: isMatched
                    )
                    self.stageView.updateCameraStatus(
                        tip: tip.isEmpty ? (isMatched ? "✅ 姿态达标" : "调整姿态") : tip,
                        isMatched: isMatched
                    )
                    self.stageView.updatePoseMatchHighlight(isMatched)
                }
            }
            vm.onChestExpansionDetected = { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self, self.isCameraModeActive else { return }
                    self.stageView.updateCameraStatus(
                        tip: SULocalized("vision_tip_inhale_detected", default: "🫁 检测到深吸气胸腔舒展"),
                        isMatched: true
                    )
                }
            }
            self.visionManager = vm
        }

        visionManager?.checkCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard granted else {
                    self.didTapModeToggle() // 降级回耳机模式
                    return
                }

                self.stageView.setCameraModeActive(true, animated: true)

                self.visionManager?.startSession { [weak self] success in
                    DispatchQueue.main.async {
                        guard let self = self, success else { return }
                        if let preview = self.visionManager?.previewLayer {
                            self.stageView.attachCameraPreview(layer: preview)
                        }
                    }
                }
            }
        }
    }

    private func stopCameraPip() {
        visionManager?.stopSession(synchronously: false)
        stageView.detachCameraPreview()
        stageView.setCameraModeActive(false, animated: true)
        stageView.updatePoseMatchHighlight(false)
        stageView.configurePet(
            action: currentAction,
            persona: persona,
            breathPhase: breathingPacerView.currentPhase,
            isMatchingPose: false
        )
    }
}
