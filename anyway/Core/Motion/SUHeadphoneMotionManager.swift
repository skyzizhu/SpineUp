//
//  SUHeadphoneMotionManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import CoreMotion
import AVFoundation
import UIKit
import os

/// 真机 AirPods 空间运动传感器管理器 —— 融合 CoreMotion、AVAudioSession 蓝牙路由、5 大连接佩戴与授权状态机引擎、抖动抑制与边界防护
final class SUHeadphoneMotionManager: NSObject, SUMotionServiceProtocol, CMHeadphoneMotionManagerDelegate, @unchecked Sendable {

    private let motionManager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()

    private let calibrationService: SUCalibrationService
    private let stateEngine: SUPostureStateEngine

    private(set) var connectionState: SUHeadphoneConnectionState = .disconnected
    var currentPostureState: SUPostureState {
        stateEngine.currentState
    }

    private var basePitchRad: Double = 0.0
    private var baseRollRad: Double = 0.0

    private let stateLock = NSLock()
    private var isMonitoringActive: Bool = false
    private var statusHeartbeatTimer: Timer?
    private var pendingDebounceWorkItem: DispatchWorkItem?

    var onReadingUpdated: (@Sendable (SUPostureReading) -> Void)?
    var onConnectionStateChanged: (@Sendable (SUHeadphoneConnectionState) -> Void)?
    var onPostureStateChanged: (@Sendable (SUPostureState, SUPostureState) -> Void)?
    var onCalibrationProgress: (@Sendable (Double) -> Void)?

    init(
        calibrationService: SUCalibrationService = SUCalibrationService(),
        stateEngine: SUPostureStateEngine = SUPostureStateEngine()
    ) {
        self.calibrationService = calibrationService
        self.stateEngine = stateEngine
        super.init()

        queue.name = "com.spineup.headphoneMotionQueue"
        queue.maxConcurrentOperationCount = 1
        motionManager.delegate = self

        // 绑定校准完成
        calibrationService.onCalibrationCompleted = { [weak self] pitch, roll in
            guard let self = self else { return }
            self.stateLock.lock()
            self.basePitchRad = pitch
            self.baseRollRad = roll
            self.stateLock.unlock()
            self.stateEngine.reset()
        }

        calibrationService.onCalibrationProgress = { [weak self] progress in
            self?.onCalibrationProgress?(progress)
        }

        // 绑定状态跃迁
        stateEngine.onStateChanged = { [weak self] oldState, newState in
            self?.onPostureStateChanged?(oldState, newState)
        }

        // 读取已有持久化基准
        if let saved = calibrationService.savedBaseline {
            basePitchRad = saved.pitch
            baseRollRad = saved.roll
            SULogger.motion.info("Loaded persisted calibration baseline: pitch=\(saved.pitch), roll=\(saved.roll)")
        }

        setupNotificationObservers()
        reevaluateConnectionState(notify: false)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func handleAudioRouteChange(_ notification: Notification) {
        // 路由变更可能有短暂硬件抖动，延时 0.3s 取得稳定音频路由
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.reevaluateConnectionState(notify: true)
        }
    }

    @objc private func handleAppDidBecomeActive() {
        reevaluateConnectionState(notify: true)
    }

    /// 检测当前系统音频输出是否连接了蓝牙耳机 (A2DP / HFP / LE)，同时过滤已知无动作传感器的音箱/车载设备
    private func getConnectedBluetoothPortInfo() -> (isConnected: Bool, isKnownSpeakerOrCar: Bool, portName: String) {
        let session = AVAudioSession.sharedInstance()
        let bluetoothTypes: Set<AVAudioSession.Port> = [
            .bluetoothA2DP,
            .bluetoothHFP,
            .bluetoothLE
        ]

        var foundPort: AVAudioSessionPortDescription?
        for output in session.currentRoute.outputs {
            if bluetoothTypes.contains(output.portType) {
                foundPort = output
                break
            }
        }
        if foundPort == nil, let inputs = session.availableInputs {
            foundPort = inputs.first(where: { bluetoothTypes.contains($0.portType) })
        }

        guard let port = foundPort else {
            return (false, false, "")
        }

        let lowerName = port.portName.lowercased()
        let nonMotionKeywords = [
            "car", "carplay", "车载", "speaker", "soundbar", "jbl", "bose", "echo", "tv", "homepod"
        ]
        let isKnownSpeakerOrCar = nonMotionKeywords.contains(where: { lowerName.contains($0) }) &&
            !lowerName.contains("airpod") && !lowerName.contains("beats")

        return (true, isKnownSpeakerOrCar, port.portName)
    }

