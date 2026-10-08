//
//  SUBaseViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import os

/// 基础视图控制器基类 —— 统一提供生命周期日志、深色模式响应、SnapKit 架构规范与 iPhone Duo 双屏适配钩子
class SUBaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        SULogger.lifecycle.debug("[\(String(describing: type(of: self)))] viewDidLoad")

        setupSubviews()
        setupConstraints()
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SULogger.lifecycle.debug("[\(String(describing: type(of: self)))] viewWillAppear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SULogger.lifecycle.debug("[\(String(describing: type(of: self)))] viewDidDisappear")
    }

    // MARK: - 子类重写构建流程
    /// 1. 添加子视图层级
    func setupSubviews() {}

    /// 2. 使用 SnapKit 配置相对自动布局
    func setupConstraints() {}

    /// 3. 数据与事件绑定 (Combine / AsyncStream / 闭包)
    func setupBindings() {}

    // MARK: - 深色/浅色外观切换响应
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearanceForCurrentTheme()
        }
    }

    /// 子类重写以更新自定义颜色或图元
    func updateAppearanceForCurrentTheme() {
        SULogger.ui.debug("[\(String(describing: type(of: self)))] updateAppearanceForCurrentTheme: \(self.traitCollection.userInterfaceStyle.rawValue)")
    }

    // MARK: - iPhone Duo 双屏与折叠屏响应式适配
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.adaptLayoutForSize(size)
        })
    }

    /// 子类重写以响应 iPhone Duo 的展开态(Regular Width)与外屏态(Compact Width)切换
    func adaptLayoutForSize(_ size: CGSize) {
        let isDualPane = size.width >= SULayoutConstants.duoSplitBreakpointWidth
        SULogger.ui.debug("[\(String(describing: type(of: self)))] adaptLayoutForSize: \(size.width)x\(size.height), isDualPane=\(isDualPane)")
    }

    deinit {
        SULogger.lifecycle.debug("[\(String(describing: type(of: self)))] deallocated")
    }
}
