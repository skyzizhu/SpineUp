//
//  SUShareSheetHelper.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit

/// 系统级分享弹窗辅助工具 —— 原生拉起 UIActivityViewController，适配 iPhone & iPad/Duo
enum SUShareSheetHelper {

    /// 弹出系统分享面板
    /// - Parameters:
    ///   - image: 生成的卡片图片
    ///   - sourceView: 锚点视图（用于 iPad / iPhone Duo 展开态的 popoverAnchor）
    ///   - presenter: 发起弹出的视图控制器
    @MainActor
    static func presentShareSheet(
        image: UIImage,
        sourceView: UIView,
        presenter: UIViewController
    ) {
        let text = "\(SUAppConfig.shareWatermarkText) · \(SUAppConfig.shareCardFooterNote)"
        let activityVC = UIActivityViewController(
            activityItems: [image, text],
            applicationActivities: nil
        )

        // 适配 iPad 及 iPhone Duo 展开态 popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
            popover.permittedArrowDirections = .any
        }

        presenter.present(activityVC, animated: true)
    }
}