    /// 评估 5 大耳机物理连接、入耳佩戴与权限状态
    private func evaluateConnectionState() -> SUHeadphoneConnectionState {
        let authStatus = CMHeadphoneMotionManager.authorizationStatus()
        let isAuthorized = (authStatus == .authorized)
        let isMotionAvailable = motionManager.isDeviceMotionAvailable
        let btInfo = getConnectedBluetoothPortInfo()

        if isMotionAvailable {
            // 耳机已连接且已戴入耳中 (CoreMotion 仅在 AirPods 佩戴入耳时 isDeviceMotionAvailable 为 true)
            return isAuthorized ? .connected : .connectedWornUnauthorized
        } else if btInfo.isConnected {
            if btInfo.isKnownSpeakerOrCar {
                // 连接的是蓝牙音箱或车载设备，无姿态传感器
                return .unsupported
            }
            // 耳机已连手机蓝牙，但当前未戴入耳中 (摘下或在充电盒中但蓝牙连着)
            return isAuthorized ? .connectedUnwornAuthorized : .connectedUnwornUnauthorized
        } else {
            // 手机未连接任何蓝牙音频设备
            return .disconnected
        }
    }

    /// 状态评估并触发跃迁通知，内置防抖过滤与自动恢复/自动挂起
    private func reevaluateConnectionState(notify: Bool) {
        let candidateState = evaluateConnectionState()

        stateLock.lock()
        let oldState = connectionState
        stateLock.unlock()

        // 边界防护：抖动抑制（Anti-Flapping）
        // 若当前处于正常追踪状态 (connected)，而新判定为摘下或断开 (connectedUnwornAuthorized / disconnected)，
        // 极可能是用户在耳中轻微微调或整理耳机导致传感器瞬间断续，延迟 0.8s 再次确认，彻底避免 UI 频繁闪烁
        if oldState == .connected && (candidateState == .connectedUnwornAuthorized || candidateState == .disconnected) {
            if pendingDebounceWorkItem == nil {
                let item = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    self.pendingDebounceWorkItem = nil
                    // 0.8s 后再次确认当前真实状态
                    let confirmedState = self.evaluateConnectionState()
                    self.applyStateTransition(to: confirmedState, notify: notify)
                }
                pendingDebounceWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: item)
            }
            return
        }

        // 若重新戴回双耳 (connected) 或其他状态跃迁：立即取消待确认任务，0ms 立即执行
        pendingDebounceWorkItem?.cancel()
        pendingDebounceWorkItem = nil

        applyStateTransition(to: candidateState, notify: notify)
    }

    private func applyStateTransition(to newState: SUHeadphoneConnectionState, notify: Bool) {
        stateLock.lock()
        let oldState = connectionState
        let isMonitoring = isMonitoringActive
        let isStreaming = motionManager.isDeviceMotionActive
        if oldState != newState {
            connectionState = newState
        }
        stateLock.unlock()

        if oldState != newState {
            SULogger.motion.notice("AirPods connection state transition: \(oldState.rawValue) -> \(newState.rawValue)")
            if notify {
                DispatchQueue.main.async { [weak self] in
                    self?.onConnectionStateChanged?(newState)
                }
            }
        }

        // 核心智能挂起与自动恢复：用户摘下耳机挂起，重新戴上零点击自动恢复追踪
        if isMonitoring {
            if newState == .connected && !isStreaming {
                startMotionUpdatesInternal()
            } else if newState != .connected && isStreaming {
                motionManager.stopDeviceMotionUpdates()
                SULogger.motion.info("Suspended motion updates due to state: \(newState.rawValue)")
            }
        }
    }

    func startMonitoring() {
        stateLock.lock()
        isMonitoringActive = true
        stateLock.unlock()

        startHeartbeatTimer()
        reevaluateConnectionState(notify: true)

        stateLock.lock()
        let canStream = (connectionState == .connected)
        stateLock.unlock()

        if canStream {
            startMotionUpdatesInternal()
        } else {
            SULogger.motion.info("Monitoring started, waiting for AirPods in state: \(self.connectionState.rawValue)")
        }
    }

    private func startMotionUpdatesInternal() {
        guard !motionManager.isDeviceMotionActive else { return }
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else {
                if let error = error {
                    SULogger.motion.error("Headphone motion update error: \(error.localizedDescription)")
                }
                return
            }
            self.handleMotionReading(motion)
        }
        SULogger.motion.info("Started headphone motion tracking updates.")
    }

    func stopMonitoring() {
        stateLock.lock()
        isMonitoringActive = false
        stateLock.unlock()

        stopHeartbeatTimer()

        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
            SULogger.motion.info("Stopped headphone motion tracking updates.")
        }
    }

    func calibrateBaseline() {
        calibrationService.startSampling()
        SULogger.motion.info("Calibration baseline requested.")
    }

    /// 请求动作与健身/耳机运动权限
    func requestMotionAuthorization(completion: (@Sendable (Bool) -> Void)? = nil) {
        let status = CMHeadphoneMotionManager.authorizationStatus()
        switch status {
        case .authorized:
            SULogger.motion.info("Motion authorization already granted.")
            reevaluateConnectionState(notify: true)
            completion?(true)

        case .denied, .restricted:
            SULogger.motion.warning("Motion authorization denied or restricted: \(status == .restricted ? "restricted" : "denied")")
            reevaluateConnectionState(notify: true)
            completion?(false)

        case .notDetermined:
            SULogger.motion.info("Motion authorization not determined, prompting user via startDeviceMotionUpdates.")
            motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
                guard let self = self else { return }
                let newStatus = CMHeadphoneMotionManager.authorizationStatus()
                let granted = (newStatus == .authorized)

                self.stateLock.lock()
                let isMonitoring = self.isMonitoringActive
                self.stateLock.unlock()

                if !isMonitoring {
                    self.motionManager.stopDeviceMotionUpdates()
                }

                self.reevaluateConnectionState(notify: true)
                DispatchQueue.main.async {
                    completion?(granted)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.reevaluateConnectionState(notify: true)
            }

        @unknown default:
            completion?(false)
        }
    }

    private func startHeartbeatTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stopHeartbeatTimer()
            let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
                self?.reevaluateConnectionState(notify: true)
            }
            RunLoop.main.add(timer, forMode: .common)
            self.statusHeartbeatTimer = timer
        }
    }

    private func stopHeartbeatTimer() {
        if Thread.isMainThread {
            self.statusHeartbeatTimer?.invalidate()
            self.statusHeartbeatTimer = nil
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.statusHeartbeatTimer?.invalidate()
                self?.statusHeartbeatTimer = nil
            }
        }
    }

    private func handleMotionReading(_ motion: CMDeviceMotion) {
        let currentPitch = motion.attitude.pitch
        let currentRoll = motion.attitude.roll

        calibrationService.feedSample(pitchRad: currentPitch, rollRad: currentRoll)

        stateLock.lock()
        let bPitch = basePitchRad
        let bRoll = baseRollRad
        stateLock.unlock()

        let reading = stateEngine.processFrame(
            rawPitchRad: currentPitch,
            rawRollRad: currentRoll,
            basePitchRad: bPitch,
            baseRollRad: bRoll
        )

        DispatchQueue.main.async { [weak self] in
            self?.onReadingUpdated?(reading)
        }
    }

    // MARK: - CMHeadphoneMotionManagerDelegate
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        SULogger.motion.notice("AirPods connected to headphone motion manager.")
        reevaluateConnectionState(notify: true)
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        SULogger.motion.notice("AirPods disconnected from headphone motion manager.")
        reevaluateConnectionState(notify: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        pendingDebounceWorkItem?.cancel()
        stopHeartbeatTimer()
        stopMonitoring()
    }
}
