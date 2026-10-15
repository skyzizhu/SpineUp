//
//  SUDebugSimulatorCardView.swift
//  anyway
//
//  Created by Antigravity on 2026/10/15.
//

#if targetEnvironment(simulator)
import UIKit
import SnapKit

/// 模拟器专属体态调试面板 —— 支持通过滑块或预设档位实时注入低头角度与耳机连接状态，便于界面预览与 App Store 截图
final class SUDebugSimulatorCardView: UIView {

    var onAngleChanged: ((Double) -> Void)?
    var onToggleConnection: ((Bool) -> Void)?

    private var isConnected: Bool = true
    private var isCollapsed: Bool = false

    private let containerCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusMedium
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 10
        return view
    }()

    private let headerContainerView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "🛠️ 模拟器体态调试滑块"
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let angleValueLabel: UILabel = {
        let label = UILabel()
        label.text = "0.0° · 端正挺拔"
        label.font = .monospacedDigitSystemFont(ofSize: 12.5, weight: .bold)
        label.textColor = .systemGreen
        label.textAlignment = .right
        return label
    }()

    private let toggleCollapseButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
        config.baseForegroundColor = .secondaryLabel
        var titleAttr = AttributedString("收起")
        titleAttr.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        config.attributedTitle = titleAttr
        let button = UIButton(configuration: config)
        return button
    }()

    private let expandableStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        return stack
    }()

    private let sliderRowView = UIView()

    private let minLabel: UILabel = {
        let label = UILabel()
        label.text = "0°"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let maxLabel: UILabel = {
        let label = UILabel()
        label.text = "60°"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let pitchSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 0.0
        s.maximumValue = 60.0
        s.value = 0.0
        s.tintColor = .systemBlue
        return s
    }()

    private let buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()

    private let uprightPresetButton = SUDebugSimulatorCardView.createPresetButton(title: "0° 端正", color: .systemGreen)
    private let slightPresetButton = SUDebugSimulatorCardView.createPresetButton(title: "18° 轻微", color: .systemOrange)
    private let severePresetButton = SUDebugSimulatorCardView.createPresetButton(title: "35° 驼背", color: .systemRed)
    private let connectionToggleButton = SUDebugSimulatorCardView.createPresetButton(title: "🎧 断连/连接", color: .systemIndigo)

    init() {
        super.init(frame: .zero)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func createPresetButton(title: String, color: UIColor) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = color.withAlphaComponent(0.12)
        config.baseForegroundColor = color
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        var titleAttr = AttributedString(title)
        titleAttr.font = UIFont.systemFont(ofSize: 11.5, weight: .bold)
        config.attributedTitle = titleAttr
        let button = UIButton(configuration: config)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        return button
    }

    private func setupUI() {
        addSubview(containerCard)
        containerCard.addSubview(headerContainerView)
        headerContainerView.addSubview(titleLabel)
        headerContainerView.addSubview(angleValueLabel)
        headerContainerView.addSubview(toggleCollapseButton)

        containerCard.addSubview(expandableStackView)

        sliderRowView.addSubview(minLabel)
        sliderRowView.addSubview(pitchSlider)
        sliderRowView.addSubview(maxLabel)
        expandableStackView.addArrangedSubview(sliderRowView)

        buttonStackView.addArrangedSubview(uprightPresetButton)
        buttonStackView.addArrangedSubview(slightPresetButton)
        buttonStackView.addArrangedSubview(severePresetButton)
        buttonStackView.addArrangedSubview(connectionToggleButton)
        expandableStackView.addArrangedSubview(buttonStackView)

        containerCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(26)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        toggleCollapseButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }

        angleValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(toggleCollapseButton.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(4)
        }

        expandableStackView.snp.makeConstraints { make in
            make.top.equalTo(headerContainerView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        minLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.equalTo(20)
        }

        maxLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(24)
        }

        pitchSlider.snp.makeConstraints { make in
            make.leading.equalTo(minLabel.snp.trailing).offset(8)
            make.trailing.equalTo(maxLabel.snp.leading).offset(-8)
            make.top.bottom.centerY.equalToSuperview()
            make.height.equalTo(32)
        }

        buttonStackView.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
    }

    private func setupActions() {
        pitchSlider.addTarget(self, action: #selector(didChangeSlider(_:)), for: .valueChanged)
        toggleCollapseButton.addTarget(self, action: #selector(didTapCollapse), for: .touchUpInside)

        uprightPresetButton.addTarget(self, action: #selector(didTapUpright), for: .touchUpInside)
        slightPresetButton.addTarget(self, action: #selector(didTapSlight), for: .touchUpInside)
        severePresetButton.addTarget(self, action: #selector(didTapSevere), for: .touchUpInside)
        connectionToggleButton.addTarget(self, action: #selector(didTapToggleConnection), for: .touchUpInside)
    }

    @objc private func didChangeSlider(_ sender: UISlider) {
        let angle = Double(sender.value)
        updateAngleLabel(angle: angle)
        onAngleChanged?(angle)
    }

    @objc private func didTapUpright() {
        pitchSlider.setValue(0.0, animated: true)
        updateAngleLabel(angle: 0.0)
        onAngleChanged?(0.0)
    }

    @objc private func didTapSlight() {
        pitchSlider.setValue(18.0, animated: true)
        updateAngleLabel(angle: 18.0)
        onAngleChanged?(18.0)
    }

    @objc private func didTapSevere() {
        pitchSlider.setValue(35.0, animated: true)
        updateAngleLabel(angle: 35.0)
        onAngleChanged?(35.0)
    }

    @objc private func didTapToggleConnection() {
        isConnected.toggle()
        onToggleConnection?(isConnected)
    }

    @objc private func didTapCollapse() {
        isCollapsed.toggle()
        UIView.animate(withDuration: 0.25) {
            self.expandableStackView.isHidden = self.isCollapsed
            self.expandableStackView.alpha = self.isCollapsed ? 0 : 1
            self.toggleCollapseButton.setTitle(self.isCollapsed ? "展开" : "收起", for: .normal)
            self.layoutIfNeeded()
        }
    }

    private func updateAngleLabel(angle: Double) {
        if angle >= 30.0 {
            angleValueLabel.text = String(format: "%.1f° · 严重驼背", angle)
            angleValueLabel.textColor = .systemRed
        } else if angle >= 15.0 {
            angleValueLabel.text = String(format: "%.1f° · 轻微低头", angle)
            angleValueLabel.textColor = .systemOrange
        } else {
            angleValueLabel.text = String(format: "%.1f° · 端正挺拔", angle)
            angleValueLabel.textColor = .systemGreen
        }
    }
}
#endif
