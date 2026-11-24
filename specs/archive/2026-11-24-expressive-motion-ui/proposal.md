# Proposal: Expressive, Emotional & Tactile Motion UI Overhaul

- **Change ID**: `2026-11-24-expressive-motion-ui`
- **Status**: Archived
- **Owner**: Irving

## 1. Why
当前 v1.0 界面偏系统默认表单风（生硬的 `List`、硬切 `TabView`、理性报表式文案），体感上比较“工程师/极客工具（nerd）”，缺少海外爆款独立 App（如 Copilot Money、Opal、Flighty、Gentler Streak）那种**有情绪温度、Q 弹顺滑、拿在手里忍不住多点几下**的质感：
- 底部 Tab 切换是生硬瞬间跳变，没有任何过渡动画；
- 列表内容较少时上下滑动发死，缺少 iOS 经典的弹性回弹（bounce）与卡片滚动呼吸感；
- 文案与视觉过于理性工具化，缺少让人有共鸣的“守护钱包、拒绝被试用偷袭”的情绪价值。

## 2. What Changes
- [ ] **情绪化视觉与氛围升级（Warm & Alive Aesthetic）**：
  - 全新设计系统 `DesignSystem.swift`（柔和渐变色板、环境光晕背景、24pt 柔和卡片容器、弹性按压按钮样式 `BouncyButtonStyle`）。
  - 首页顶部加入**情绪化状态脉搏条（Mood Banner）**（如试用临近提醒、本周零扣费治愈状态）+ **生活化每日折算洞察**（例如 `Just $1.06/day — less than a coffee ☕️`）。
  - 升级 Hero 金额卡片：多层极光渐变 + 呼吸光晕 + **机械滚动数字动画（`.contentTransition(.numericText())`）**。
  - 订阅卡片增加**柔和彩色图标光晕、试用脉冲呼吸点、直观续费倒计时进度条**。
- [ ] **丝滑切换与 Q 弹滚动体验（Spring Physics & Bounce）**：
  - 用 **悬浮毛玻璃胶囊 Tab Bar（`matchedGeometryEffect` 液体滑动指示器 + `.symbolEffect(.bounce)` + 触感反馈）** 替代生硬默认 TabBar，页面切换附带弹簧平滑过渡动画。
  - `Overview`、`Subscriptions`、`Upcoming` 全部改用 **`ScrollView` + `.scrollBounceBehavior(.always)`**，确保无论条数多少，上下滑动都有 Q 弹回弹手感，并加上 iOS 17 原生 **`.scrollTransition` 卡片进出视口微缩弹性动效**。
  - 分类筛选胶囊使用 `matchedGeometryEffect` 丝滑滑块 + 列表项弹簧重排。
  - 卡片点击、快捷预设、标记已续费、开关切换全面接入弹簧微动效与原生 Haptics（`.sensoryFeedback`）。
- [ ] **氛围感 Paywall 升级**：
  - 柔和光晕背景 + 呼吸动效皇冠徽章 + 弹性选中方案卡 + 更温暖的情绪化文案。
- [ ] **双语与上架截图同步刷新**：更新 `en` / `zh-Hans` 情绪化文案，重截一套高级感 6.9" App Store 截图。

## 3. Non-Goals
- 不引入任何第三方动画/UI 依赖库（保持 100% 原生 SwiftUI，零包体膨胀、120fps 顺滑）。
- 不修改 SwiftData 数据模型、3 个订阅免费上限规则、StoreKit 2 Product ID 与隐私合规声明。
- 不做过度花哨影响可读性的眩晕动画（遵循 iOS Reduce Motion 无障碍兼容与克制质感）。

## 4. Impact & Risks
- **Data / Migration**：零 Schema 变更，完全兼容现有本地数据。
- **Performance / Accessibility**：所有动效均使用 SwiftUI 原生 GPU 合成（`scaleEffect` / `opacity` / `matchedGeometryEffect` / `.scrollTransition`），低开销且流畅。
- **App Review / StoreKit**：Paywall 继续严格保留价格、周期、自动续订说明、Restore Purchases 与法务链接（Guideline 3.1.2 完全合规）。
