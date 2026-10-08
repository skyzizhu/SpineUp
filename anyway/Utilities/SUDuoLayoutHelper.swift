//
//  SUDuoLayoutHelper.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit

/// iPhone Duo 折叠屏形态模式
enum SUDuoDisplayMode: String, Sendable {
    case compact      // 外屏模式 (Compact Width，单手操作)
    case regularDual  // 内屏完全展开模式 (Regular Width，双栏分屏沉浸体验)
    case tabletop     // 半折叠悬停模式 (Tabletop Pose：上半屏展示内容，下半屏承载控制)
}

/// iPhone Duo 屏幕与多姿态自适应辅助器 —— 遵循 Apple HIG Designing for iPhone Duo 规范
final class SUDuoLayoutHelper {

    /// 判断当前尺寸和环境对应的 Duo 布局模式
    /// - Parameters:
    ///   - size: 当前视图容器尺寸
    ///   - traitCollection: 当前特征集合
    /// - Returns: 计算出的 Duo 形态
    static func currentDisplayMode(size: CGSize, traitCollection: UITraitCollection) -> SUDuoDisplayMode {
        // 内屏展开模式：通常水平宽度具有 Regular 尺寸类或宽度超过分界点
        let isRegularWidth = traitCollection.horizontalSizeClass == .regular || size.width >= SULayoutConstants.duoSplitBreakpointWidth

        if isRegularWidth {
            // 当高度大于宽度且有特定长宽比时，可能处于半折叠桌面态 Tabletop
            // Tabletop 规范：顶部为信息展示区（宠物/气泡），底部为触控交互区（表盘/校准按钮）
            if size.height > size.width && size.height > 800 {
                return .tabletop
            }
            return .regularDual
        }

        return .compact
    }

    /// 计算展开双栏时的分栏宽度比例与中缝避让内边距
    /// - Parameter totalWidth: 视图总可用宽度
    /// - Returns: (左栏宽度, 右栏宽度, 中缝铰链避让间距)
    static func splitColumnLayout(totalWidth: CGFloat) -> (leftWidth: CGFloat, rightWidth: CGFloat, hingeSpacing: CGFloat) {
        let hingeSpacing: CGFloat = 16.0 // 铰链/中缝安全避让保护区
        let availableWidth = max(0, totalWidth - (SULayoutConstants.horizontalPadding * 2) - hingeSpacing)
        let halfWidth = availableWidth / 2.0
        return (leftWidth: halfWidth, rightWidth: halfWidth, hingeSpacing: hingeSpacing)
    }

    /// Tabletop 桌面悬停姿态下计算上下屏幕分割布局
    /// - Parameter totalHeight: 视图总可用高度
    /// - Returns: (上半屏高度, 下半屏高度, 折痕中缝避让间距)
    static func tabletopVerticalLayout(totalHeight: CGFloat) -> (topHeight: CGFloat, bottomHeight: CGFloat, foldSpacing: CGFloat) {
        let foldSpacing: CGFloat = 20.0 // 水平铰链折痕避让间距
        let availableHeight = max(0, totalHeight - foldSpacing)
        let topSection = availableHeight * 0.48 // 上屏留给桌宠与台词气泡
        let bottomSection = availableHeight * 0.52 // 下屏留给表盘与校准操作区
        return (topHeight: topSection, bottomHeight: bottomSection, foldSpacing: foldSpacing)
    }
}
