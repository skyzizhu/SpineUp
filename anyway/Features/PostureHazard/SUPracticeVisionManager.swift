//
//  SUPracticeVisionManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import AVFoundation
import Vision
import os

/// 30 秒微操 AI 视觉姿态识别服务 —— 基于 Apple Vision 框架与前置摄像头关键点追踪
final class SUPracticeVisionManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    // MARK: - 属性
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.spineup.practice.vision.queue", qos: .userInteractive)

    private var currentAction: SUPracticeActionType = .chinTuck
    private var isSessionRunning = false
    private let stateLock = NSLock()

    /// 姿态达标识别回调：(是否符合动作标准, 实时提示文案)
    var onPoseMatched: (@Sendable (Bool, String) -> Void)?

    /// 呼吸胸腔舒展识别回调：(是否检测到深吸气胸腔舒展)
    var onChestExpansionDetected: (@Sendable (Bool) -> Void)?

    /// 视频预览层
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    /// 呼吸检测基准肩宽缓冲 (用于检测吸气胸腔舒展)
    private var baselineShoulderSpan: CGFloat = 0.0
    private var frameCount: Int = 0

    override init() {
        super.init()
        setupPreviewLayer()
    }

    private func setupPreviewLayer() {
        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        self.previewLayer = preview
    }

    /// 设置当前微操动作类型并重置基准
    func setAction(_ action: SUPracticeActionType) {
        stateLock.lock()
        self.currentAction = action
        self.baselineShoulderSpan = 0.0
        self.frameCount = 0
        stateLock.unlock()
    }

    // MARK: - 权限检测与启动
    func checkCameraPermission(completion: @escaping @Sendable (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    /// 启动摄像头采集会话
    func startSession(completion: @escaping @Sendable (Bool) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.stateLock.lock()
            if self.isSessionRunning {
                self.stateLock.unlock()
                DispatchQueue.main.async { completion(true) }
                return
            }
            self.stateLock.unlock()

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .vga640x480

            // 清理旧输入与输出 (避免重复添加)
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }
            for output in self.captureSession.outputs {
                self.captureSession.removeOutput(output)
            }

            // 获取前置超广角/广角摄像头
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
                return
            }

            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }

            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ]
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)

            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)

                // 强制将输出画面配置为正向肖像模式与镜像对齐
                if let connection = self.videoOutput.connection(with: .video) {
                    if #available(iOS 17.0, *) {
                        if connection.isVideoRotationAngleSupported(90.0) {
                            connection.videoRotationAngle = 90.0
                        }
                    } else {
                        if connection.isVideoOrientationSupported {
                            connection.videoOrientation = .portrait
                        }
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()

            self.stateLock.lock()
            self.isSessionRunning = true
            self.stateLock.unlock()

            DispatchQueue.main.async {
                completion(true)
            }
        }
    }

    /// 停止摄像头采集 (支持同步停止，避免在 dismiss/deinit 时硬件会话仍在运行导致崩溃)
    func stopSession(synchronously: Bool = false) {
        let stopWork = { [weak self] in
            guard let self = self else { return }
            self.stateLock.lock()
            guard self.isSessionRunning else {
                self.stateLock.unlock()
                return
            }
            self.isSessionRunning = false
            self.stateLock.unlock()

            // 1. 立即解除委托，切断帧缓冲区回调流
            self.videoOutput.setSampleBufferDelegate(nil, queue: nil)

            // 2. 停止硬件会话采集
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            // 3. 在事务中安全解绑输入与输出
            self.captureSession.beginConfiguration()
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }
            for output in self.captureSession.outputs {
                self.captureSession.removeOutput(output)
            }
            self.captureSession.commitConfiguration()
        }

        if synchronously {
            sessionQueue.sync(execute: stopWork)
        } else {
            sessionQueue.async(execute: stopWork)
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        stateLock.lock()
        let action = self.currentAction
        stateLock.unlock()

        switch action {
        case .chinTuck:
            analyzeChinTuckPose(pixelBuffer: pixelBuffer)
        case .wStretch:
            analyzeUpperBodyWPose(pixelBuffer: pixelBuffer)
        }
    }

    // MARK: - 动作 1：麦肯基收下巴分析 (Face Landmarks + Head Alignment)
    private func analyzeChinTuckPose(pixelBuffer: CVPixelBuffer) {
        let faceRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self, error == nil,
                  let results = request.results as? [VNFaceObservation],
                  let face = results.first else {
                self?.notifyPoseMatched(false, tip: SULocalized("vision_tip_face_missing", default: "请正对前置摄像头"))
                return
            }

            // 1. 偏头角与转头角检测 (必须水平正对，避免歪头与斜视)
            let roll = abs(face.roll?.doubleValue ?? 0.0)
            let yaw = abs(face.yaw?.doubleValue ?? 0.0)

            // 2. 俯仰角检测 (Pitch: 0 代表水平平视；负值代表低头俯视；微正值代表收下巴微仰)
            let pitch = face.pitch?.doubleValue ?? 0.0

            let isNotTilted = roll < 0.22 && yaw < 0.30
            // 工位持机场景下，前置镜头通常位于视线微下方 5°~10°，故平视区间科学设定为 [-0.18, 0.22] 弧度 (-10.3° ~ +12.6°)
            let isHorizontalGaze = pitch >= -0.18 && pitch <= 0.22
            let isSevereDroop = pitch < -0.25 // 低头超过约 14.3° 判定为明显垂首

            if isSevereDroop {
                self.notifyPoseMatched(false, tip: SULocalized("vision_tip_keep_forward", default: "两眼平视正前方，背部微靠"))
            } else if isNotTilted && isHorizontalGaze {
                self.notifyPoseMatched(true, tip: SULocalized("vision_tip_chin_good", default: "平视良好！保持下巴向后微缩"))
            } else {
                self.notifyPoseMatched(false, tip: SULocalized("vision_tip_keep_forward", default: "两眼平视正前方，背部微靠"))
            }
        }

        // 输出连接已固定为 portrait + mirrored，故使用标准 .up 即可精准定位
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([faceRequest])
    }

    // MARK: - 动作 2：W 展肩夹背分析 (Body Pose W 形状关节点与呼吸胸腔检测)
    private func analyzeUpperBodyWPose(pixelBuffer: CVPixelBuffer) {
        let bodyPoseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self, error == nil,
                  let results = request.results as? [VNHumanBodyPoseObservation],
                  let body = results.first else {
                self?.notifyPoseMatched(false, tip: SULocalized("vision_tip_body_missing", default: "请将手机稍微立起，确保上半身入镜"))
                return
            }

            do {
                let recognizedPoints = try body.recognizedPoints(.all)
                let leftShoulder = recognizedPoints[.leftShoulder]
                let rightShoulder = recognizedPoints[.rightShoulder]
                let neck = recognizedPoints[.neck]
                let leftElbow = recognizedPoints[.leftElbow]
                let rightElbow = recognizedPoints[.rightElbow]
                let leftWrist = recognizedPoints[.leftWrist]
                let rightWrist = recognizedPoints[.rightWrist]

                let minConfidence: Float = 0.28
                guard let lS = leftShoulder, lS.confidence > minConfidence,
                      let rS = rightShoulder, rS.confidence > minConfidence,
                      let lE = leftElbow, lE.confidence > minConfidence,
                      let rE = rightElbow, rE.confidence > minConfidence else {
                    self.notifyPoseMatched(false, tip: SULocalized("vision_tip_arms_raise", default: "请抬起双肘，呈 W 字形展开"))
                    return
                }

                // 1. 手肘外展贴肋与跨度判断 (双肘横向跨度显著宽于双肩跨度)
                let shoulderSpan = abs(rS.location.x - lS.location.x)
                let elbowSpan = abs(rE.location.x - lE.location.x)
                let isElbowSpanWide = elbowSpan > max(0.12, shoulderSpan * 1.10)
                let isLeftElbowSpread = min(lE.location.x, rE.location.x) < min(lS.location.x, rS.location.x) - 0.015
                let isRightElbowSpread = max(lE.location.x, rE.location.x) > max(lS.location.x, rS.location.x) + 0.015
                let isWSpread = isElbowSpanWide || (isLeftElbowSpread && isRightElbowSpread)

                // 2. 小臂向上屈起呈 W 双翼（若检测到手腕，手腕 y 需高于手肘 y 至少 0.02）
                var isWristsRaised = true
                if let lW = leftWrist, lW.confidence > minConfidence,
                   let rW = rightWrist, rW.confidence > minConfidence {
                    isWristsRaised = (lW.location.y > lE.location.y + 0.02) && (rW.location.y > rE.location.y + 0.02)
                }

                // 3. 避免耸肩（颈部应高于双肩至少 0.015）
                var isNotShrugging = true
                if let n = neck, n.confidence > minConfidence {
                    isNotShrugging = n.location.y > max(lS.location.y, rS.location.y) + 0.015
                }

                // 4. 呼吸胸腔舒展检测：测量双肩横向跨度
                let currentSpan = shoulderSpan
                self.checkChestExpansion(currentSpan: currentSpan)

                if isWSpread && isWristsRaised && isNotShrugging {
                    self.notifyPoseMatched(true, tip: SULocalized("vision_tip_w_perfect", default: "W 形姿态标准！肩胛骨向中线夹紧"))
                } else if !isWSpread {
                    self.notifyPoseMatched(false, tip: SULocalized("vision_tip_arms_raise", default: "请抬起双肘，呈 W 字形展开"))
                } else {
                    self.notifyPoseMatched(false, tip: SULocalized("vision_tip_w_adjust", default: "双手屈起，向后夹紧肩胛骨"))
                }
            } catch {
                self.notifyPoseMatched(false, tip: "")
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([bodyPoseRequest])
    }

    private func checkChestExpansion(currentSpan: CGFloat) {
        stateLock.lock()
        frameCount += 1
        if baselineShoulderSpan == 0.0 || frameCount < 10 {
            baselineShoulderSpan = (baselineShoulderSpan * 0.7) + (currentSpan * 0.3)
            stateLock.unlock()
            return
        }
        let ratio = currentSpan / baselineShoulderSpan
        stateLock.unlock()

        // 当肩宽因深吸气挺胸而扩展超过 2.5% 时
        if ratio > 1.025 {
            DispatchQueue.main.async { [weak self] in
                self?.onChestExpansionDetected?(true)
            }
        }
    }

    private func notifyPoseMatched(_ isMatched: Bool, tip: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onPoseMatched?(isMatched, tip)
        }
    }

    /// 解除预览图层关联
    func detachPreviewLayer() {
        previewLayer?.session = nil
        previewLayer?.removeFromSuperlayer()
    }

    deinit {
        // 在 deinit 中必须同步停止硬件会话，防止由于异步释放导致 AVCaptureSession 在运行状态下被销毁触发系统 crash
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        captureSession.beginConfiguration()
        for input in captureSession.inputs { captureSession.removeInput(input) }
        for output in captureSession.outputs { captureSession.removeOutput(output) }
        captureSession.commitConfiguration()
        previewLayer?.session = nil
        previewLayer?.removeFromSuperlayer()
    }
}
