//
//  SUSettingsViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import UIKit
import SnapKit

/// Tab 3: 我的与个性化设置 (人设切换/校准灵敏度)
final class SUSettingsViewController: SUBaseViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "设置与个性化"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "\(SUAppConfig.appDisplayName) v\(SUAppConfig.appVersion)"
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    override func setupSubviews() {
        super.setupSubviews()
        navigationItem.title = "设置"

        view.addSubview(titleLabel)
        view.addSubview(versionLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(SULayoutConstants.verticalSpacing * 2)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        versionLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-SULayoutConstants.verticalSpacing * 2)
            make.centerX.equalToSuperview()
        }
    }
}
