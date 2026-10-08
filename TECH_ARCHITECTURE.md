# SpineUp: AI Posture Pet — 技术架构与工程研发规范

> **适用范围**：本文件为《SpineUp: AI Posture Pet》项目的技术底层纲领。每次进入开发、新建文件、实现模块或进行代码重构时，**必须首先读取并严格遵循**本规范。  
> **配套文件**：产品需求与分阶段任务清单请参阅 [`DEVELOPMENT_PLAN.md`](./DEVELOPMENT_PLAN.md)。两份文件配合使用，不可分离。

---

## 目录
1. [系统环境与版本基线](#1-系统环境与版本基线)
2. [应用生命周期与窗口入口规范 (SceneDelegate)](#2-应用生命周期与窗口入口规范-scenedelegate)
3. [iPhone Duo 双屏与折叠屏适配规范](#3-iphone-duo-双屏与折叠屏适配规范)
4. [命名与代码前缀规范 (SU 前缀)](#4-命名与代码前缀规范-su-前缀)
5. [整体架构模式 (MVVM + 视图拆分)](#5-整体架构模式-mvvm--视图拆分)
6. [UI 框架分工与混编规范 (UIKit + SwiftUI)](#6-ui-框架分工与混编规范-uikit--swiftui)
7. [UI 布局与 SnapKit 相对约束规范](#7-ui-布局与-snapkit-相对约束规范)
8. [导航与 TabBar 原生控件规范](#8-导航与-tabbar-原生控件规范)
9. [滑动视图与安全区域 (Safe Area) 处理规范](#9-滑动视图与安全区域-safe-area-处理规范)
10. [网络层架构与 Alamofire 封装](#10-网络层架构与-alamofire-封装)
11. [数据持久化层规范 (SwiftData + UserDefaults)](#11-数据持久化层规范-swiftdata--userdefaults)
12. [后台运行与传感器保活策略](#12-后台运行与传感器保活策略)
13. [隐私与系统权限配置清单](#13-隐私与系统权限配置清单)
14. [深色/浅色模式与无障碍适配](#14-深色浅色模式与无障碍适配)
15. [国际化与本地化策略](#15-国际化与本地化策略)
16. [第三方依赖管理与引入策略](#16-第三方依赖管理与引入策略)
17. [补充工程细节与最佳实践](#17-补充工程细节与最佳实践)
18. [全局公共配置与复用规范](#18-全局公共配置与复用规范)

---

## 1. 系统环境与版本基线

* **目标系统版本**：`iOS 26.0+`
* **Xcode 版本**：Xcode 27+（支持 iOS 26 SDK 与 iPhone Duo 模拟器）
* **API 选型准则**：
  * 面向 iOS 26 及最新系统特性，优先选用 Apple 最新推出的现代 API 与系统行为，坚决废弃过期（Deprecated）接口。
  * 每次涉及系统底层（如 CoreMotion、ActivityKit、HealthKit、AVFoundation 等）开发时，需主动检索并使用该系统版本推荐的现代声明与调用方式。
* **语言标准**：Swift 6 模式，全面启用严格并发检查（Strict Concurrency Checking），采用现代 `async/await`、`Actor` 及 `@MainActor`。

---

## 2. 应用生命周期与窗口入口规范 (SceneDelegate)

根据现代 iOS 多窗口体系架构：
1. **UI 窗口唯一入口：`SUSceneDelegate`**
   * **严禁** 在 `AppDelegate.swift` 中初始化 `UIWindow` 或设置 `rootViewController`。
   * `SUAppDelegate.swift` 仅负责应用级进程生命周期（如第三方 SDK 初始化、APNs 推送注册、全局日志初始化、后台守护任务声明）。
   * `SUSceneDelegate.swift` 中的 `scene(_:willConnectTo:options:)` 是创建 `UIWindow`、绑定 `windowScene`、设置根视图控制器 `SUMainTabBarController` 并调用 `makeKeyAndVisible()` 的**唯一入口**。
   ```swift
   // SUSceneDelegate.swift 示例规范
   class SUSceneDelegate: UIResponder, UIWindowSceneDelegate {
       var window: UIWindow?

       func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                  options connectionOptions: UIScene.ConnectionOptions) {
           guard let windowScene = (scene as? UIWindowScene) else { return }
           let window = UIWindow(windowScene: windowScene)
           let mainTabBarController = SUMainTabBarController()
           window.rootViewController = mainTabBarController
           self.window = window
           window.makeKeyAndVisible()
       }
   }
   ```
2. **Info.plist 场景配置**：
   * 在 `Info.plist` 中必须配置 `UIApplicationSceneManifest`，声明 `SUSceneDelegate` 为默认场景代理类名。
   * **保留** `LaunchScreen.storyboard` 作为应用启动屏（Splash Screen），这是 Apple 要求的启动页机制，不得删除。
   * **删除** `UIMainStoryboardFile` 与 `UISceneStoryboardFile` 中对 `Main.storyboard` 的引用——应用的页面导航与根控制器由 `SUSceneDelegate` 代码加载，不通过 Main.storyboard 入口。
3. **多场景与状态连续性支持**：
   * 在用户展开/折叠双屏、或者分屏切换时，`SceneDelegate` 需妥善处理场景前后台状态转移（`sceneDidBecomeActive`、`sceneWillResignActive`），确保传感器状态平滑过渡。

---

## 3. iPhone Duo 双屏与折叠屏适配规范

本应用全面兼容并优化 **iPhone Duo** 硬件设备。每次进行 UI 布局与页面开发时，**必须参考 Apple 官方人机界面指南**：  
🔗 [Apple Human Interface Guidelines: Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)  
🔗 [Apple Developer: Get Ready for iPhone Duo](https://developer.apple.com/iphone-duo/)

### 3.1 核心设计原则
1. **尺寸类别自适应 (Adaptive Size Classes)**：
   * **外屏态 (Outer Display)**：通常为 `Compact Width`。页面呈现单列流式结构（Single Column），聚焦核心快速操作（当前体态、一键校准、快速挂起）。
   * **内屏展开态 (Inner Unfolded Display)**：通常呈现为 `Regular Width`。界面自动升级为**双栏/主次分屏响应式布局 (Dual-Pane Split Layout)**：
     * **主屏区 (Primary Pane)**：左侧展示 SwiftUI 宠物元气动态、实时坐姿偏角仪表盘；
     * **副屏区 (Secondary Pane)**：右侧展示今日骨气病历单、脊椎承重历史趋势分析、AI 幽默评语面板。
2. **设备形态/姿态感知 (Device Poses)**：
   * **平展态 (Flat / Open)**：全屏完整展开，双栏信息协同展示。
   * **悬停/桌面态 (Tabletop / Half-Folded Pose)**：设备像笔记本一样折角放在桌面上：
     * 上半部屏幕充当"桌面立宠与仪表盘"，面向视线；
     * 下半部平放屏幕展示操作面板（校准按钮、灵敏度滑块、人设切换）。
   * **折叠闭合态 (Folded / Outer Display)**：单手快速浏览。
3. **折痕/中缝避让 (Hinge & Crease Avoidance)**：
   * 严禁将关键操作按钮、文字输入框、或宠物核心面部焦点跨越在物理中缝（Hinge）正中间。
   * 使用 SnapKit 相对约束时，充分利用分隔参照物或 safeArea，使内容自然分布于两侧有效显示区域。
4. **无缝连续性 (Continuity)**：
   * 用户在合上或展开 iPhone Duo 屏幕瞬间，App 通过 `viewWillTransition(to:with:)` 接收尺寸变更通知并自适应重算约束，**严禁发生状态重置或中断正在进行的体态监测会话**。

### 3.2 布局适配技术实现
```swift
// 在 SUBaseViewController 中统一提供尺寸变化钩子
override func viewWillTransition(to size: CGSize,
                                  with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { [weak self] _ in
        self?.adaptLayoutForSize(size)
    })
}

/// 子类重写此方法以响应 Compact / Regular 宽度切换
func adaptLayoutForSize(_ size: CGSize) {
    // 子类实现：根据 traitCollection.horizontalSizeClass 切换布局
}
```

---

## 4. 命名与代码前缀规范 (SU 前缀)

为保持工程模块清晰，所有自定义业务类、结构体、枚举、协议以及对应源码文件名，统一以 **`SU`**（代表 **S**pine**U**p）作为前缀：

### 4.1 文件与类命名示例
| 类型 | 命名模式 | 实际示例 |
| :--- | :--- | :--- |
| **应用生命周期** | `SU<名称>.swift` | `SUSceneDelegate.swift`, `SUAppDelegate.swift` |
| **控制器** | `SU<功能>ViewController.swift` | `SUPostureMonitorViewController.swift` |
| **视图模型** | `SU<功能>ViewModel.swift` | `SUPostureMonitorViewModel.swift` |
| **自定义视图** | `SU<功能>View.swift` | `SUPetVisualView.swift`, `SUCalibrationGuideView.swift` |
| **服务/管理器** | `SU<功能>Manager.swift` / `Service` | `SUHeadphoneMotionManager.swift`, `SUNetworkManager.swift` |
| **协议** | `SU<功能>Protocol.swift` | `SUMotionServiceProtocol.swift`, `SUAIServiceProtocol.swift` |
| **模型/实体** | `SU<名称>Model.swift` / 枚举 | `SUPostureState.swift`, `SUPetProfileModel.swift` |
| **自定义 Cell** | `SU<功能>Cell.swift` | `SUDailyReportHistoryCell.swift` |
| **Extension** | `<系统类型>+SU<功能>.swift` | `UIColor+SUTheme.swift`, `Date+SUFormatting.swift` |
| **常量** | `SU<类别>Constants.swift` | `SULayoutConstants.swift`, `SUMotionConstants.swift` |

### 4.2 命名注意事项
* **禁止**使用无前缀的泛型命名（如 `MotionManager`、`NetworkService`、`BaseVC`）。
* **SwiftUI 视图**同样遵循 SU 前缀（如 `SUPetAnimatedView`）。
* **SwiftData Model**同样遵循 SU 前缀（如 `SUPostureSession`）。

---

## 5. 整体架构模式 (MVVM + 视图拆分)

工程严格采用 **MVVM (Model-View-ViewModel)** 架构，严禁出现将业务、网络、复杂布局全部揉杂在 Controller 中的"庞大控制器（Massive ViewController）"。

```
  ┌──────────────────────────────────────────────────────────────┐
  │                 SU***ViewController (调度与生命周期)            │
  └──────────────┬───────────────────────────────┬───────────────┘
                 │ 1. 挂载并布局                  │ 2. 数据与事件双向绑定
                 ▼                               ▼
  ┌──────────────────────────────┐ ┌─────────────────────────────┐
  │   SU***View (独立封装视图)     │ │   SU***ViewModel (业务状态)  │
  │ - 负责自身子视图初始化与布局   │ │ - 纯业务逻辑与状态机处理    │
  │ - 暴露简洁的渲染接口或事件回调 │ │ - 统一派发 State / Output    │
  └──────────────────────────────┘ └──────────────┬──────────────┘
                                                  │ 3. 数据请求与设备感知
                                                  ▼
                                   ┌─────────────────────────────┐
                                   │  Service 层 (Network / Core) │
                                   └─────────────────────────────┘
```

### 5.1 Controller 职责界定
* 仅负责：页面生命周期、依赖注入、ViewModel 数据绑定、导航路由跳转、多尺寸/折叠屏形态适配回调。
* **原则**：Controller 内代码行数尽量控制在 250 行以内，不直接编写数十行的控件创建与约束代码。

### 5.2 复杂视图独立封装原则
* 凡是包含 2 个以上子控件或具备独立视觉逻辑的模块（如：宠物展示面板、坐姿角度表盘、今日承重卡片），**必须**继承自 `UIView` 单独建立 `SU***View.swift`。
* `SU***View` 内部自闭环处理自身的 SnapKit 布局；对外仅暴露配置接口与回调：
  ```swift
  // 配置数据渲染接口
  func configure(with state: SUPostureViewState)
  // 事件向上传递闭包
  var onCalibrationButtonTapped: (() -> Void)?
  ```

### 5.3 ViewModel 规范
* 纯业务逻辑与状态管理，**禁止引入 UIKit 视图对象**（不允许 `import UIKit`，仅允许 `import Foundation`）。
* 状态输出采用 Swift Concurrency (`AsyncStream` / `@MainActor @Observable`) 或 `Combine`，与 Controller 解耦。
* ViewModel 内部可持有 Service / Manager 引用，但通过协议抽象注入，便于单元测试。

### 5.4 SUBaseViewController 基类职责
所有业务 Controller 必须继承自 `SUBaseViewController`，基类提供：
```swift
class SUBaseViewController: UIViewController {
    // MARK: - 生命周期日志
    // 自动在 viewDidLoad / viewWillAppear / deinit 中输出 os.Logger 日志

    // MARK: - 深色/浅色模式响应
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearanceForCurrentTheme()
        }
    }
    /// 子类重写以响应外观变化
    func updateAppearanceForCurrentTheme() {}

    // MARK: - iPhone Duo 尺寸适配钩子
    override func viewWillTransition(to size: CGSize,
                                      with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.adaptLayoutForSize(size)
        })
    }
    /// 子类重写以响应 Compact/Regular 宽度切换
    func adaptLayoutForSize(_ size: CGSize) {}
}
```

---

## 6. UI 框架分工与混编规范 (UIKit + SwiftUI)

系统采用 **UIKit 主干 + 局部 SwiftUI 赋能** 的工程策略：

### 6.1 UIKit 适用场景（主干框架）
* 应用整体框架：`SUMainTabBarController`、`SUBaseNavigationController`。
* 页面骨架：所有基础 Controller、常规滑动列表、设置表单页。
* 理由：生命周期控制更稳健，系统导航栏与手势交互更细腻成熟，多窗口与分屏容器调度灵活。

### 6.2 SwiftUI 适用场景（创意与生态组件）
* **宠物形象与动态视觉**：利用 SwiftUI 丰富的状态驱动动画编写 `SUPetAnimatedView`，并通过 `UIHostingController` 嵌入 UIKit 视图中：
  ```swift
  let petView = SUPetAnimatedView(petState: currentState)
  let hostingController = UIHostingController(rootView: petView)
  addChild(hostingController)
  containerView.addSubview(hostingController.view)
  hostingController.view.snp.makeConstraints { make in
      make.edges.equalToSuperview()
  }
  hostingController.didMove(toParent: self)
  ```
* **灵动岛与锁屏实时活动**：使用 `ActivityKit` + 纯 SwiftUI 编写。
* **桌面小组件**：使用 `WidgetKit` + 纯 SwiftUI 编写。
* **社交分享卡片渲染**：使用 SwiftUI `ImageRenderer` 导出高清图片。

### 6.3 混编桥接规范
* UIKit 中嵌入 SwiftUI：统一使用 `UIHostingController`，SnapKit 约束其 `view`。
* SwiftUI 中嵌入 UIKit（如有需要）：使用 `UIViewRepresentable` / `UIViewControllerRepresentable`。
* 数据流方向：UIKit Controller → ViewModel 状态变化 → 传递给 SwiftUI 的 `@ObservedObject` / `@Binding`。

---

## 7. UI 布局与 SnapKit 相对约束规范

* **依赖工具**：全面使用 `SnapKit`。
* **布局核心原则**：
  1. **严禁写死绝对坐标**：禁止在业务代码中出现 `CGRect(x: 10, y: 100, width: 300, height: 50)` 等绝对计算，所有视图均使用 `make.xxx` 约束。
  2. **严禁硬编码屏幕宽高**：禁止使用 `UIScreen.main.bounds.width` 进行等比计算。控件宽度应相对于父容器按比例或固定边距约束。
  3. **相对约束与安全区绑定**：
     * 顶部/底部边界必须相对于 `view.safeAreaLayoutGuide`：
       ```swift
       headerView.snp.makeConstraints { make in
           make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
           make.leading.trailing.equalToSuperview()
           make.height.equalTo(120)
       }
       ```
     * 控件之间使用链式相对依赖关系，确保在所有屏幕尺寸（包括不同尺寸的 iPhone、Pro Max 与 iPhone Duo 折叠态/展开态）自适应撑开或压缩。
  4. **视图初始化规范**：统一在视图的 `init` 中调用：
     * `setupSubviews()`：添加子视图层级；
     * `setupConstraints()`：编写 SnapKit 约束；
     * `setupBindings()`：绑定手势或事件。
  5. **间距与尺寸常量化**：
     * 常用间距与尺寸统一定义在 `SULayoutConstants` 中：
       ```swift
       enum SULayoutConstants {
           static let horizontalPadding: CGFloat = 16
           static let verticalSpacing: CGFloat = 12
           static let cornerRadius: CGFloat = 12
           static let petContainerHeight: CGFloat = 280
       }
       ```
  6. **视觉设计调性与交互原则**：
     * **清新、简约、大气**：页面留白适度，信息层次分明，卡片式采用微阴影与高斯模糊（`UIBlurEffect` / `.ultraThinMaterial`），杜绝繁复堆砌；
     * **操作与交互简洁流畅**：所有交互均配合轻微触觉反馈（Haptics）与弹性过渡（Spring Animations），避免冗余弹窗与复杂层级；
     * **图标规范**：**整个 UI 内部所有图标一律统一使用苹果原生 SF Symbols**（`UIImage(systemName: "...")` / `Image(systemName: "...")`），严禁使用未经统一的自定义位图。

---

## 8. 导航与 TabBar 原生控件规范

为了保证系统级流畅体验与无缝的原生手势支持：

1. **统一使用系统原生容器**：
   * 标签栏：使用系统的 `UITabBarController`（`SUMainTabBarController`）。
   * 导航栏：使用系统的 `UINavigationController`（`SUBaseNavigationController`）。
2. **严禁自定义导航栏与 TabBar 视图**：
   * 不要使用隐藏系统导航栏并在页面上方贴自定义 `UIView` 作为假导航栏的反模式。
   * 样式定制统一通过现代 `UINavigationBarAppearance` 与 `UITabBarAppearance` 全局或单页配置：
     ```swift
     let appearance = UINavigationBarAppearance()
     appearance.configureWithDefaultBackground()
     navigationController?.navigationBar.standardAppearance = appearance
     navigationController?.navigationBar.scrollEdgeAppearance = appearance
     ```
3. **按钮与图标**：
   * 优先使用系统 SF Symbols（如 `UIImage(systemName: "figure.walk")`），保证在深色/浅色模式与不同系统版本上的视觉一致性。
   * Tab 图标规范：使用 SF Symbols 的 filled 与 regular 变体分别对应选中/未选中状态。

---

## 9. 滑动视图与安全区域 (Safe Area) 处理规范

对于 `UIScrollView`、`UITableView`、`UICollectionView`、`UITextView` 等可滑动视图：

1. **从 0 延伸，全屏铺满**：
   * 滑动视图的外层约束直接占满父容器边缘（`make.edges.equalToSuperview()`），**让视图自然贯穿顶部刘海/灵动岛及底部 Home Bar**。
2. **由系统自动管理内边距**：
   * 严禁在代码中强行手写写死固定边距（如 `contentInset = UIEdgeInsets(top: 44, ...)`）。
   * 统一依赖系统机制：
     ```swift
     scrollView.contentInsetAdjustmentBehavior = .automatic
     ```
   * 列表内容区由系统自动在安全区边缘启停，保证用户滑动时具有原生的穿透沉浸感与滚动到底部的完整露出。
3. **键盘避让**：
   * 涉及文本输入的滑动视图，需监听键盘通知 (`UIResponder.keyboardWillShowNotification`) 并动态调整 `contentInset.bottom`，或使用 iOS 15+ 的 `keyboardLayoutGuide`。

---

## 10. 网络层架构与 Alamofire 封装

### 10.1 选型与职责
* 引入 **Alamofire** 作为底层网络引擎。
* 统一由单例 `SUNetworkManager` 对外提供统一的异步接口。

### 10.2 封装规范
1. **全面采用 Swift Concurrency (`async/await`)**：
   * 禁止在业务层直接调用散落的 `AF.request`。
   * 定义 `SUAPIEndpoint` 协议与路由枚举，包含 `baseURL`、`path`、`method`、`headers`、`parameters`、`encoding`。
   * 统一管理请求拦截、鉴权 Token 注入与重试策略。
   ```swift
   final class SUNetworkManager: @unchecked Sendable {
       static let shared = SUNetworkManager()
       private let session: Session

       func request<T: Decodable>(_ endpoint: SUAPIEndpoint,
                                   responseType: T.Type) async throws -> T {
           // 统一超时(15s)、拦截器、错误码转换与 JSON 解析
       }
   }
   ```
2. **错误模型统一**：
   * 封装 `SUNetworkError` 枚举：
     ```swift
     enum SUNetworkError: Error, LocalizedError {
         case noConnection          // 无网络连接
         case serverError(Int)      // 服务端状态码异常
         case decodingFailed        // 数据解析失败
         case timeout               // 请求超时
         case aiGenerationFailed    // AI 内容生成失败
         case unknown(Error)        // 未知错误
     }
     ```
   * ViewModel 中统一将 `SUNetworkError` 映射为用户友好的提示文案。

### 10.3 网络状态监测
* 使用 Alamofire 内置的 `NetworkReachabilityManager` 监测网络连通性。
* AI 引擎根据网络状态自动切换云端/离线策略。

---

## 11. 数据持久化层规范 (SwiftData + UserDefaults)

### 11.1 SwiftData 适用场景
* **结构化业务数据**：每日体态会话记录（`SUPostureSession`）、宠物档案（`SUPetProfile`）、历史趋势数据。
* 使用 `@Model` 宏声明实体，统一在 `Persistence/` 目录下管理。
* `ModelContainer` 在 `SUSceneDelegate` 中初始化并注入。

### 11.2 UserDefaults 适用场景
* **轻量级偏好配置**：
  * 是否已完成 Onboarding（`hasCompletedOnboarding: Bool`）
  * 校准基准值（`calibrationBasePitch: Double` / `calibrationBaseRoll: Double`）
  * 当前选中的宠物人格（`activePetPersona: String`）
  * 用户偏好阈值设置（`slightSlumpThreshold: Double` / `severeSlumpThreshold: Double`）
* 统一通过 `SUUserDefaultsManager` 或 `@AppStorage` 属性包装器访问，禁止在业务代码中散落裸调用 `UserDefaults.standard.set/get`。

### 11.3 数据安全
* 敏感配置（如 AI API Key，若有）使用 Keychain 存储，**禁止**存入 UserDefaults 或硬编码在源码中。

---

## 12. 后台运行与传感器保活策略

### 12.1 后台音频保活
* 在 `Info.plist` 的 `UIBackgroundModes` 中声明 `audio` 模式。
* App 进入后台后，通过维持一个静音音频会话（`AVAudioSession`），保持 `CMHeadphoneMotionManager` 传感器监听不中断。
* 用户主动点击"暂停监测"时释放音频会话，避免不必要的电池消耗。

### 12.2 传感器生命周期管理
```
App 前台 + 监测中 → 传感器 Active（正常采样 10-20Hz）
App 进入后台     → 传感器 Active（后台音频保活）
App 被系统挂起   → 传感器 Stopped（graceful 停止，保存当前会话快照）
用户取下耳机     → 传感器 Stopped（UI 更新为"未连接"状态）
用户戴上耳机     → 传感器 Resume（自动恢复监听，无需重新校准）
```

### 12.3 电量优化
* 传感器采样率控制在 10Hz~20Hz，禁止使用 60Hz 或更高频率。
* 当连续 5 分钟判定为稳定 `upright` 状态时，可降频至 5Hz 节能模式。
* App 通过 `ProcessInfo.processInfo.isLowPowerModeEnabled` 检测低电量模式，自动降频并减少动画。

---

## 13. 隐私与系统权限配置清单

### 13.1 Info.plist 完整权限声明
| 权限 Key | 说明 | 使用阶段 |
| :--- | :--- | :--- |
| `NSMotionUsageDescription` | "SpineUp 需要访问运动传感器以通过 AirPods 监测您的头部姿态" | Phase 0+ |
| `UIBackgroundModes: audio` | 后台音频保活以维持传感器监听 | Phase 0+ |
| `NSHealthShareUsageDescription` | "SpineUp 希望读取您的健康数据以提供更精准的体态分析" | Phase 4 |
| `NSHealthUpdateUsageDescription` | "SpineUp 希望将您的挺拔专注时长记录为正念时间" | Phase 4 |
| `NSCameraUsageDescription` | "SpineUp 需要访问摄像头以在无耳机时通过面部朝向检测体态"（降级模式） | Phase 4 |

### 13.2 权限申请时机
* **延迟申请原则**：不在 App 启动时弹出所有权限请求。在用户首次触达对应功能时，先展示自定义的预申请说明页（解释为什么需要此权限），再触发系统弹窗。
* 运动传感器权限在 Onboarding 引导流第 2 页申请。

### 13.3 数据处理原则
* 姿态数据（角度、时长等）仅在本地实时计算与存储，**严禁上传用户运动裸数据**。
* AI 台词生成时仅向云端发送脱敏的统计摘要（角度数值、时长、犯规次数），不含设备标识、地理位置或个人信息。

---

## 14. 深色模式与无障碍深度规范

### 14.1 深色模式 (Dark Mode) 全覆盖设计规范
App 全面支持 **浅色模式 (Light Mode)** 与 **深色模式 (Dark Mode)** 的无缝平滑切换，提供极致沉浸的人体工学视觉体验。

1. **动态语义化颜色体系 (Semantic Colors)**：
   * **背景层级 (Background Elevation)**：
     * 主画布背景：`UIColor.systemBackground`（浅色纯白，深色纯黑 `#000000`）；
     * 卡片/容器背景：`UIColor.secondarySystemBackground`（浅色淡灰 `#F2F2F7`，深色层级深灰 `#1C1C1E`）；
     * 浮层/弹窗背景：`UIColor.tertiarySystemBackground`（深色微亮深灰 `#2C2C2E`）。
   * **文字与前景色 (Text & Foreground)**：
     * 主要文字：`UIColor.label`；
     * 次要说明：`UIColor.secondaryLabel`；
     * 辅助占位：`UIColor.tertiaryLabel`；
     * 分割线：`UIColor.separator`。
   * **自定义品牌与强调色**：
     * 必须在 `Assets.xcassets` 中以 Color Set 定义（同时提供 Any Appearance 与 Dark Appearance），或在代码中通过动态提供者声明：
       ```swift
       static let suPrimaryAccent = UIColor { traitCollection in
           traitCollection.userInterfaceStyle == .dark
               ? UIColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 1.0)
               : UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1.0)
       }
       ```
     * **严禁** 在业务代码中硬编码无外观感知的绝对 RGB/十六进制色彩。
2. **深色模式卡片层级与阴影质感**：
   * 深色模式下放弃大面积浓黑投影，改为通过**明度层级提升 + 细腻描边**营造立体感：
     ```swift
     cardView.layer.borderColor = UIColor.separator.cgColor
     cardView.layer.borderWidth = 0.5
     ```
3. **SwiftUI 视图双模式适配**：
   * SwiftUI 动态组件（如宠物动画、小组件）使用 `@Environment(\.colorScheme) private var colorScheme` 自适应。
   * 必须在 Preview 中同时提供浅色与深色预览：
     ```swift
     #Preview("Light Mode") {
         SUPetAnimatedView(petState: .upright).preferredColorScheme(.light)
     }
     #Preview("Dark Mode") {
         SUPetAnimatedView(petState: .upright).preferredColorScheme(.dark)
     }
     ```
4. **生命周期与外观切换监听**：
   * `SUBaseViewController` 在 `traitCollectionDidChange` 中自动检测 `hasDifferentColorAppearance`，触发 `updateAppearanceForCurrentTheme()`，确保 CGColor（如 `layer.borderColor`）即时刷新。

### 14.2 无障碍 (Accessibility)
1. **VoiceOver 标签**：所有可交互控件必须设置 `accessibilityLabel`、`accessibilityValue` 与 `accessibilityHint`。
2. **Dynamic Type**：文字控件统一使用 `UIFont.preferredFont(forTextStyle:)` 或对应 SwiftUI 字体修饰器，全面支持系统字体缩放。
3. **最小触摸区域**：所有可点击区域不小于 44×44 pt（`SULayoutConstants.minimumTouchTargetSize`）。

---

## 15. 全方位国际化与本地化策略 (7国语言 + Info.plist + RTL 适配)

本应用为全球化定位，基准开发语言（Base Language）为**英语**，全面适配 7 种主流语言。

### 15.1 语言矩阵与代码映射
| 序号 | 语言名称 | Locale 代码 | 布局方向 | 备注 |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **英语 (English)** | `en` | LTR (左到右) | **基准开发语言 (Base / Development)** |
| **2** | **简体中文** | `zh-Hans` | LTR (左到右) | 核心主力市场 |
| **3** | **繁体中文** | `zh-Hant` | LTR (左到右) | 港澳台及海外华人市场 |
| **4** | **日语 (Japanese)** | `ja` | LTR (左到右) | 亚洲重点市场 |
| **5** | **韩语 (Korean)** | `ko` | LTR (左到右) | 亚洲重点市场 |
| **6** | **阿拉伯语 (Arabic)** | `ar` | **RTL (从右往左)** | 中东市场，需专属镜像与对齐适配 |
| **7** | **法语 (French)** | `fr` | LTR (左到右) | 欧洲主力市场 |

### 15.2 Info.plist 系统级多语言本地化 (`InfoPlist.xcstrings` / `InfoPlist.strings`)
* **应用桌面名称 (`CFBundleDisplayName`)**：**不进行多语言本地化，全局统一显示为 `SpineUp`**。
* **系统权限描述**：必须在 7 种语言下完整提供本地化，杜绝在非英语系统下弹出未经翻译的权限弹窗：

| 字段 Key | 英语 (`en`) | 简体中文 (`zh-Hans`) | 繁体中文 (`zh-Hant`) | 日语 (`ja`) | 韩语 (`ko`) | 阿拉伯语 (`ar`) | 法语 (`fr`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `CFBundleDisplayName` | **SpineUp** | **SpineUp** | **SpineUp** | **SpineUp** | **SpineUp** | **SpineUp** | **SpineUp** |
| `NSMotionUsageDescription` | SpineUp needs motion sensor access to monitor your posture via AirPods. | SpineUp 需要访问运动传感器以通过 AirPods 监测您的头部姿态。 | SpineUp 需要存取運動感測器以透過 AirPods 監測您的頭部姿態。 | SpineUpはAirPodsを通じて姿勢を監視するためにモーションセンサーにアクセスする必要があります。 | SpineUp은 AirPods를 통해 자세를 모니터링하기 위해 모션 센서 접근이 필요합니다. | يحتاج SpineUp للوصول إلى مستشعرات الحركة لمراقبة وضعيتك عبر AirPods. | SpineUp a besoin d'accéder aux capteurs de mouvement pour surveiller votre posture via les AirPods. |
| `NSHealthShareUsageDescription` | SpineUp needs to read health data to provide accurate posture analytics. | SpineUp 希望读取您的健康数据以提供更精准的体态分析。 | SpineUp 希望讀取您的健康資料以提供更精準的體態分析。 | SpineUpはより正確な姿勢分析を提供するためにヘルスケアデータを読み取る必要があります。 | SpineUp은 정확한 자세 분석을 제공하기 위해 건강 데이터를 읽어야 합니다. | يحتاج SpineUp لقراءة البيانات الصحية لتقديم تحليلات دقيقة للوضعية. | SpineUp a besoin de lire les données de santé pour fournir des analyses posturales précises. |
| `NSHealthUpdateUsageDescription` | SpineUp records your upright focus time as mindful minutes. | SpineUp 希望将您的挺拔专注时长记录为正念时间。 | SpineUp 希望將您的挺拔專注時長記錄為正念時間。 | SpineUpは背筋を伸ばした集中時間をマインドフル時間として記録します。 | SpineUp은 바른 자세 집중 시간을 마음 챙김 시간으로 기록합니다. | يسجل SpineUp وقت تركيزك في الوضعية المستقيمة كدقائق يقظة. | SpineUp enregistre votre temps de posture droite sous forme de minutes de pleine conscience. |

### 15.3 页面与业务文本本地化 (`Localizable.xcstrings`)
* 全面使用现代 **String Catalogs (`Localizable.xcstrings`)** 集中管理。
* 业务代码中使用 `String(localized: "key", defaultValue: "Fallback Text")`：
  ```swift
  let calibrateTitle = String(localized: "monitor.button.calibrate", defaultValue: "Calibrate Posture")
  ```
* **纪律**：**严禁** 在代码中硬编码用户可见的自然语言字符串。

### 15.4 阿拉伯语 RTL (Right-to-Left) 专门布局准则
阿拉伯语使用从右向左的书写与阅读习惯，必须严格遵循以下规则：
1. **SnapKit 约束方向规则**：
   * 必须严格使用 `make.leading` / `make.trailing`；
   * **绝对禁止** 使用 `make.left` / `make.right`（在 RTL 下 left/right 不会自适应翻转，导致布局错乱）。
2. **文本对齐规则**：
   * `UILabel.textAlignment` 默认使用 `.natural`（LTR 下靠左，RTL 下自动对齐到右侧）。
3. **方向性图标自动镜像**：
   * 带有方向隐喻的图标（如前进箭头、返回键、展开折叠指示），必须启用 `.imageFlippedForRightToLeftLayoutDirection()`。
4. **进度条与仪表盘流向**：
   * 水平进度条在 RTL 环境下由右向左增长。

### 15.5 AI 动态台词多语言生成与离线库
* **云端 AI 生成**：动态 Prompt 构建器在请求体中自动附带用户当前系统 Locale（`Locale.current.identifier`），并在 System Prompt 中严格指定输出语言。
* **离线备用语料库**：针对 3 大宠物人格（毒舌打工人、傲娇猫猫、温柔私教），离线预制台词表完整提供 7 种语言的高频对照语料。

---

## 16. 第三方依赖管理与引入策略

* **首选管理工具**：**Apple Swift Package Manager (SPM)**（Xcode 原生支持，易维护，无侵入性）。
* **备选方案**：若由于特定混编配置需要，亦可通过 `CocoaPods` 管理。
* **已确定依赖清单**：

| 依赖 | 用途 | 版本策略 |
| :--- | :--- | :--- |
| `Alamofire` | 网络请求 | 最新稳定版 (Up to Next Major) |
| `SnapKit` | 自动布局 | 最新稳定版 (Up to Next Major) |

* **新增依赖审批原则**：引入任何新的第三方库之前，须评估：
  1. 是否有系统原生 API 可替代？（优先使用系统能力）
  2. 库的维护活跃度与 Swift 6 / iOS 26 兼容性？
  3. 包体积影响与依赖链复杂度？

---

## 17. 补充工程细节与最佳实践

### 17.1 内存管理与闭包捕获
* 在 Controller、ViewModel 以及长时间存活的观察者内部，所有闭包传参必须严格遵循 `[weak self]` 捕获列表，并在使用时做安全展开：
  ```swift
  viewModel.onStateChanged = { [weak self] newState in
      guard let self else { return }
      self.updateUI(with: newState)
  }
  ```
* Timer、NotificationCenter 观察者在 `deinit` 中必须显式移除/失效。

### 17.2 结构化目录体系设计
工程目录将按照清晰的模块职责分层归纳：
```text
anyway/ (项目主目录)
├── App/
│   ├── SUAppDelegate.swift          // 应用进程生命周期（SDK初始化、推送注册）
│   └── SUSceneDelegate.swift        // UI 窗口生命周期唯一入口
├── Base/
│   ├── SUBaseViewController.swift   // 基类 VC（日志、主题响应、Duo适配钩子）
│   ├── SUBaseNavigationController.swift
│   └── SUBaseTabBarController.swift
├── Constants/
│   ├── SULayoutConstants.swift      // 布局间距与尺寸常量
│   ├── SUMotionConstants.swift      // 传感器阈值与采样率常量
│   └── SUAppConstants.swift         // 应用全局配置常量
├── Core/
│   ├── Motion/                      // AirPods CoreMotion 传感器层
│   │   ├── SUMotionServiceProtocol.swift
│   │   ├── SUHeadphoneMotionManager.swift
│   │   ├── SUMockMotionManager.swift
│   │   ├── SUPostureStateEngine.swift
│   │   └── SUCalibrationService.swift
│   ├── AI/                          // AI 提示词与大模型桥接层
│   │   ├── SUAIServiceProtocol.swift
│   │   ├── SUCloudAIEngine.swift
│   │   ├── SUOfflineAIEngine.swift
│   │   ├── SUPromptBuilder.swift
│   │   └── SUPersonaPrompts.swift
│   └── Audio/                       // 音效与语音合成
│       └── SUAudioFeedbackManager.swift
├── Network/
│   ├── SUNetworkManager.swift
│   ├── SUAPIEndpoint.swift
│   └── SUNetworkError.swift
├── Persistence/                     // 数据持久化层
│   ├── SUModelContainer.swift       // SwiftData 容器配置
│   ├── SUUserDefaultsManager.swift  // UserDefaults 统一封装
│   └── Models/
│       ├── SUPostureSession.swift   // 每日监测会话 @Model
│       └── SUPetProfile.swift       // 宠物档案 @Model
├── Features/                        // 各大业务功能模块 (MVVM)
│   ├── Onboarding/                  // 首次启动引导流
│   │   └── SUOnboardingViewController.swift
│   ├── PostureMonitor/              // 核心姿态监测与桌宠主页
│   │   ├── SUPostureMonitorViewController.swift
│   │   ├── SUPostureMonitorViewModel.swift
│   │   └── Views/
│   │       ├── SUPetVisualContainerView.swift
│   │       ├── SUPostureGaugeView.swift
│   │       └── SUCalibrationGuideView.swift
│   ├── DailyReport/                 // 今日骨气病历单与战报
│   │   ├── SUDailyReportViewController.swift
│   │   ├── SUDailyReportViewModel.swift
│   │   └── Views/
│   │       ├── SUDailyReportCardView.swift
│   │       ├── SUTrendChartView.swift
│   │       └── SUShareCardRenderer.swift
│   └── Settings/                    // 人设切换与校准设置
│       ├── SUSettingsViewController.swift
│       ├── SUSettingsViewModel.swift
│       └── Views/
│           └── SUPersonaSwitchCell.swift
├── UIComponents/                    // 全局可复用组件与 SwiftUI 桥接
│   ├── PetAnimation/                // SwiftUI 宠物微动效
│   │   └── SUPetAnimatedView.swift
│   └── Common/
│       ├── SUPrimaryButton.swift
│       └── SUEmptyStateView.swift
├── Extensions/                      // 系统类型扩展
│   ├── UIColor+SUTheme.swift
│   ├── Date+SUFormatting.swift
│   ├── Double+SUAngle.swift         // 弧度/角度转换工具
│   └── UIView+SUSnapshot.swift      // 截图导出工具
├── Utilities/                       // 工具类
│   └── SULogger.swift               // 统一结构化日志
└── Resources/
    ├── Assets.xcassets              // 图片、颜色、App Icon
    ├── Info.plist
    ├── Localizable.xcstrings        // 国际化字符串
    └── SoundEffects/                // 提示音音效文件
        ├── water_drop.caf
        └── gentle_chime.caf
```

### 17.3 统一结构化日志 (Structured Logging)
* 放弃裸用 `print()`，统一使用系统现代的 `os.Logger`：
  ```swift
  import os

  enum SULogger {
      private static let subsystem = Bundle.main.bundleIdentifier ?? "com.spineup.app"
      static let motion  = Logger(subsystem: subsystem, category: "Motion")
      static let network = Logger(subsystem: subsystem, category: "Network")
      static let ai      = Logger(subsystem: subsystem, category: "AI")
      static let ui      = Logger(subsystem: subsystem, category: "UI")
      static let data    = Logger(subsystem: subsystem, category: "Data")
  }
  ```

### 17.4 传感器 Mock 与离线调试支持
* 由于 AirPods 姿态传感器强依赖真机佩戴，在 `Core/Motion` 中必须定义 `SUMotionServiceProtocol`：
  * 真机实现：`SUHeadphoneMotionManager`——调用 `CMHeadphoneMotionManager`。
  * 模拟器调试实现：`SUMockMotionManager`——通过浮层摇杆或滑块模拟低头、抬头动作，确保无硬件时仍可完整调试 UI 与业务流。
* 环境切换策略：
  ```swift
  #if targetEnvironment(simulator)
  let motionService: SUMotionServiceProtocol = SUMockMotionManager()
  #else
  let motionService: SUMotionServiceProtocol = SUHeadphoneMotionManager()
  #endif
  ```

### 17.5 版本控制与 .gitignore
* 标准 iOS `.gitignore` 必须包含：
  ```
  # Xcode
  DerivedData/
  xcuserdata/
  *.xcworkspace/xcuserdata/
  *.xcodeproj/xcuserdata/

  # SPM
  .build/
  .swiftpm/

  # CocoaPods (备选)
  Pods/

  # OS
  .DS_Store
  *.swp

  # Secrets
  *.xcconfig  # 如包含 API Key 配置
  ```

### 17.6 编码风格速查
* **缩进**：4 个空格（Xcode 默认）。
* **最大行宽**：建议 120 字符。
* **空行**：`// MARK: -` 分区前后各留一空行。
* **访问控制**：
  * 默认 `internal`，不写显式修饰符。
  * 仅对外暴露的属性/方法标注 `public`。
  * 所有不应被外部访问的成员标注 `private` 或 `fileprivate`。
* **注释规范**：
  * 公开 API 使用 `///` 文档注释。
  * 逻辑复杂的私有方法使用 `//` 行内注释说明意图（而非 What，而是 Why）。

---

## 18. 全局公共配置与复用规范

在大型工程中，散落在各模块内的重复配置与魔法数字（Magic Numbers）是维护灾难的根源。本项目要求将所有**跨模块复用的配置、常量、工具方法**统一集中管理。

### 18.1 公共配置文件体系

按照**配置级别**从高到低，分为以下三层文件：

```text
Constants/
├── SUAppConfig.swift          // 🔴 最高级：应用级全局配置（API地址、版本号、功能开关）
├── SULayoutConstants.swift    // 🟡 UI 级：布局间距、圆角、动画时长等全局复用 UI 常量
└── SUMotionConstants.swift    // 🟢 业务级：传感器采样率、姿态阈值等业务领域常量
```

#### 18.1.1 应用级全局配置 (`SUAppConfig.swift`)
用于存放**整个 App 范围内的高级别公共配置**，任何模块都可能引用的全局变量：

```swift
/// 应用级全局配置 —— 跨模块复用的公共参数统一管理于此
enum SUAppConfig {

    // MARK: - 应用信息
    static let appName = "SpineUp"
    static let appBundleID = "com.spineup.app"

    // MARK: - 网络与 API
    static let aiAPIBaseURL = "https://api.example.com/v1"
    static let networkTimeoutInterval: TimeInterval = 15
    static let aiGenerationTimeout: TimeInterval = 3  // AI 生成超时后降级至离线

    // MARK: - 功能开关 (Feature Flags)
    static let isProSubscriptionEnabled = false  // Pro 订阅功能总开关
    static let isHealthKitEnabled = false         // HealthKit 功能总开关（Phase 4 开启）
    static let isFallbackCameraModeEnabled = false // 无耳机降级摄像头模式（Phase 4 开启）

    // MARK: - 分享与社交
    static let shareWatermarkText = "SpineUp · 做人要有骨气"
    static let appStoreURL = "https://apps.apple.com/app/spineup/idXXXXXXXX"

    // MARK: - 骨气能量系统
    static let energyPerMinuteUpright: Int = 1      // 每分钟挺拔获得的能量币
    static let streakBonusMultiplier: Double = 1.5   // 连续天数额外奖励倍率

    // MARK: - 提醒冷却
    static let voiceReminderCooldown: TimeInterval = 180  // 语音提醒最小间隔（秒）
}
```

#### 18.1.2 UI 级布局常量 (`SULayoutConstants.swift`)
所有跨页面复用的 UI 尺寸与间距：

```swift
/// 全局 UI 布局常量 —— 所有页面共享的间距、圆角、尺寸统一定义于此
enum SULayoutConstants {

    // MARK: - 通用间距
    static let horizontalPadding: CGFloat = 16
    static let verticalSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    static let cardInternalPadding: CGFloat = 16

    // MARK: - 圆角
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 20

    // MARK: - 组件高度
    static let primaryButtonHeight: CGFloat = 50
    static let petContainerHeight: CGFloat = 280
    static let gaugeViewHeight: CGFloat = 120
    static let tabBarHeight: CGFloat = 49

    // MARK: - 动画时长
    static let defaultAnimationDuration: TimeInterval = 0.3
    static let petStateTransitionDuration: TimeInterval = 0.6
    static let springDamping: CGFloat = 0.7
}
```

#### 18.1.3 业务级传感器常量 (`SUMotionConstants.swift`)
传感器采样与体态判定的专用领域常量：

```swift
/// 传感器与体态判定常量
enum SUMotionConstants {

    // MARK: - 传感器采样
    static let defaultSampleRateHz: Double = 15         // 默认采样频率
    static let lowPowerSampleRateHz: Double = 5          // 节能模式采样频率
    static let calibrationSampleDuration: TimeInterval = 2 // 校准采样时长（秒）
    static let movingAverageWindowSize: Int = 8           // 滑动窗口平滑帧数

    // MARK: - 体态阈值（角度，单位：度）
    static let slightSlumpThreshold: Double = 15.0       // 轻度前倾阈值
    static let severeSlumpThreshold: Double = 25.0       // 重度驼背阈值
    static let uprightRecoveryThreshold: Double = 10.0   // 恢复挺拔阈值（需低于此角度）

    // MARK: - 时间缓冲（秒）
    static let slumpBufferDuration: TimeInterval = 10    // 低头持续多久才判定为异常
    static let uprightBufferDuration: TimeInterval = 5   // 抬头持续多久才判定为恢复

    // MARK: - 颈椎力学模型参数（kg）
    static let neutralLoadKg: Double = 5.0               // 中立位颈椎基础负荷
}
```

### 18.2 公共工具方法复用规范

对于**多处使用的工具性方法**（非特定业务逻辑），统一放置在 `Extensions/` 目录下，按系统类型组织：

```text
Extensions/
├── UIColor+SUTheme.swift      // 主题色快捷访问（SUColor.primary、SUColor.accent 等）
├── Date+SUFormatting.swift    // 日期格式化（"今天 14:30"、"2026年10月8日"）
├── Double+SUAngle.swift       // 弧度↔角度转换、角度格式化
├── String+SULocalized.swift   // 本地化字符串便捷扩展
├── UIView+SUSnapshot.swift    // 视图截图导出工具
└── TimeInterval+SUDisplay.swift // 时长格式化（"1小时23分钟"、"03:45"）
```

### 18.3 使用原则与纪律

1. **新增常量前先查**：在任何文件中写下一个字面量数字或字符串之前，**先检查** `Constants/` 目录中是否已存在同类配置。如有，直接引用；如无，在对应常量文件中新增后再引用。
2. **严禁同一个值散落多处**：如果一个阈值、间距、URL、时长在两个以上模块中使用，它**必须**提取到 `Constants/` 中统一管理。
3. **常量文件只放值，不放逻辑**：`SUAppConfig` / `SULayoutConstants` / `SUMotionConstants` 均为纯 `enum`（无实例化），内部仅包含 `static let/var` 声明，**禁止**放置方法实现或业务逻辑。
4. **按级别归档**：
   * 全 App 级别（API 地址、功能开关、应用名称等）→ `SUAppConfig`
   * UI 级别（间距、圆角、动画时长等）→ `SULayoutConstants`
   * 特定业务领域（传感器参数、力学模型常数等）→ `SU<领域>Constants`
5. **敏感配置例外**：API Key、Secret 等敏感信息**不放在**常量文件中，使用 Keychain 或 `.xcconfig` + `.gitignore` 管理（参见 § 11.3）。
