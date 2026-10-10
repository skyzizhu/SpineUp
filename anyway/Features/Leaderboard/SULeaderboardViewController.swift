//
//  SULeaderboardViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/9.
//

import UIKit
import SnapKit

/// 骨气能量排行榜控制器 —— 正向激励打工人挺拔打卡与社群归属
final class SULeaderboardViewController: SUBaseViewController {

    private let service: SULeaderboardService
    private var currentCategory: SULeaderboardCategory = .energyCoins
    private var entries: [SULeaderboardEntry] = []

    // MARK: - UI Components

    private let myRankCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusLarge
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.06
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 10
        return view
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemOrange
        return iv
    }()

    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let editNameButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        btn.setImage(UIImage(systemName: "pencil.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .systemBlue
        return btn
    }()

    private let rankBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let rankBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .heavy)
        label.textColor = .systemOrange
        return label
    }()

    private let myScoreSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let segmentedControl: UISegmentedControl = {
        let items = SULeaderboardCategory.allCases.map { $0.localizedTitle }
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private let tableHeaderContainerView = UIView()
    private let tableFooterContainerView = UIView()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInsetAdjustmentBehavior = .automatic
        return tv
    }()

    private let positiveHintLabel: UILabel = {
        let label = UILabel()
        label.text = SULocalized("leaderboard_positive_hint", default: "💡 本榜单严格遵循正向激励原则，仅展示挺拔与能量成就，不设立预警负面排行，守护每位打工人的体态自尊心。")
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let refreshControl = UIRefreshControl()
    private var isFetchingRemote = false

    // MARK: - Initializer

    init(service: SULeaderboardService = .shared) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.service = .shared
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = SULocalized("leaderboard_title", default: "骨气能量榜")
        navigationController?.navigationBar.prefersLargeTitles = false

        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SULeaderboardCell.self, forCellReuseIdentifier: SULeaderboardCell.reuseIdentifier)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        updateRefreshControlTitle()

        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renderCurrentData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTableHeaderAndFooter()
        if myRankCard.bounds.width > 0 && myRankCard.bounds.height > 0 {
            myRankCard.layer.shadowPath = UIBezierPath(
                roundedRect: myRankCard.bounds,
                cornerRadius: SULayoutConstants.cornerRadiusLarge
            ).cgPath
        }
    }

    private func layoutTableHeaderAndFooter() {
        let currentWidth = tableView.bounds.width
        guard currentWidth > 0 else { return }

        // 1. 动态自适应 Header 高度 (我的排位卡片 + 周期切换 Segment)
        let headerTargetSize = CGSize(width: currentWidth, height: UIView.layoutFittingCompressedSize.height)
        let calculatedHeaderHeight = tableHeaderContainerView.systemLayoutSizeFitting(
            headerTargetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let finalHeaderHeight = max(calculatedHeaderHeight, 158.0)

        if tableHeaderContainerView.frame.size != CGSize(width: currentWidth, height: finalHeaderHeight) {
            tableHeaderContainerView.frame = CGRect(x: 0, y: 0, width: currentWidth, height: finalHeaderHeight)
            tableView.tableHeaderView = tableHeaderContainerView
        }

        // 2. 动态自适应 Footer 高度 (正向激励文案)
        let footerTargetSize = CGSize(width: currentWidth - SULayoutConstants.horizontalPadding * 3, height: UIView.layoutFittingCompressedSize.height)
        let calculatedFooterHeight = tableFooterContainerView.systemLayoutSizeFitting(
            footerTargetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let finalFooterHeight = max(calculatedFooterHeight, 60.0)

        if tableFooterContainerView.frame.size != CGSize(width: currentWidth, height: finalFooterHeight) {
            tableFooterContainerView.frame = CGRect(x: 0, y: 0, width: currentWidth, height: finalFooterHeight)
            tableView.tableFooterView = tableFooterContainerView
        }
    }

    override func setupSubviews() {
        super.setupSubviews()

        // 整个滚动视图挂载到主视图
        view.addSubview(tableView)

        // 组装可滚动的 TableHeaderView
        tableHeaderContainerView.addSubview(myRankCard)
        myRankCard.addSubview(avatarImageView)
        myRankCard.addSubview(userNameLabel)
        myRankCard.addSubview(editNameButton)
        myRankCard.addSubview(rankBadgeView)
        rankBadgeView.addSubview(rankBadgeLabel)
        myRankCard.addSubview(myScoreSubtitleLabel)
        tableHeaderContainerView.addSubview(segmentedControl)

        // 组装可滚动的 TableFooterView
        tableFooterContainerView.addSubview(positiveHintLabel)

        tableView.tableHeaderView = tableHeaderContainerView
        tableView.tableFooterView = tableFooterContainerView
    }

    override func setupConstraints() {
        super.setupConstraints()

        // 整个滑动视图铺满全屏，x 从 0 开始，y 从 0 开始，底部从 0 开始，系统自动计算安全区域
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Header 内部自动约束
        myRankCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(88)
        }

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView).offset(2)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
        }

        editNameButton.snp.makeConstraints { make in
            make.leading.equalTo(userNameLabel.snp.trailing).offset(6)
            make.centerY.equalTo(userNameLabel)
            make.width.height.equalTo(24)
        }

        rankBadgeView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(userNameLabel)
            make.height.equalTo(24)
        }

        rankBadgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }

        myScoreSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(6)
            make.leading.equalTo(userNameLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(myRankCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.height.equalTo(34)
            make.bottom.equalToSuperview().offset(-8)
        }

        // Footer 内部自动约束
        positiveHintLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding * 1.5)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    override func setupBindings() {
        super.setupBindings()

        editNameButton.addTarget(self, action: #selector(didTapEditUserName), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(didChangeSegment(_:)), for: .valueChanged)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDidChange),
            name: SULocalizationManager.languageDidChangeNotification,
            object: nil
        )
    }

    // MARK: - Data Reload

    private func reloadData() {
        renderCurrentData()
        fetchRemoteData()
    }

    private func renderCurrentData() {
        entries = service.fetchLeaderboard(for: currentCategory)

        // 刷新我的排位卡片
        let userName = SUUserDefaultsManager.shared.userName
        userNameLabel.text = userName

        let personaId = SUPetPersonaManager.shared.currentPersona.rawValue
        avatarImageView.image = UIImage(systemName: personaIcon(for: personaId))

        if let myInfo = service.getCurrentUserRankInfo(for: currentCategory) {
            rankBadgeLabel.text = String(format: SULocalized("leaderboard_my_rank_fmt", default: "第 %d 名"), myInfo.rank)
            switch currentCategory {
            case .energyCoins:
                myScoreSubtitleLabel.text = String(format: SULocalized("leaderboard_my_energy_sub", default: "当前累积 %d 骨气币 · 挺拔保持领先"), myInfo.entry.energyCoins)
            case .postureQuality:
                myScoreSubtitleLabel.text = String(format: SULocalized("leaderboard_my_quality_sub", default: "挺拔质量优秀率 %d%% · 告别低头前探"), myInfo.entry.uprightRatioPercent)
            case .streakDays:
                myScoreSubtitleLabel.text = String(format: SULocalized("leaderboard_my_streak_sub", default: "连续端坐打卡 %d 天 · 坚守体态自律"), myInfo.entry.streakDays)
            }
        }

        tableView.reloadData()
    }

    private func fetchRemoteData() {
        guard !isFetchingRemote else { return }
        isFetchingRemote = true
        let category = currentCategory

        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await self.service.fetchRemoteLeaderboard(for: category)
                await MainActor.run {
                    self.isFetchingRemote = false
                    if self.currentCategory == category {
                        self.renderCurrentData()
                    }
                    self.refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    self.isFetchingRemote = false
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }

    @objc private func handleRefresh() {
        SUAudioFeedbackManager.shared.triggerHapticLightTap()
        fetchRemoteData()
    }

    private func updateRefreshControlTitle() {
        let title = SULocalized("leaderboard_pull_refresh", default: "下拉刷新骨气榜...")
        refreshControl.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
    }

    @objc private func didChangeSegment(_ sender: UISegmentedControl) {
        SUAudioFeedbackManager.shared.triggerHapticSelection()
        if let category = SULeaderboardCategory(rawValue: sender.selectedSegmentIndex) {
            currentCategory = category
            renderCurrentData()
            fetchRemoteData()
        }
    }

    @objc private func didTapEditUserName() {
        SUAudioFeedbackManager.shared.triggerHapticLightTap()
        let alert = UIAlertController(
            title: SULocalized("edit_username_title", default: "修改个性昵称"),
            message: SULocalized("edit_username_msg", default: "给自己起一个响亮的挺拔代号吧！"),
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.text = SUUserDefaultsManager.shared.userName
            tf.placeholder = SULocalized("edit_username_placeholder", default: "如：不低头的极客阿强")
        }
        alert.addAction(UIAlertAction(title: SULocalized("common_cancel", default: "取消"), style: .cancel))
        alert.addAction(UIAlertAction(title: SULocalized("common_confirm", default: "保存"), style: .default) { [weak self] _ in
            guard let self = self, let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
            Task { [weak self] in
                guard let self = self else { return }
                try? await self.service.updateUserName(text)
                await MainActor.run {
                    self.renderCurrentData()
                    self.fetchRemoteData()
                }
            }
        })
        present(alert, animated: true)
    }

    @objc private func handleLanguageDidChange() {
        navigationItem.title = SULocalized("leaderboard_title", default: "骨气能量榜")
        for (i, cat) in SULeaderboardCategory.allCases.enumerated() {
            segmentedControl.setTitle(cat.localizedTitle, forSegmentAt: i)
        }
        positiveHintLabel.text = SULocalized("leaderboard_positive_hint", default: "💡 本榜单严格遵循正向激励原则，仅展示挺拔与能量成就，不设立预警负面排行，守护每位打工人的体态自尊心。")
        updateRefreshControlTitle()
        renderCurrentData()
    }

    private func personaIcon(for id: String) -> String {
        switch id {
        case "cat": return "cat.fill"
        case "coach": return "figure.mind.and.body"
        default: return "briefcase.fill"
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension SULeaderboardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SULeaderboardCell.reuseIdentifier, for: indexPath) as? SULeaderboardCell else {
            return UITableViewCell()
        }
        let entry = entries[indexPath.row]
        cell.configure(with: entry, category: currentCategory)
        return cell
    }
}

