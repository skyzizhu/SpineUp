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
> **目标**：赋予宠物独特的人格与"嘴替"属性，让提醒变得好玩且期待。

- [ ] **Task 2.1: 宠物人格配置系统 (SUPetPersonaManager)**
  * 预设三种可切换性格：
    1. **毒舌打工人**（风格：犀利、自嘲、反内卷、扎心）
    2. **傲娇猫猫**（风格：傲娇、猫咪视角、被压扁的委屈）
    3. **温柔私教**（风格：鼓励、正向反馈、深呼吸指导）
  * 用户在"我的"设置页中可随时切换，选择结果持久化。
- [ ] **Task 2.2: AI 服务抽象层 (SUAIServiceProtocol + 双引擎实现)**
  * 定义 `SUAIServiceProtocol`：`func generateReminder(context: SUPostureContext) async throws -> String`。
  * **云端引擎**：`SUCloudAIEngine`——调用 Gemini API / OpenAI API，传入结构化 Prompt（含角色人设、当前角度、时长、当天第几次犯规、时间段）。
  * **离线引擎**：`SUOfflineAIEngine`——内置按人格分类的预制高频语料库（每人格 50+ 条台词），无网络时随机抽取并做简单模板替换。
  * 策略：优先尝试云端，超时 3 秒自动降级至离线。
- [ ] **Task 2.3: 场景化动态 Prompt 构建器 (SUPromptBuilder)**
  * 将动态上下文封装为 `SUPostureContext` 结构体：
    * `currentAngle: Double` / `duration: TimeInterval` / `violationCountToday: Int`
    * `currentTime: Date` / `persona: SUPetPersona` / `streakDays: Int`
  * 构建不同人格的 System Prompt 与 User Prompt 模板。
- [ ] **Task 2.4: 语音与播报集成 (TTS & Audio Ducking)**
  * 支持系统 `AVSpeechSynthesizer` 高质量 TTS，按人格配置不同语速、音调。
  * 智能音量控制：在用户听音乐/播客时不暴力打断，使用 `AVAudioSession` 的 `duckOthers` 选项轻声提醒。
  * 冷却时间机制：同一会话内两次语音提醒间隔 ≥ 3 分钟，避免频繁打扰。
- [ ] **Task 2.5: 骨气能量养成系统 (SUSpineEnergyManager)**
  * 挺拔时间每分钟积累 1 枚"骨气能量币"。
  * 连续多日坚持有额外奖励系数（Streak Bonus）。
  * 能量币可用于解锁宠物装扮/台词包（后期商业化入口）。
  * 数据持久化到本地 SwiftData。

> **✅ Phase 2 验收标准 (Definition of Done)**：
> * 可在设置页切换 3 种宠物人格，切换后提醒台词风格立即变化。
> * 低头超时后，耳机中播放与当前人格匹配的语音提醒，音量不干扰正在播放的音乐。
> * 两次语音提醒间隔不少于 3 分钟。
> * 无网络环境下，离线语料库仍可正常输出提醒文案。
> * 能量币随挺拔时间实时累积，App 重启后数据保留。

---

### Phase 3: MVP v0.3 — 脊椎受力科学模型与社交战报
> **目标**：打造自传播武器，将每一次专注记录沉淀为可分享的社交资产。

- [ ] **Task 3.1: 颈椎承重力学模型 (SUErgonomicsCalculator)**
  * 根据人体工学医学常模：
    * 正常中立位（0°）：颈椎承受约 5 kg
    * 低头 15°：约 12 kg
    * 低头 30°：约 18 kg
    * 低头 45°：约 22 kg
    * 低头 60°：约 27 kg（相当于脖子上挂了一个 8 岁儿童）
  * 趣味换算引擎：将累计额外负荷转换为生活化比喻——"今日颈椎负荷相当于扛了 3.2 块红砖 / 1.5 只柴犬 / 12 杯奶茶"。
  * 换算素材库可配置扩展。
- [ ] **Task 3.2: 每日监测会话数据持久化 (SUPostureSession + SwiftData)**
  * 使用 SwiftData 存储每日会话数据：
    * 会话 ID、日期、挺拔总时长、驼背总时长、最长连续挺拔时长、低头犯规次数、累计额外负荷 (kg)、骨气等级评分。
  * 支持按日/周/月查询历史记录。
- [ ] **Task 3.3: AI 生成《今日骨气病历单》 (SUDailyReportGenerator)**
  * 统计维度：挺拔专注总时长、驼背摸鱼总时长、最长挺拔记录、骨气等级评定（S/A/B/C/D）。
  * AI 总结幽默诊断词："诊断：微积分曲线脊椎。处方：今晚枕头垫低点，明天继续挺直做人。"
  * 展示界面设计为竖屏"病历单"卡片样式。
- [ ] **Task 3.4: 高颜值社交海报渲染与分享 (SUShareCardRenderer)**
  * 基于 SwiftUI 视图构建复古票据/拍立得风格卡片。
  * 使用 `ImageRenderer` 导出高清图片（@3x 分辨率）。
  * 集成系统分享面板 `UIActivityViewController`，一键直达微信/小红书/Instagram。
  * 免费版带轻水印，Pro 版去水印。
- [ ] **Task 3.5: 历史趋势可视化 (SUTrendChartView)**
  * 使用 Swift Charts 绘制近 7 天 / 30 天的挺拔时长趋势折线图与骨气评分趋势。
  * 在"战报"Tab 中展示。

> **✅ Phase 3 验收标准 (Definition of Done)**：
> * 一次完整监测会话结束后，自动生成当日骨气病历单并持久化存储。
> * 病历单中包含准确的脊椎承重换算数据与趣味比喻。
> * 点击"分享"可导出高清卡片，唤起系统分享面板。
> * 战报 Tab 可查看近 7 天历史趋势图。

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
