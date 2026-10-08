//
//  SUPetVisualContainerView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SwiftUI
import SnapKit

/// 独立封装视图：宠物视觉容器组件 —— 通过 UIHostingController 挂载 SwiftUI SUPetAnimatedView
final class SUPetVisualContainerView: UIView {

    private var hostingController: UIHostingController<SUPetAnimatedView>?
    private var currentState: SUPostureState = .upright

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContainer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContainer() {
        backgroundColor = .clear

        let petSwiftUIView = SUPetAnimatedView(petState: currentState)
        let hc = UIHostingController(rootView: petSwiftUIView)
        hc.view.backgroundColor = .clear

        addSubview(hc.view)
        hc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.hostingController = hc
    }

    /// 供 ViewController 挂载父子控制器关系
    func attach(to parentViewController: UIViewController) {
        guard let hc = hostingController else { return }
        parentViewController.addChild(hc)
        hc.didMove(toParent: parentViewController)
    }

    /// 响应式更新当前宠物状态
    func configure(with state: SUPostureState) {
        guard state != currentState else { return }
        currentState = state
        hostingController?.rootView = SUPetAnimatedView(petState: state)
    }
}
