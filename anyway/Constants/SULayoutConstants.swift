//
//  SULayoutConstants.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 全局 UI 布局与尺寸常量 —— 所有页面的间距、圆角与尺寸统一定义于此
enum SULayoutConstants {

    // MARK: - 基础间距
    static let horizontalPadding: CGFloat = 20.0
    static let verticalSpacing: CGFloat = 16.0
    static let sectionSpacing: CGFloat = 32.0
    static let cardInternalPadding: CGFloat = 20.0
    static let smallSpacing: CGFloat = 10.0
    static let tinySpacing: CGFloat = 4.0

    // MARK: - 圆角规范
    static let cornerRadius: CGFloat = 20.0
    static let cornerRadiusSmall: CGFloat = 12.0
    static let cornerRadiusMedium: CGFloat = 20.0
    static let cornerRadiusLarge: CGFloat = 28.0
    static let cornerRadiusPill: CGFloat = 999.0

    // MARK: - 控件与模块固定尺寸
    static let primaryButtonHeight: CGFloat = 56.0
    static let secondaryButtonHeight: CGFloat = 46.0
    static let petContainerHeight: CGFloat = 280.0
    static let gaugeViewHeight: CGFloat = 154.0
    static let minimumTouchTargetSize: CGFloat = 44.0

    // MARK: - 动效与过渡
    static let defaultAnimationDuration: TimeInterval = 0.4
    static let petTransitionAnimationDuration: TimeInterval = 0.65
    static let springDampingRatio: CGFloat = 0.70

    // MARK: - iPhone Duo 尺寸适配分界点
    static let duoSplitBreakpointWidth: CGFloat = 600.0 // 超过此宽度进入双栏分屏布局
}
