# SpineUp · App Store 上架准备与审核自查指南 (App Store Submission Checklist)

## 1. 基础元数据 (Metadata)

- **App 名称 (Uniform Across Locales)**: SpineUp
- **副标题 (Subtitle)**:
  - **EN**: AI Posture Pet & Ergonomics
  - **ZH-Hans**: AI 拟人体态桌面宠物与颈椎守护
  - **ZH-Hant**: AI 擬人體態桌面寵物與頸椎守護
  - **JA**: AI姿勢見守りペット＆頸椎ケア
  - **KO**: AI 바른 자세 데스크 펫 & 척추 가디언
  - **AR**: حارس استقامة الرقبة وحيوانك الأليف الذكي
  - **FR**: Compagnon IA de posture & santé cervicale
- **主类别 (Primary Category)**: Health & Fitness (健康与健美)
- **次类别 (Secondary Category)**: Productivity (效率)
- **年龄分级 (Age Rating)**: 4+ (无限制内容)

---

## 2. 7 语言本地化关键词 (Keywords)

- **en**: `posture,airpods,spine,neck,ergonomics,pet,widget,live activity,mindful,health`
- **zh-Hans**: `坐姿,体态,颈椎,低头族,AirPods,桌宠,灵动岛,健康,脊椎,护颈`
- **zh-Hant**: `坐姿,體態,頸椎,低頭族,AirPods,桌寵,靈動島,健康,脊椎,護頸`
- **ja**: `姿勢,猫背,首,AirPods,健康,ヘルスケア,ウィジェット,ライブアクティビティ,エルゴノミクス`
- **ko**: `자세,거북목,목디스크,에어팟,바른자세,위젯,라이브액티비티,건강,척추`
- **ar**: `وضعية,رقبة,عمود فقري,سماعات,صحة,نشاط مباشر,تأمل,لياقة`
- **fr**: `posture,dos,cervicale,airpods,santé,ergonomie,widget,activité en direct,bien-être`

---

## 3. iPhone Duo 折叠屏专属截图与适配规范

- **外屏态 (Compact Width)**:
  - 聚焦单手敏捷操作、顶部 AirPods 连接状态引导、即时一键校准。
- **展开态 (Regular Width Dual-Pane)**:
  - 左屏：高精动态桌宠微动效与 AI 悬浮台词气泡；
  - 右屏：颈椎物理受力表盘、每日骨气病历单与快捷设置。
- **悬停态 (Tabletop Pose)**:
  - 上半屏：全景宠物陪伴与实时体态；
  - 下半屏：触控操作盘、校准按钮与护颈番茄钟。

---

## 4. 隐私安全与数据合规 (Privacy Nutrition Labels)

| 数据类型 | 采集目的 | 是否追踪用户 | 存储机制 |
| :--- | :--- | :--- | :--- |
| **耳机运动感知 (`CMHeadphoneMotionManager`)** | 核心功能：测量头部俯仰与横滚角度 | 否 | 仅在设备内存计算，不上传任何服务器 |
| **健康正念数据 (`HKCategoryType.mindfulSession`)** | 记录挺拔专注时长至 Apple Health | 否 | 用户授权后本地写入 Apple HealthKit |
| **健康步数数据 (`HKQuantityType.stepCount`)** | 读取当日步数辅助生成个性化体态处方 | 否 | 仅在设备本地只读计算 |
| **本地偏好与战报** | 持久化人格选择、音效开关与历史评分 | 否 | 沙盒 `UserDefaults` 与加密本地 JSON |

---

## 5. App Review 审核要点自查清单 (Guideline Verification)

- [x] **Guideline 2.1 (完整性与降级体验)**: 当用户未连接 AirPods 或使用不支持的耳机时，提供清晰的连接引导横幅 (`SUConnectionBannerView`)，并无缝提供"护颈番茄钟"降级模式 (`SUNeckPomodoroManager`)，保证 App 具备完整可用的基础功能，不被拒审。
- [x] **Guideline 2.5.1 (原生框架合规使用)**: `ActivityKit`、`WidgetKit`、`AppIntents`、`HealthKit` 均遵循苹果官方规范。
- [x] **Guideline 5.1.1 (数据安全与权限描述)**: `Info.plist` 与 7 种语言的 `InfoPlist.strings` 对运动权限与 HealthKit 读写权限提供了明确、用户友好的使用目的解释。
- [x] **Guideline 4.0 (设计规范)**: 全应用图标严格采用苹果原生 SF Symbols，视觉风格清新简约大气；布局支持动态字体、深色模式与阿拉伯语 RTL 镜像适配。
