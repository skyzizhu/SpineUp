//
//  SULegalDetailViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/10.
//

import UIKit
import SnapKit

/// 法律文档类型
enum SULegalDocumentType: Sendable {
    case medicalDisclaimer  // 健康与医疗免责声明 (Guideline 1.4.1)
    case privacyPolicy      // 隐私政策 (Guideline 5.1.1)
    case termsOfService     // 用户服务条款与许可协议
}

/// 法律文档条目模型
struct SULegalSectionItem {
    let title: String
    let content: String
}

/// 法律与合规详情展示页面 —— 优雅排版、卡片分节、严格符合 Apple HIG 与 App Store 审核准则
final class SULegalDetailViewController: SUBaseViewController {

    private let documentType: SULegalDocumentType

    // MARK: - 滚动视图
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let contentView = UIView()

    // MARK: - 头部图标与标题
    private let headerIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let headerDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    // MARK: - 重点提示警示横幅
    private let alertBannerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let alertBannerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    // MARK: - 段落 StackView
    private let sectionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fill
        return stack
    }()

    init(documentType: SULegalDocumentType) {
        self.documentType = documentType
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        self.documentType = .medicalDisclaimer
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
    }

    override func setupSubviews() {
        super.setupSubviews()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerIconView)
        contentView.addSubview(headerTitleLabel)
        contentView.addSubview(headerDateLabel)
        contentView.addSubview(alertBannerView)
        alertBannerView.addSubview(alertBannerLabel)
        contentView.addSubview(sectionsStackView)

        configureContent()
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        headerIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.size.equalTo(48)
        }

        headerTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerIconView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        headerDateLabel.snp.makeConstraints { make in
            make.top.equalTo(headerTitleLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }

        alertBannerView.snp.makeConstraints { make in
            make.top.equalTo(headerDateLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
        }

        alertBannerLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }

        sectionsStackView.snp.makeConstraints { make in
            make.top.equalTo(alertBannerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(SULayoutConstants.horizontalPadding)
            make.bottom.equalToSuperview().offset(-SULayoutConstants.sectionSpacing * 2)
        }
    }

    private func configureContent() {
        let isChinese = SULocalizationManager.shared.currentLanguage == .zhHans || SULocalizationManager.shared.currentLanguage == .zhHant

        switch documentType {
        case .medicalDisclaimer:
            configureMedicalDisclaimer(isChinese: isChinese)
        case .privacyPolicy:
            configurePrivacyPolicy(isChinese: isChinese)
        case .termsOfService:
            configureTermsOfService(isChinese: isChinese)
        }
    }

    // MARK: - 1. 健康与医疗免责声明
    private func configureMedicalDisclaimer(isChinese: Bool) {
        let navTitle = SULocalized("legal_item_medical_title", default: "健康与医疗免责声明")
        navigationItem.title = navTitle
        headerTitleLabel.text = navTitle

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 42, weight: .semibold)
        headerIconView.image = UIImage(systemName: "cross.case.fill", withConfiguration: symbolConfig)
        headerIconView.tintColor = .systemRed

        headerDateLabel.text = SULocalized("legal_effective_date", default: "生效日期：2026年10月")

        alertBannerView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.08)
        alertBannerLabel.textColor = .systemRed
        alertBannerLabel.text = isChinese
            ? "⚠️ 重要须知：SpineUp 绝非医疗器械，不提供任何临床诊断或医疗建议。若您患有颈椎病或感到任何身体不适，请务必咨询执业医师。"
            : "⚠️ Important: SpineUp is NOT a medical device and does NOT provide medical advice or diagnosis. Always consult a physician for spinal or health conditions."

        let sections: [SULegalSectionItem]
        if isChinese {
            sections = [
                SULegalSectionItem(
                    title: "1. 非医疗器械与非医疗服务声明",
                    content: "SpineUp（包括耳机姿态追踪、微操识别训练、正念专注与骨气评分等全部功能）仅作为日常体态健康习惯养成与专注辅助工具。本应用不是国家药品监督管理局（NMPA）、美国食品药品监督管理局（FDA）或任何其他卫生健康监管机构认可的医疗器械，亦不提供任何形式的医学诊断、临床治疗方案、物理康复治疗或疾病预防服务。"
                ),
                SULegalSectionItem(
                    title: "2. 姿态数据与负重模型性质",
                    content: "应用中所展示的低头俯仰角度、颈椎负重估算值（如“60°低头颈椎等效承受27kg负重”等生物力学模型数据）以及挺拔评分，均基于人体工程学通用统计学学术模型计算，仅供日常参考与不良坐姿警示，切勿将此类数据作为判断个人颈椎生理曲度或病理状态的医学依据。"
                ),
                SULegalSectionItem(
                    title: "3. 专业就医警示与身体不适处理",
                    content: "如果您已确诊患有颈椎病、椎间盘突出、脊柱侧弯、骨质疏松，或日常伴有颈肩慢性疼痛、上肢麻木、头晕目眩或恶心等神经受压症状，请切勿盲目依据本应用进行自我矫正。在开始任何姿势训练前，您应当寻求专业骨科医生、康复理疗师的当面诊断与康复建议。"
                ),
                SULegalSectionItem(
                    title: "4. 紧急情况与免责范围",
                    content: "切勿因参考本应用内的任何功能或文本提示而忽视、替代或延误寻求专业医生的医学诊断。用户因自行采纳本应用数据或未能及时就医而产生的任何直接或间接健康风险，SpineUp 及开发团队均不承担法律责任。"
                )
            ]
        } else {
            sections = [
                SULegalSectionItem(
                    title: "1. Non-Medical Device Notice",
                    content: "SpineUp (including AirPods motion tracking, micro-exercises, mindful sessions, and posture score) is designed solely for fitness awareness and habit formation. It is NOT a medical device certified by the FDA, CE, or health authorities, and does not provide clinical diagnosis, medical therapy, or preventive medical care."
                ),
                SULegalSectionItem(
                    title: "2. Posture & Strain Estimation Nature",
                    content: "All neck tilt angles, cervical strain calculations (such as 27kg load equivalent), and posture metrics are based on generalized biomechanical ergonomic models for educational guidance only. They must not be interpreted as definitive anatomical or clinical diagnostics."
                ),
                SULegalSectionItem(
                    title: "3. Physician Consultation Requirement",
                    content: "If you have pre-existing spinal conditions (e.g., cervical spondylosis, scoliosis, herniated discs) or experience chronic pain, dizziness, or numbness, discontinue use immediately and seek professional guidance from a licensed physician or orthopedic specialist."
                ),
                SULegalSectionItem(
                    title: "4. Limitation of Medical Liability",
                    content: "Never disregard or delay seeking professional medical advice because of information provided in SpineUp. The developers disclaim all liability for any personal injury or health consequences resulting from use or misuse of the app."
                )
            ]
        }

        populateSections(sections)
    }

    // MARK: - 2. 隐私政策
    private func configurePrivacyPolicy(isChinese: Bool) {
        let navTitle = SULocalized("legal_item_privacy_title", default: "隐私政策")
        navigationItem.title = navTitle
        headerTitleLabel.text = navTitle

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 42, weight: .semibold)
        headerIconView.image = UIImage(systemName: "hand.raised.fill", withConfiguration: symbolConfig)
        headerIconView.tintColor = .systemBlue

        headerDateLabel.text = SULocalized("legal_effective_date", default: "生效日期：2026年10月")

        alertBannerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        alertBannerLabel.textColor = .systemBlue
        alertBannerLabel.text = isChinese
            ? "🛡️ 隐私承诺：SpineUp 绝不跨应用追踪您，所有运动传感器与摄像头骨骼算法均 100% 在您设备本地完成，绝不向云端上传原始数据。"
            : "🛡️ Privacy Guarantee: SpineUp never tracks you across apps. Motion and camera computations run 100% on your device locally with zero raw data uploaded."

        let sections: [SULegalSectionItem]
        if isChinese {
            sections = [
                SULegalSectionItem(
                    title: "1. 传感器数据 100% 端侧本地处理",
                    content: "• AirPods 空间运动传感器：通过 CoreMotion 采集的头部陀螺仪与加速度矢量在 iPhone 内存中以 60Hz 实时计算俯仰角，计算完成后即时销毁，绝不上传至任何外部服务器。\n• 前置摄像头微操识别：微操跟练仅使用 Apple Vision 框架在手机本地芯片实时检测人体关节点，不录制、不保存、不上传任何视频图像或人脸生物特征信息。"
                ),
                SULegalSectionItem(
                    title: "2. Apple HealthKit 健康数据合规",
                    content: "在获得您的明确授权后，SpineUp 仅将您的挺拔专注时长同步写入 Apple Health 的“正念时间 (Mindful Session)”。我们严格遵守 Apple HealthKit 开发者隐私规范，绝不将任何健康数据用于商业广告、受众画像或与任何第三方共享。"
                ),
                SULegalSectionItem(
                    title: "3. 访客匿名化与零个人信息收集",
                    content: "应用采用基于 Keychain 的匿名设备随机标识符（UUID）建立安全会话，无需用户绑定手机号码、电子邮箱、真实姓名或身份证件。我们不收集任何可直接识别您个人身份的信息。"
                ),
                SULegalSectionItem(
                    title: "4. 零追踪与第三方广告免责",
                    content: "SpineUp 不包含任何第三方广告追踪 SDK，不接入数据中介商，不进行跨应用或跨网站的用户追踪（App Tracking Transparency: False）。"
                ),
                SULegalSectionItem(
                    title: "5. 用户数据控制与彻底删除权",
                    content: "您对本机的历史体态记录和偏好拥有完全控制权。您可以随时在 iOS 系统设置中关闭传感器或相机权限，或在应用内一键清除所有本地缓存与配置。"
                )
            ]
        } else {
            sections = [
                SULegalSectionItem(
                    title: "1. 100% On-Device Sensor Processing",
                    content: "• Headphone Motion Data: Real-time gyroscope and accelerometer vectors from your AirPods are processed in local memory at 60Hz and discarded immediately. No raw sensor streams are transmitted to any server.\n• Camera Vision Tracking: Micro-exercises process front-camera frames on-device using the Apple Vision framework. No video frames, photos, or facial biometric data are recorded or uploaded."
                ),
                SULegalSectionItem(
                    title: "2. Apple HealthKit Privacy Compliance",
                    content: "With your explicit permission, SpineUp writes upright focus durations as Mindful Sessions to Apple Health. We strictly adhere to HealthKit privacy guidelines: health data is never sold, used for advertising, or disclosed to third parties."
                ),
                SULegalSectionItem(
                    title: "3. Anonymous Device UUID & No Personal Data",
                    content: "SpineUp authenticates using an anonymous Keychain-stored device UUID. We do not require registration with phone numbers, emails, or personal identities."
                ),
                SULegalSectionItem(
                    title: "4. Zero Cross-App Tracking",
                    content: "We do not track users across third-party websites or apps. We do not use advertising identifiers (IDFA) or third-party ad networks."
                ),
                SULegalSectionItem(
                    title: "5. Data Control & Deletion Rights",
                    content: "You can revoke sensor permissions in iOS Settings or wipe local application storage at any time."
                )
            ]
        }

        populateSections(sections)
    }

    // MARK: - 3. 用户服务条款
    private func configureTermsOfService(isChinese: Bool) {
        let navTitle = SULocalized("legal_item_terms_title", default: "用户服务条款")
        navigationItem.title = navTitle
        headerTitleLabel.text = navTitle

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 42, weight: .semibold)
        headerIconView.image = UIImage(systemName: "doc.plaintext.fill", withConfiguration: symbolConfig)
        headerIconView.tintColor = .systemIndigo

        headerDateLabel.text = SULocalized("legal_effective_date", default: "生效日期：2026年10月")

        alertBannerView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.08)
        alertBannerLabel.textColor = .systemIndigo
        alertBannerLabel.text = isChinese
            ? "📜 条款摘要：下载与使用 SpineUp 即表示您认可本许可条款。请合理使用本软件，注意保护身体健康与设备安全。"
            : "📜 Terms Summary: Downloading or using SpineUp constitutes acceptance of this agreement. Please use the software responsibly."

        let sections: [SULegalSectionItem]
        if isChinese {
            sections = [
                SULegalSectionItem(
                    title: "1. 软件许可范围",
                    content: "开发者授予您一项个人的、非排他性的、不可转让的、可撤销的有限许可，允许您在拥有或控制的兼容 Apple 设备上运行 SpineUp，仅供个人非商业性质的体态习惯养成目的使用。"
                ),
                SULegalSectionItem(
                    title: "2. 用户行为规范与禁止行为",
                    content: "您同意不得对本软件进行反编译、反汇编、逆向工程或破解；不得利用任何自动化手段恶意请求云端服务接口；不得将本软件用于任何违反适格法律法规的场景。"
                ),
                SULegalSectionItem(
                    title: "3. 硬件兼容性与使用建议",
                    content: "本应用的部分核心体态追踪功能依赖具备空间音频与运动传感器的兼容耳机（如 AirPods Pro、AirPods 3/4、AirPods Max）。佩戴耳机时请确保适宜音量，并在安全环境（如办公室或室内工位）下使用，切勿在驾驶、骑行或高危操作中分心使用。"
                ),
                SULegalSectionItem(
                    title: "4. 知识产权保护",
                    content: "SpineUp 包含的所有程序代码、算法设计、宠物拟人形象、图形 UI、声音特效及品牌标识均属于开发者所有，受著作权与知识产权法律保护。"
                ),
                SULegalSectionItem(
                    title: "5. 免责与责任限制",
                    content: "在适用法律允许的最大范围内，本软件按“按现状 (AS IS)”提供，不附带任何形式的明示或暗示保证。开发者对于因使用或无法使用本软件而导致的任何间接性、附带性或后果性损失不承担任何赔偿责任。"
                ),
                SULegalSectionItem(
                    title: "6. 条款变更与解释",
                    content: "开发者保留适时更新本服务条款的权利。更新后的条款将通过应用内更新发布。继续使用本应用即视为您接受修订后的条款。"
                )
            ]
        } else {
            sections = [
                SULegalSectionItem(
                    title: "1. End User License Grant",
                    content: "The developer grants you a personal, non-exclusive, non-transferable, revocable license to use SpineUp on compatible Apple devices for non-commercial personal posture wellness purposes."
                ),
                SULegalSectionItem(
                    title: "2. Prohibited Uses",
                    content: "You agree not to reverse engineer, decompile, or tamper with the software, or abuse cloud API endpoints with unauthorized automated scripts."
                ),
                SULegalSectionItem(
                    title: "3. Hardware Requirements & Safety",
                    content: "Spatial tracking features require compatible Apple headphones (AirPods Pro, AirPods 3/4, AirPods Max). Exercise caution with audio volumes and do not use the app in hazardous environments such as operating machinery or driving."
                ),
                SULegalSectionItem(
                    title: "4. Intellectual Property",
                    content: "All code, UI designs, character artwork, algorithms, and trademarks associated with SpineUp are the exclusive property of the developers."
                ),
                SULegalSectionItem(
                    title: "5. Limitation of Liability",
                    content: "To the maximum extent permitted by applicable law, the software is provided 'AS IS' without warranty. The developers shall not be liable for any incidental or consequential damages."
                ),
                SULegalSectionItem(
                    title: "6. Modifications to Terms",
                    content: "We reserve the right to revise these Terms at any time. Continued use of the app signifies acceptance of updated terms."
                )
            ]
        }

        populateSections(sections)
    }

    private func populateSections(_ sections: [SULegalSectionItem]) {
        for item in sections {
            let cardView = UIView()
            cardView.backgroundColor = .secondarySystemGroupedBackground
            cardView.layer.cornerRadius = SULayoutConstants.cornerRadiusSmall
            cardView.layer.cornerCurve = .continuous

            let titleLabel = UILabel()
            titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
            titleLabel.textColor = .label
            titleLabel.numberOfLines = 0
            titleLabel.text = item.title

            let contentLabel = UILabel()
            contentLabel.font = .systemFont(ofSize: 13, weight: .regular)
            contentLabel.textColor = .secondaryLabel
            contentLabel.numberOfLines = 0
            contentLabel.text = item.content

            cardView.addSubview(titleLabel)
            cardView.addSubview(contentLabel)

            titleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(14)
                make.leading.trailing.equalToSuperview().inset(16)
            }

            contentLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().offset(-14)
            }

            sectionsStackView.addArrangedSubview(cardView)
        }
    }
}
