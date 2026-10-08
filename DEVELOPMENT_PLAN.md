# SpineUp: AI Posture Pet — 产品详细研发计划与技术规范文档

> **项目名称**：SpineUp: AI Posture Pet (中文名：骨气)  
> **核心定位**：基于 AirPods 空间姿态感知 + AI 拟人情绪桌宠的无感体态守护应用  
> **文档用途**：作为后续所有开发阶段的核心基准指南与检查清单（Checklist）。后续开发任务将严格遵循本计划中的阶段规划逐步执行。  
> **技术规范**：本文件聚焦产品需求与任务分解。详细的技术架构与编码规范请参阅 [`TECH_ARCHITECTURE.md`](./TECH_ARCHITECTURE.md)。两份文件配合使用，不可分离。

---

## 目录
1. [产品定位与核心价值主张](#1-产品定位与核心价值主张)
2. [分阶段 MVP 开发路线图](#2-分阶段-mvp-开发路线图)
   - [Phase 0: 基础架构搭建与环境配置](#phase-0-基础架构搭建与环境配置)
   - [Phase 1: MVP v0.1 — 姿态感知与核心状态闭环](#phase-1-mvp-v01--姿态感知与核心状态闭环)
   - [Phase 2: MVP v0.2 — AI 拟人情绪系统与语音预警](#phase-2-mvp-v02--ai-拟人情绪系统与语音预警)
   - [Phase 3: MVP v0.3 — 脊椎受力科学模型与社交战报](#phase-3-mvp-v03--脊椎受力科学模型与社交战报)
   - [Phase 4: v1.0 — iOS 原生生态体验与上线打磨](#phase-4-v10--ios-原生生态体验与上线打磨)
3. [核心数据结构与状态机设计](#3-核心数据结构与状态机设计)
4. [开发规范与后续执行准则](#4-开发规范与后续执行准则)

---

## 1. 产品定位与核心价值主张

### 1.1 痛点与破局点
* **传统体态应用痛点**：依靠前置摄像头常驻扫描，发热严重、极其耗电，且侵犯用户在办公室或私密环境的隐私；或者仅依靠定时死板提醒，缺乏吸引力。
* **SpineUp 破局点**：
  1. **零摄像头侵入**：全流程利用 AirPods 的内置运动传感器（`CMHeadphoneMotionManager`），无感、低功耗、零隐私焦虑。
  2. **情绪价值与游戏化桌宠**：将体态数据映射为"桌宠的生命力/形态"。你挺拔，宠物元气满满挖矿升级；你低头，宠物被巨石压扁/哀嚎求救。
  3. **AI 毒舌/治愈嘴替**：告别冰冷机械的"哔哔"报警声，由 AI 带来千人千面的情境化语音与吐槽。

### 1.2 目标用户画像
| 用户群体 | 核心场景 | 核心诉求 |
| :--- | :--- | :--- |
| **办公室白领/程序员** | 长时间伏案工作 | 颈椎保护提醒，无打扰感 |
| **大学生/考研/备考** | 图书馆/自习室刷题 | 低侵入性但有效的体态纠正 |
| **远程居家办公者** | 沙发/床上办公 | 无需额外设备的自律辅助 |
| **健康管理关注者** | 日常生活 | 长期数据追踪与正向激励 |

### 1.3 商业化路径规划
1. **基础功能免费**：核心姿态监测 + 单一默认宠物人格 + 每日基础战报。
2. **高级订阅（SpineUp Pro）**：解锁全部 AI 人格语音包、完整历史数据分析趋势图、去水印高清分享卡片、自定义阈值灵敏度。
3. **一次性付费**：额外宠物主题皮肤包、节日限定语音包。

---

## 2. 分阶段 MVP 开发路线图

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SpineUp 阶段递进路线图                           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
    ▼ Phase 0: 基础设施搭建 (UIKit 工程化、模块解耦、SPM 依赖、Mock 传感器)
    ▼ Phase 1: MVP v0.1 核心感知闭环 (AirPods 监听 + 坐姿校准 + 宠物三态变化)
    ▼ Phase 2: MVP v0.2 AI 情绪系统 (多重人格 + 动态吐槽台词 + 语音播报)
    ▼ Phase 3: MVP v0.3 科学战报与自传播 (脊椎承重换算 + 骨气病历单 + 分享卡片)
    ▼ Phase 4: v1.0 iOS 生态与打磨 (灵动岛 + Live Activities + 降级方案)
```

---

### Phase 0: 基础架构搭建与环境配置
> **目标**：将工程现代化，建立清晰的模块分层、权限配置与离线调试能力。

- [x] **Task 0.1: 工程清理与 UIKit 现代化入口配置**
  * 保留 `LaunchScreen.storyboard` 与 `Main.storyboard` 入口；页面导航由 `SUSceneDelegate` 代码加载。
  * 在 `Info.plist` 中配置 `UIApplicationSceneManifest`，声明 `SUSceneDelegate` 为场景代理。
  * 设置 Deployment Target 为 **iOS 26.2**。
- [x] **Task 0.2: SPM 第三方依赖引入**
  * 通过 Xcode / SPM 添加并集成：
    * `Alamofire`（网络请求）
    * `SnapKit`（自动布局）
  * 验证 import 与编译全部通过。
- [x] **Task 0.3: 系统权限与 Info.plist 完整配置**
  * `NSMotionUsageDescription`：运动与健身传感器权限说明（AirPods 头部运动监测）。
  * `UIBackgroundModes`：`audio`（后台音频保活以维持传感器监听）。
  * `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`：HealthKit 正念数据读写权限。
- [x] **Task 0.4: 分层目录结构搭建与全局公共配置**
  * 按照规范创建完整分层结构。
  * 创建三层公共配置：`SUAppConfig.swift`（应用级高级别配置）、`SULayoutConstants.swift`（UI级）、`SUMotionConstants.swift`（传感器业务级）。
- [x] **Task 0.5: 基类搭建 (SUBaseViewController / SUBaseNavigationController / SUBaseTabBarController)**
  * `SUBaseViewController`：统一管理生命周期日志、深色/浅色模式响应、SnapKit 闭环、iPhone Duo 响应式适配钩子 `adaptLayoutForSize`。
  * `SUBaseNavigationController`：原生外观配置（`UINavigationBarAppearance`）。
  * `SUBaseTabBarController`：原生标签栏外观（`UITabBarAppearance`）。
- [x] **Task 0.6: 主框架骨架搭建 (TabBar + Navigation + 3大功能页)**
  * 搭建 `SUMainTabBarController`，包含 3 个 Tab：
    * Tab 1：**监测** (SUPostureMonitorViewController) — 姿态状态卡片、角度实时显示、一键校准、SnapKit 相对布局
    * Tab 2：**战报** (SUDailyReportViewController) — 今日骨气病历单骨架
    * Tab 3：**设置** (SUSettingsViewController) — 人设切换与版本信息
  * 采用系统原生 SF Symbols 图标。
- [x] **Task 0.7: 实现 SUMotionServiceProtocol 与传感器双引擎**
  * 定义 `SUMotionServiceProtocol` 协议与数据结构（`SUPostureReading`、`SUPostureState`、`SUHeadphoneConnectionState`）。
  * 实现 `SUMockMotionManager`：模拟器与无耳机调试，支持手动/定时角度注入与状态判定。
  * 实现 `SUHeadphoneMotionManager`：基于 CoreMotion `CMHeadphoneMotionManager` 的真机监听实现。
- [x] **Task 0.8: .gitignore 与版本控制初始化**
  * 创建标准 iOS `.gitignore`。
  * 初始化 Git 仓库。

> **✅ Phase 0 验收标准 (Definition of Done)**：
> * 工程编译零错误零警告。
> * 真机/模拟器运行后进入 TabBar 主框架，3 个 Tab 可正常切换。
> * 模拟器中可看到 MockMotion 浮层滑块，拖动滑块 Console 中能打印 Pitch/Roll 数值。
> * SPM 依赖正常 import 且编译通过。

---

### Phase 1: MVP v0.1 — 姿态感知与核心状态闭环
> **目标**：在真机上跑通 AirPods 实时姿态监听，实现坐姿校准和宠物的基本视觉反馈。

- [x] **Task 1.1: AirPods 耳机连接管理 (`SUHeadphoneMotionManager` 完整实现)**
  * 监听 `CMHeadphoneMotionManager.isDeviceMotionAvailable` 与连接状态变化。
  * 当用户戴上/取下 AirPods 时，UI 能够即时响应状态切换（已连接 / 未连接 / 不支持）。
  * 传感器采样率控制在 10Hz~20Hz（默认 15Hz），平衡精度与电量消耗。
- [x] **Task 1.2: 姿态基准校准系统 (SUCalibrationService)**
  * 提供"一键校准"功能：用户端坐后点击，采集 2 秒内多帧 Pitch/Roll 取均值作为基准零点（Neutral Reference），亦支持即时校准。
  * 校准数据持久化存储（`SUUserDefaultsManager`），App 重启后无需重复校准。
  * 计算相对偏移角 `ΔPitch = CurrentPitch - BasePitch`。
- [x] **Task 1.3: 防抖动与体态状态判定引擎 (SUPostureStateEngine)**
  * **轻度低头阈值**（默认 > 15°）与 **重度低头阈值**（默认 > 25°），阈值可配置。
  * 引入时间缓冲滤波器（Buffer Timer）：低头持续超过 10 秒才判定为异常体态，避免打字、喝水、点头产生误报；端正保持 5 秒判定为复原。
  * 滑动窗口均值平滑（Moving Average Filter）：对连续 8 帧的 Pitch/Roll 取均值，消除传感器噪声。
  * 输出三态枚举：`upright` → `slightSlump` → `severeSlump`，并通过回调通知上层。
- [x] **Task 1.4: 宠物核心形态三态可视化 (SUPetVisualContainerView & SUPetAnimatedView)**
  * 使用 SwiftUI 编写 `SUPetAnimatedView`，通过 `UIHostingController` 嵌入 UIKit 主页中的 `SUPetVisualContainerView`。
  * 状态 1【精神挺拔 `upright`】：宠物元气满满，呼吸动效，周围散发活力光晕。
  * 状态 2【轻微前倾 `slightSlump`】：宠物额头流汗水滴，身体微倾斜，表情犯困。
  * 状态 3【严重驼背 `severeSlump`】：宠物瘫软压扁横向形变，痛苦求救表情。
  * 状态切换时使用 Spring 弹性动画平滑过渡。
- [x] **Task 1.5: 基础轻提示反馈 (SUAudioFeedbackManager 基础版)**
  * 低头超时时触发轻微触觉反馈（`UINotificationFeedbackGenerator`）。
  * 播放清脆的系统提示音（小水滴/提示铃），具备 15 秒最小冷却间隔。
- [x] **Task 1.6: Onboarding 引导流 (SUOnboardingViewController)**
  * 首次启动展示 3 页引导：产品概念介绍、运动传感器权限申请与隐私说明、佩戴与校准教学。
  * 完成后进入主 TabBar 框架，标记 `hasCompletedOnboarding` 至 `SUUserDefaultsManager`。

> **✅ Phase 1 验收标准 (Definition of Done)**：
> * 真机佩戴 AirPods 后，主页宠物实时响应头部倾斜角度变化。
> * 点击"校准"按钮后，端坐为零基准，低头超过 15°/25° 后宠物依次切换为前倾/瘫塌形态。
> * 持续低头超过 10 秒后触发触觉反馈与提示音。
> * 模拟器中通过 Mock 滑块可完整触发以上全部流程。
> * 首次安装展示 Onboarding 引导流。

---

### Phase 2: MVP v0.2 — AI 拟人情绪系统与语音预警
> **目标**：赋予宠物独特的人格与"嘴替"属性，让提醒变得好玩且期待。全 UI 统一严格使用苹果原生 SF Symbols，视觉清新、简约、大气，交互简洁流畅。

- [x] **Task 2.1: 宠物人格配置系统 (SUPetPersonaManager & SUPetPersona)**
  * 预设三种可切换性格（毒舌打工人、傲娇猫猫、温柔私教），统一配备原生 SF Symbols。
  * 用户在"设置"页中可随时通过卡片切换，即时触发试听语音并持久化至 `SUUserDefaultsManager`。
- [x] **Task 2.2: AI 服务抽象层 (SUAIServiceProtocol + 云端/离线双引擎)**
  * 定义 `SUAIServiceProtocol`：`func generateReminder(context: SUPostureContext) async throws -> String`。
  * **云端引擎**：`SUCloudAIEngine`——基于 Alamofire 封装带 3 秒超时熔断机制。
  * **离线引擎**：`SUOfflineAIEngine`——内置 50+ 条多场景（轻度、重度、首次、反复、深夜加班、挺拔鼓励）高质量结构化语料库。
  * 策略：`SUAIService` 统一调度，云端超时/断网时毫秒级无缝降级至离线。
- [x] **Task 2.3: 场景化动态 Prompt 构建器 (SUPromptBuilder & SUPostureContext)**
  * 上下文包含低头角度、持续时长、今日违规频次、时间段、目标人格、连续打卡天数与物理额外负荷。
  * 产出精简（25~45字）适合 TTS 发音的 System & User Prompt。
- [x] **Task 2.4: 语音与播报集成 (SUSpeechManager & Audio Ducking)**
  * 基于 `AVSpeechSynthesizer` 针对不同人格自适应音调 (Pitch) 与语速 (Rate)。
  * `AVAudioSession` 配置 `.playback` 与 `.duckOthers`，播报时柔和压低背景音乐/播客，不粗暴打断。
  * 严格实行 3 分钟防疲劳冷却间隔，支持点击气泡强制试听。
- [x] **Task 2.5: 骨气能量养成系统 (SUSpineEnergyManager)**
  * 端坐挺拔每分钟铸造 1 枚"骨气能量币"，支持多日连续坚持打卡加成系数 (Streak Bonus)。
  * 统计数据与连续坚持天数持久化。
- [x] **Task 2.6: 清新简约 UI 与气泡交互 (SUPetSpeechBubbleView & SUSettingsViewController)**
  * 监测主页悬浮高斯模糊台词气泡，支持轻触回放与触觉微震动。
  * 设置页采用纯原生 SF Symbols、自适应卡片与流畅交互。

> **✅ Phase 2 验收标准 (Definition of Done)**：
> * 可在设置页切换 3 种宠物人格，切换后提醒台词风格立即变化。
> * 低头超时后，耳机中播放与当前人格匹配的语音提醒，音量不干扰正在播放的音乐。
> * 两次语音提醒间隔不少于 3 分钟。
> * 无网络环境下，离线语料库仍可正常输出提醒文案。
> * 能量币随挺拔时间实时累积，App 重启后数据保留。
> * 整个 UI 严格使用 SF 图标，风格清新、简约、大气，交互流畅。

---

### Phase 3: MVP v0.3 — 脊椎受力科学模型与社交战报
> **目标**：打造自传播武器，将每一次专注记录沉淀为可分享的社交资产。全 UI 统一严格使用苹果原生 SF Symbols，视觉清新、简约、大气，交互简洁流畅。

- [x] **Task 3.1: 颈椎承重力学模型 (SUErgonomicsCalculator)**
  * 根据人体工学医学常模（0° 5kg，15° 12kg，30° 18kg，45° 22kg，60° 27kg）计算瞬间受力与额外负荷。
  * 趣味生活化受力换算引擎：将累计颈椎负荷等效折算为珍珠奶茶、建筑红砖、胖橘猫、柴犬、重型哑铃，严格配备原生 SF Symbols。
- [x] **Task 3.2: 每日监测会话数据持久化 (SUPostureSession & SUPostureSessionManager)**
  * 数据实体包含挺拔总时长、低头疲劳时长、最长连续挺拔时长、违规频次、累积额外承重、骨气综合评分 (0~100) 与评级 (S/A/B/C/D)。
  * 线程安全管理今日会话与本地 JSON 自动化持久化，与 `SUPostureMonitorViewModel` 实时传感器事件闭环联动。
- [x] **Task 3.3: AI 生成《今日骨气病历单》 (SUDailyReportGenerator)**
  * 自动化生成具有医学趣味性的临床诊断名称（如"阶段性打工低头综合征"、"早期折叠屏人类蜕变期"）。
  * 包含幽默实用的医生拟人处方，结合当前宠物人格（打工人/猫猫/私教）口吻定制专属寄语台词。
- [x] **Task 3.4: 高颜值社交海报渲染与分享 (SUShareCardView & SUShareSheetHelper)**
  * 清新简约大气的卡片版式，包含品牌 Logo、大号骨气评级徽章、三宫格核心指标、生活化换算横幅与医生诊断书。
  * `renderAsImage()` 无损导出高质量 `UIImage`，并通过 `SUShareSheetHelper` 原生唤起系统 `UIActivityViewController`。
- [x] **Task 3.5: 战报页完整交互 (SUDailyReportViewController & SUDailyReportViewModel)**
  * 原生搭建 Tab 2 战报页，包含顶部等级勋章、4 宫格指标卡、力学换算横幅、AI 病历单卡片与"生成并分享骨气战报"主按钮。
  * 针对 iPhone 单列与 iPhone Duo 展开态双栏自适应排版。

> **✅ Phase 3 验收标准 (Definition of Done)**：
> * 实时体态监测数据即时累加至当日骨气会话并持久化存储。
> * 战报页准确展示骨气评级、端正挺拔率、各项指标及趣味换算比喻。
> * 自动产出《今日骨气病历单》诊断、处方及宠物人格金句。
> * 点击"分享"可无损导出高颜值卡片并唤起系统原生分享面板。
> * 针对 iPhone 与 iPhone Duo 展开态自适应排版。

---

### Phase 4: v1.0 — iOS 原生生态体验与上线打磨
> **目标**：深度契合 Apple 生态，达到 Apple Design Award 水平的精致体验。

- [ ] **Task 4.1: 灵动岛 (Dynamic Island) 深度集成**
  * 紧凑态：小宠物微头像 + 当前状态色指示器（绿/黄/红）。
  * 展开态：展示当前实时倾斜度、本次已坚持挺拔分钟数、宠物微表情。
  * 使用 `ActivityKit` 管理 Live Activity 生命周期。
- [ ] **Task 4.2: 锁屏实时活动 (Live Activities)**
  * 锁屏常驻监控条，后台低功耗更新体态进度。
  * 展示：宠物状态图标 + 今日挺拔时长 + 骨气等级。
- [ ] **Task 4.3: 桌面互动小组件 (Interactive Widgets)**
  * 小尺寸：宠物表情 + 今日骨气评分。
  * 中尺寸：宠物表情 + 今日统计摘要 + "开始校准"按钮。
  * 使用 `WidgetKit` + `AppIntents` 实现桌面直接触发校准操作。
- [ ] **Task 4.4: iPhone Duo 双屏深度适配**
  * 监测主页在 Regular Width 下自动升级为双栏布局（宠物 + 实时仪表盘 | 病历单 + 设置快捷面板）。
  * 悬停/桌面态（Tabletop Pose）适配：上屏展示宠物，下屏展示操作面板。
  * 折痕区域避让验证与约束修正。
- [ ] **Task 4.5: 兜底降级方案 (No-AirPods Fallback Mode)**
  * 无耳机用户可选：
    * 方案 A：基于 iPhone 前置 Vision 框架人脸倾角识别模式（需 `NSCameraUsageDescription` 权限）。
    * 方案 B：轻量级"护颈番茄钟"模式（定时提醒 + 手动记录）。
- [ ] **Task 4.6: Apple HealthKit 数据打通**
  * 将端正坐姿的专注时长写入 HealthKit 的 `MindfulSession`。
  * 读取用户当日步数等数据作为 AI 诊断的辅助参考。
- [ ] **Task 4.7: 7 种语言国际化与深色模式全覆盖验证**
  * 全部页面在深色/浅色模式下视觉完整性检查，保证卡片层级、分割线与动态语义色渲染正常。
  * 验证 7 种语言（en, zh-Hans, zh-Hant, ja, ko, ar, fr）在 `Localizable.xcstrings` 与 `InfoPlist.xcstrings` 下的完整覆盖（基数语言为英语）。
  * 专项校验阿拉伯语（ar）RTL 从右向左排版、SnapKit leading/trailing 镜像、文本右对齐及方向性图标翻转。
  * VoiceOver 无障碍标签补全与 Dynamic Type 字体缩放适配验证。
- [ ] **Task 4.8: App Store 上架准备**
  * App Store 截图制作（含 iPhone Duo 截图）。
  * 隐私政策与用户协议文案。
  * App Review 审核要点自查清单。

> **✅ Phase 4 验收标准 (Definition of Done)**：
> * 灵动岛/锁屏实时活动在后台监测期间持续更新。
> * 桌面小组件展示正确且支持一键校准交互。
> * iPhone Duo 展开态/外屏态/桌面悬停态均正常展示。
> * 无 AirPods 时可进入降级模式，不影响基础体验。
> * HealthKit 正念时长数据同步至"健康"App。
> * 全部页面在深色与浅色模式下色彩层次清晰，无硬编码颜色。
> * 7 种语言（含 Info.plist 权限描述与应用名称）切换无截断、阿拉伯语 RTL 布局完美镜像。

---

## 3. 核心数据结构与状态机设计

### 3.1 姿态与传感器状态
```swift
/// 当前体态判定状态
enum SUPostureState: String, Codable, Sendable {
    case upright      // 端正挺拔
    case slightSlump  // 轻度前倾
    case severeSlump  // 严重驼背
    case calibrating  // 正在校准中
    case unknown      // 传感器不可用/未佩戴
}

/// AirPods 连接状态
enum SUHeadphoneConnectionState: Sendable {
    case connected         // 已连接且可用
    case disconnected      // 未佩戴/未连接
    case unsupported       // 设备不支持运动传感器
}

/// 单帧姿态读数
struct SUPostureReading: Sendable {
    let timestamp: Date
    let rawPitch: Double       // 原始俯仰角 (弧度)
    let rawRoll: Double        // 原始横滚角 (弧度)
    let relativePitch: Double  // 相对校准基准的偏移角 (角度)
    let relativeRoll: Double   // 相对校准基准的偏移角 (角度)
    let state: SUPostureState
    let extraLoadKg: Double    // 当前角度下的额外颈椎受力 (kg)
}
```

### 3.2 宠物模型与人格
```swift
/// 宠物人格类型
enum SUPetPersona: String, CaseIterable, Codable, Sendable {
    case sarcasticWorker = "toxic_worker" // 毒舌打工人
    case tsundereCat     = "tsundere_cat" // 傲娇猫猫
    case gentleCoach     = "gentle_coach" // 温柔私教
}

/// 宠物档案
struct SUPetProfile: Codable, Sendable {
    var name: String
    var level: Int
    var spineEnergy: Int        // 累计骨气能量币
    var activePersona: SUPetPersona
    var streakDays: Int         // 连续坚持天数
    var totalUprightMinutes: Int // 历史累计挺拔分钟数
}
```

### 3.3 每日监测会话
```swift
/// 每日监测会话记录 (SwiftData 持久化)
@Model
final class SUPostureSession {
    var id: UUID
    var date: Date
    var uprightDuration: TimeInterval      // 挺拔总时长 (秒)
    var slumpDuration: TimeInterval        // 驼背总时长 (秒)
    var longestUprightStreak: TimeInterval  // 最长连续挺拔时长 (秒)
    var violationCount: Int                // 低头犯规总次数
    var totalExtraLoadKg: Double           // 累计额外颈椎负荷 (kg·s)
    var gradeRating: String                // S/A/B/C/D 等级
    var aiDiagnosis: String?               // AI 生成的幽默诊断评语
}
```

### 3.4 AI 上下文传参
```swift
/// AI 提示词生成所需的上下文信息
struct SUPostureContext: Sendable {
    let currentAngle: Double          // 当前低头偏移角度
    let slumpDuration: TimeInterval   // 本次低头持续秒数
    let violationCountToday: Int      // 今日第几次犯规
    let currentTime: Date             // 当前时间
    let persona: SUPetPersona         // 当前人格
    let streakDays: Int               // 连续坚持天数
    let isLateNight: Bool             // 是否深夜加班
    let isWeekend: Bool               // 是否周末
}
```

### 3.5 状态机流转图
```
                     校准完成
    [unknown] ──────────────────► [upright]
                                     │
                      ΔPitch > 15°   │   ΔPitch ≤ 15°
                      持续 > 10s     │   持续 > 5s
                                     ▼
                               [slightSlump]
                                     │
                      ΔPitch > 25°   │   ΔPitch ≤ 15°
                      持续 > 10s     │   持续 > 5s
                                     ▼
                               [severeSlump] ──► 触发 AI 语音提醒
                                     │
                      ΔPitch ≤ 15°   │
                      持续 > 5s      │
                                     ▼
                                [upright] ──► 宠物满血复活动效
```

---

## 4. 开发规范与后续执行准则

1. **增量交付原则**：每个 Task 必须有明确的单测或 UI 预览（SwiftUI Preview），保证每次迭代工程均可正常编译运行。
2. **硬件与离线解耦**：所有涉及 `CMHeadphoneMotionManager` 的逻辑必须面向协议（`SUMotionServiceProtocol`），确保模拟器开发与无 AirPods 场景下可通过 Mock 运行。
3. **隐私与能耗底线**：
   * 姿态数据仅在本地实时计算，严禁上传用户运动裸数据至服务器。
   * 仅 AI 台词生成时向云端发送脱敏的统计摘要（角度、时长、次数），不含任何个人标识。
   * 采用合理的传感器刷新率（10Hz~20Hz 足矣），避免不必要的电池消耗。
4. **代码读取指引**：后续每一次开发会话，AI 助手将：
   * **首先**读取 `TECH_ARCHITECTURE.md`，确认技术规范与编码守则。
   * **然后**读取本文件（`DEVELOPMENT_PLAN.md`），核对当前处于哪一个 Phase 的哪一个 Task。
   * 严格按照 Phase → Task 顺序逐步推进，单个 Task 完成后勾选 `[x]` 并提交。
5. **Phase 间卡点原则**：在一个 Phase 的所有 Task 未全部完成且通过验收标准前，**严禁跳跃到下一个 Phase**。
