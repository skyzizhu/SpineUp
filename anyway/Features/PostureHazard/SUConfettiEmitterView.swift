//
//  SUConfettiEmitterView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit

/// 30 秒微操完成结算全屏彩花彩屑粒子发射器
final class SUConfettiEmitterView: UIView {

    private var emitterLayer: CAEmitterLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    /// 触发彩带喷射庆祝动效
    func burst() {
        emitterLayer?.removeFromSuperlayer()

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)

        let colors: [UIColor] = [
            .systemGreen,
            .systemOrange,
            .systemYellow,
            .systemPink,
            .systemPurple,
            .systemCyan
        ]

        var cells: [CAEmitterCell] = []
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 22
            cell.lifetime = 3.5
            cell.velocity = 220
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 3
            cell.spin = 3.5
            cell.spinRange = 4.0
            cell.scale = 0.55
            cell.scaleRange = 0.25
            cell.color = color.cgColor
            cell.contents = createConfettiParticleImage(color: color)?.cgImage
            cells.append(cell)
        }

        emitter.emitterCells = cells
        layer.addSublayer(emitter)
        self.emitterLayer = emitter

        // 1.8 秒后停止发射，让残留纸屑飘落完毕
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.emitterLayer?.birthRate = 0
        }

        // 4 秒后清理图层
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            self?.emitterLayer?.removeFromSuperlayer()
            self?.emitterLayer = nil
        }
    }

    private func createConfettiParticleImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 14, height: 8)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2.5)
        ctx.setFillColor(UIColor.white.cgColor)
        path.fill()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer?.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitterLayer?.emitterSize = CGSize(width: bounds.width, height: 1)
    }
}
