//
//  SULiquidGlassView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SwiftUI

// MARK: - UIKit SULiquidGlassView (iOS 26+ Native UIGlassEffect)

/// 苹果「液态玻璃」(Liquid Glass) 核心材质容器视图 (iOS 26+ 规范)
/// - 整合 iOS 26.0 原生 `UIGlassEffect` 与流体光学质感
/// - 遵循 Hardware Concentric Curvature 硬件同心曲率圆角 (`.continuous`)
/// - 完整支持 `Reduce Transparency` 辅助功能动态平滑降级
@MainActor
final class SULiquidGlassView: UIView {

    // MARK: - 配置属性
    public var cornerRadius: CGFloat {
        didSet {
            updateCorners()
        }
    }

    public var isInteractive: Bool {
        didSet {
            updateEffect()
        }
    }

    public var glassTintColor: UIColor? {
        didSet {
            updateEffect()
        }
    }

    public var isCapsule: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: - 子视图
    private let visualEffectView = UIVisualEffectView()
    private let fallbackView = UIView()

    /// 外部内容承载容器
    public var contentView: UIView {
        return visualEffectView.contentView
    }

    // MARK: - 初始化
    public init(
        cornerRadius: CGFloat = 16.0,
        isInteractive: Bool = false,
        tintColor: UIColor? = nil,
        isCapsule: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
        self.glassTintColor = tintColor
        self.isCapsule = isCapsule
        super.init(frame: .zero)

        setupView()
        observeAccessibility()
    }

    required init?(coder: NSCoder) {
        self.cornerRadius = 16.0
        self.isInteractive = false
        self.glassTintColor = nil
        self.isCapsule = false
        super.init(coder: coder)

        setupView()
        observeAccessibility()
    }

    // MARK: - 视图装配
    private func setupView() {
        clipsToBounds = true
        layer.cornerCurve = .continuous

        // Specular 边缘高光微反射边框 (模拟液态玻璃微倒角反光)
        layer.borderWidth = 0.5
        updateBorderColor()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateBorderColor()
        }

        // 挂载辅助功能降级垫底视图
        fallbackView.backgroundColor = .secondarySystemBackground
        fallbackView.isHidden = !UIAccessibility.isReduceTransparencyEnabled
        addSubview(fallbackView)

        // 挂载液态玻璃特效视图
        addSubview(visualEffectView)

        updateEffect()
        updateCorners()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fallbackView.frame = bounds
        visualEffectView.frame = bounds

        if isCapsule {
            let capsuleRadius = bounds.height / 2.0
            layer.cornerRadius = capsuleRadius
            visualEffectView.layer.cornerRadius = capsuleRadius
            fallbackView.layer.cornerRadius = capsuleRadius
        }
    }

    private func updateCorners() {
        guard !isCapsule else { return }
        layer.cornerRadius = cornerRadius
        visualEffectView.layer.cornerRadius = cornerRadius
        fallbackView.layer.cornerRadius = cornerRadius
    }

    private func updateBorderColor() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let borderAlpha: CGFloat = isDark ? 0.22 : 0.12
        layer.borderColor = UIColor.label.withAlphaComponent(borderAlpha).cgColor
    }

    // MARK: - 液态玻璃效果配置 (iOS 26+)
    private func updateEffect() {
        if UIAccessibility.isReduceTransparencyEnabled {
            // 辅助功能开启减弱透明度时：优雅降级为纯净次级系统背景，禁用重度模糊
            visualEffectView.effect = nil
            visualEffectView.isHidden = true
            fallbackView.isHidden = false
            return
        }

        visualEffectView.isHidden = false
        fallbackView.isHidden = true

        // iOS 26 原生 UIGlassEffect 配置
        let glassEffect = UIGlassEffect(style: .regular)
        glassEffect.isInteractive = isInteractive
        if let tint = glassTintColor {
            glassEffect.tintColor = tint
        }
        visualEffectView.effect = glassEffect
    }

    private func observeAccessibility() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReduceTransparencyChanged),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleReduceTransparencyChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateEffect()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - SwiftUI Liquid Glass Modifier

/// SwiftUI 液态玻璃通用样式修饰器
struct SULiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16.0
    var isInteractive: Bool = false
    var tintColor: Color? = nil
    var isCapsule: Bool = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: isCapsule ? 100 : cornerRadius, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                } else {
                    RoundedRectangle(cornerRadius: isCapsule ? 100 : cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            if let tint = tintColor {
                                RoundedRectangle(cornerRadius: isCapsule ? 100 : cornerRadius, style: .continuous)
                                    .fill(tint.opacity(0.12))
                            }
                        }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: isCapsule ? 100 : cornerRadius, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.2)
                            : Color.black.opacity(0.08),
                        lineWidth: 0.5
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: isCapsule ? 100 : cornerRadius, style: .continuous))
    }
}

extension View {
    /// 应用符合 iOS 26+ Liquid Glass 材质的流体光泽背景
    func suLiquidGlass(
        cornerRadius: CGFloat = 16.0,
        isInteractive: Bool = false,
        tintColor: Color? = nil,
        isCapsule: Bool = false
    ) -> some View {
        self.modifier(SULiquidGlassModifier(
            cornerRadius: cornerRadius,
            isInteractive: isInteractive,
            tintColor: tintColor,
            isCapsule: isCapsule
        ))
    }
}
