# Baseline Spec: SubPulse v1.0.0 MVP

> **Status**: Implemented (`main`)  
> **Target Platform**: iOS 17.0+ (SwiftUI, SwiftData, StoreKit 2, Swift Charts)  
> **Bundle ID**: `com.irvingwangjr.subpulse`

## 1. Product Positioning
100% 本地隐私的多币种订阅与免费试用追踪器，面向海外 App Store 市场（无后端、免注册登录、Data Not Collected）。

## 2. Core Capabilities

### 2.1 Data Model (`SubscriptionItem`)
- 本地 SwiftData 持久化字段：`id`, `name`, `amount`, `currencyCode`, `billingCycleRaw`, `categoryRaw`, `nextBillingDate`, `reminderDaysBefore`, `isTrial`, `notes`, `iconSymbol`, `colorHex`, `createdAt`。
- 支持周期：`weekly`、`monthly`、`quarterly`、`yearly`，统一折算为月均与年化支出。
- 支持 9 种内置离线参考汇率币种：`USD`, `EUR`, `GBP`, `JPY`, `CAD`, `AUD`, `CNY`, `HKD`, `SGD`。

### 2.2 Views, Motion & Aesthetic
- **Design System (`DesignSystem.swift`)**：统一弹簧物理动效参数（`AppMotion.snappy / bouncy / gentle`）、触感按压按钮 `BouncyButtonStyle`、呼吸光点 `PulseDotView`、自适应明暗环境光晕 `AmbientBackgroundView`、滚动驱动折叠吸顶毛玻璃顶栏 `CollapsingTopBar`（iOS 18 原生 `onScrollGeometryChange` 驱动 + iOS 17 降级兼容，展示页面紧凑标题 + 核心摘要胶囊 + 快捷操作，点击回顶）、`24pt` 柔和悬浮卡片 `.tactileCard()`、iOS 17 原生 `.scrollTransition` 滚动呼吸缩放 `.scrollCardMotion()`。
- **Haptic Kinetic Onboarding (`OnboardingView`)**：冷启动首帧直出深色极光 3 页可滑动引导（无白屏闪烁）：
  - **Page 0**：仿 ChatGPT 逐词/分节浮现开屏，基于稳定占位 `AttributedString` 零重影渲染，每拍同步触发 `UIImpactFeedbackGenerator(.soft)` 轻震与中心脉搏光环微跳，自动轮播 3 组核心价值主张。
  - **Page 1**：5 秒热门服务图标墙（3 列 12 项海外高频预设），点击即时累计月均支出并受 3 个免费额度保护。
  - **Page 2**：一键跳转系统 Apple 订阅页（`itms-apps://apps.apple.com/account/subscriptions`）+ 零权限相册选图离线 OCR 识别 + 通知授权启动；跳过全部时自动预置 2 条示例数据。
- **Zero-Friction Smart Import (`SmartImportView` + `ScreenshotOCRParser`)**：在订阅页顶栏、折叠顶栏与空态均提供「快捷 / 识图」入口；支持 12 项热门预设一键点选、基于 Apple `Vision` (`VNRecognizeTextRequest`, `en-US` + `zh-Hans`) 的 100% 本机离线截图识别（通过 out-of-process `PhotosPicker` 免相册权限弹窗）及剪贴板账单文本解析。
- **Adaptive Multi-Screen & iPhone Duo Support**：严格基于 `@Environment(\.horizontalSizeClass)` 适配，兼容 5.4" 折叠外屏/小屏（紧凑缩放零截断）与 7.6" iPhone Duo 展开内屏 / iPad（`Overview` 左右双栏、`Subscriptions` / `Upcoming` / `Settings` 2 列折痕安全网格、`FloatingTabBar` 宽屏 `440pt` 居中悬浮）。
- **Navigation (`FloatingTabBar`)**：自定义悬浮毛玻璃胶囊底栏，支持 `matchedGeometryEffect` 液体滑动指示器、`.symbolEffect(.bounce)` 图标弹性反馈、`.sensoryFeedback(.selection)` 触感震动，及带方向感知的弹簧切页过渡动画。
- **Overview**：`ScrollView` + `.scrollBounceBehavior(.always)`；动态情绪状态脉搏条（试用临近 / 本周续费 / 安心躺平）、极光呼吸 Hero 金额卡（带 `.numericText()` 机械滚动数字动画与每日咖啡等价洞察）、带彩色光晕的指标卡片、带续费倒计时进度条的近期续费列表、无遮挡 Swift Charts 分类支出柱状图。
- **Subscriptions**：`ScrollView` + `.scrollBounceBehavior(.always)`；搜索、带进度条的 `2/3` 免费额度卡片、`matchedGeometryEffect` 丝滑分类胶囊筛选、带呼吸试用点与倒计时进度条的卡片（长按快捷菜单支持已续费/编辑/删除）、快捷点选与离线 OCR 极速导入入口。
- **Upcoming**：`ScrollView` + `.scrollBounceBehavior(.always)`；按「未来 7 天 / 未来 30 天 / 更晚」分组展示及小计，支持一键 Q 弹「已续费」按钮与成功触感反馈。
- **Settings**：`ScrollView` + `.scrollBounceBehavior(.always)`；暖色渐变 Pro 升级横幅卡片、主币种切换、通知权限检查与刷新、全量开放的 CSV 导出、系统 Apple 订阅页快捷入口、重看开屏引导与极速配置、受免费额度约束的示例数据导入、一键清空本地数据、隐私/条款/支持外链。

### 2.3 Local Notifications (`NotificationManager`)
- 基于 `UNUserNotificationCenter`，按 `nextBillingDate - reminderDaysBefore` 的上午 9:00 触发本地提醒，区分试用转正提醒与普通续费提醒；1 / 3 / 7 / 14 天提前提醒对所有用户免费开放。

### 2.4 Monetization (`StoreManager` + `PaywallView`)
- **策略**：全功能完整开放 + 单一数量上限（Free ≤ 3 个订阅，Pro 无限数量）。
- **Free Tier**：最多 **3 个订阅**，包含全部核心功能（多币种折算、完整分类图表、1/3/7/14 天自定义提醒、CSV 导出）。已有 ≥3 条记录的免费用户（含 Pro 过期用户）不丢数据，可正常查看/编辑/续费/导出/删除，仅在继续新增时触发 Paywall。
- **Pro Tier**：
  - `com.irvingwangjr.subpulse.pro.monthly`（$2.99/mo）
  - `com.irvingwangjr.subpulse.pro.yearly`（$19.99/yr，含 7 天免费试用）
  - 解锁：无限数量订阅与试用追踪、自动获取后续 Pro 新特性。
- 严格遵循 Apple Guideline 3.1.2：展示清晰续费声明、Restore Purchases 按钮、Terms & Privacy 链接。

## 3. Overseas Compliance Baseline
- `ITSAppUsesNonExemptEncryption = NO`
- `PrivacyInfo.xcprivacy` 声明 `UserDefaults (CA92.1)` 且 `NSPrivacyTracking = false`
- 支持 `en`（主语言）与 `zh-Hans` 双语本地化
- 线上合规网页托管于 `https://irvingwangjr.github.io/SubPulse/`，支持邮箱 `kiinkrft@gmail.com`