// MARK: - SULeaderboardCell

final class SULeaderboardCell: UITableViewCell {
    static let reuseIdentifier = "SULeaderboardCell"

    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .black)
        label.textAlignment = .center
        return label
    }()

    private let crownImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .secondaryLabel
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let tagBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .heavy)
        label.textColor = .systemBlue
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        if let descriptor = UIFont.systemFont(ofSize: 15, weight: .heavy).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 15)
        } else {
            label.font = .systemFont(ofSize: 15, weight: .heavy)
        }
        label.textAlignment = .right
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .secondarySystemGroupedBackground

        contentView.addSubview(crownImageView)
        contentView.addSubview(rankLabel)
        contentView.addSubview(avatarImageView)

        let nameStackView = UIStackView(arrangedSubviews: [nameLabel, tagBadgeLabel])
        nameStackView.axis = .horizontal
        nameStackView.spacing = 6
        nameStackView.alignment = .center
        contentView.addSubview(nameStackView)

        contentView.addSubview(scoreLabel)

        crownImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }

        rankLabel.snp.makeConstraints { make in
            make.center.equalTo(crownImageView)
            make.width.height.equalTo(24)
        }

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalTo(crownImageView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }

        nameStackView.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(scoreLabel.snp.leading).offset(-10)
        }

        tagBadgeLabel.snp.makeConstraints { make in
            make.height.equalTo(18)
        }

        scoreLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        scoreLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with entry: SULeaderboardEntry, category: SULeaderboardCategory) {
        // 排名图标与着色
        if entry.rank == 1 {
            crownImageView.isHidden = false
            crownImageView.image = UIImage(systemName: "crown.fill")
            crownImageView.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
            rankLabel.isHidden = true
        } else if entry.rank == 2 {
            crownImageView.isHidden = false
            crownImageView.image = UIImage(systemName: "medal.fill")
            crownImageView.tintColor = UIColor(white: 0.75, alpha: 1.0)
            rankLabel.isHidden = true
        } else if entry.rank == 3 {
            crownImageView.isHidden = false
            crownImageView.image = UIImage(systemName: "medal.fill")
            crownImageView.tintColor = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0)
            rankLabel.isHidden = true
        } else {
            crownImageView.isHidden = true
            rankLabel.isHidden = false
            rankLabel.text = "\(entry.rank)"
            rankLabel.textColor = .secondaryLabel
        }

        let personaIconName: String
        switch entry.personaId {
        case "cat": personaIconName = "cat.fill"
        case "coach": personaIconName = "figure.mind.and.body"
        default: personaIconName = "briefcase.fill"
        }
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        avatarImageView.image = UIImage(systemName: personaIconName, withConfiguration: iconConfig)

        if entry.isCurrentUser {
            nameLabel.text = "\(entry.userName) " + SULocalized("leaderboard_me_tag", default: "(我)")
            nameLabel.textColor = .systemBlue
            contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        } else {
            nameLabel.text = entry.userName
            nameLabel.textColor = .label
            contentView.backgroundColor = .secondarySystemGroupedBackground
        }

        if let tag = entry.tag {
            tagBadgeLabel.isHidden = false
            tagBadgeLabel.text = "  \(tag)  "
        } else {
            tagBadgeLabel.isHidden = true
        }

        switch category {
        case .energyCoins:
            scoreLabel.text = "\(entry.energyCoins) 🪙"
            scoreLabel.textColor = .systemOrange
        case .postureQuality:
            let fmt = SULocalized("leaderboard_upright_ratio_fmt", default: "%d%% 挺拔")
            scoreLabel.text = String(format: fmt, entry.uprightRatioPercent)
            scoreLabel.textColor = .systemGreen
        case .streakDays:
            let fmt = SULocalized("leaderboard_streak_fmt", default: "%d 天连胜 🔥")
            scoreLabel.text = String(format: fmt, entry.streakDays)
            scoreLabel.textColor = .systemRed
        }
    }
}
