# Proposal: Top Safe-Area Scroll Fade & iPhone Duo Adaptive Layout

- **Change ID**: `2026-11-24-status-bar-scrim-and-iphone-duo`
- **Status**: Archived
- **Owner**: Irving

## 1. Why
1. **顶部状态栏重叠 Bug**：在 4 个主页面上滑 `ScrollView` 时，Hero 卡片与列表内容会直接穿过顶部安全区，导致 `$31.95` 等文字与系统 `09:41` 时间和灵动岛发生重叠。
2. **iPhone Duo 折叠屏适配需求**：Apple 新款折叠屏 **iPhone Duo** 具备 **5.4 英寸窄外屏（Compact）** 与 **7.6 英寸展开内屏（Regular，带中央折痕与多任务分屏）**。当前布局为固定单列且悬浮 TabBar 无最大宽度约束，折叠态（5.4" 窄屏）容易挤压文案，展开态（7.6" 宽屏）卡片横跨中间折痕且视觉拉太宽。

## 2. What Changes
- [ ] **顶部安全区渐隐毛玻璃遮罩（`TopSafeAreaScrim`）**：
  - 在 `DesignSystem.swift` 新增 `TopSafeAreaScrim`（自动读取安全区顶部高度，在状态栏与灵动岛区域叠加柔和的背景渐变 + 轻度毛玻璃过渡），并挂载到 `OverviewView`、`SubscriptionListView`、`UpcomingView`、`SettingsView` 顶部；
  - 列表上滑时内容在进入状态栏前柔和隐去，保证 `09:41`、信号、电量与灵动岛始终清晰不撞车，且不影响正常点击与手势。
- [ ] **iPhone Duo 外屏（5.4" Compact）+ 内屏（7.6" Regular）双态自适应**：
  - **严格按 `@Environment(\.horizontalSizeClass)` 驱动**（绝不写死 `UIDevice.userInterfaceIdiom`，满足 iPhone Duo 同为 `.phone` 但内屏为 `.regular` 的特性）。
  - **7.6" 内屏展开态（Regular，同步兼容 iPad 分屏）**：
    - `OverviewView`：自动切换为**左右双栏网格布局**（左栏：Mood Banner + Aurora Hero 卡 + 指标卡；右栏：Upcoming Renewals + Category Breakdown 图表），中央留出清晰间距，**避免单张大卡片横跨折叠屏中间折痕**；
    - `SubscriptionListView` & `UpcomingView`：自动切换为 **2 列自适应卡片网格**（`LazyVGrid`），左右对称分布于折痕两侧；
    - `SettingsView`：在宽屏下采用 2 列分区布局（或居中优雅栏宽）避免超长横向拉伸；
    - `FloatingTabBar`：在宽屏下约束 `maxWidth: 440` 并居中悬浮，避免胶囊底栏被拉得过宽。
  - **5.4" 外屏折叠态（Compact 窄屏）**：
    - 精调 `FloatingTabBar`、Hero 金额、咖啡洞察胶囊与订阅行在窄宽度下的缩放与间距，确保 5.4" 窄屏零截断、零换行错位。
  - **折叠/展开热切换状态保持**：全部核心状态（当前 Tab、筛选条件、Paywall、SwiftData 数据）保持在顶层容器，折叠/展开动态缩放时不丢状态。
- [ ] **跨尺寸验证**：在当前 Xcode 16.2 环境下用 **iPhone 16 Pro Max（灵动岛滚顶测试）**、**iPhone SE（小窄屏模拟外屏）** 与 **iPad mini（7.6" 近似 Regular 展开双栏）** 三端模拟器视觉验证。

## 3. Non-Goals
- 本次不升级本机 Xcode 版本（当前 Mac 为 Xcode 16.2 / iOS 18.2 SDK；注：向 App Store 提交以完全解除 iPhone Duo 内屏黑边/letterboxing 时，后续需用新版 Xcode SDK 重新归档上传，但本方案的 SwiftUI 自适应代码零改动直接原生生效）。
- 不改动 SwiftData 模型、StoreKit 2 权益逻辑及 3 订阅免费上限。

## 4. Impact & Risks
- **Compatibility**：完全基于 iOS 17+ 标准 SwiftUI API（`horizontalSizeClass`、`LazyVGrid`、`safeAreaInset`、`GeometryReader`），向下兼容 iOS 17，向上无缝兼容 iOS 27+ iPhone Duo 动态展开。
- **App Review / Privacy**：无权限或隐私变更，且可一次性顺带提升 iPad / 折叠屏审核观感。
