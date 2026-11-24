# Proposal: Collapsing Sticky Glass Top Bar with Compact Summary

- **Change ID**: `2026-11-24-collapsing-sticky-header`
- **Status**: Archived
- **Owner**: Irving

## 1. Why
目前顶部只有一层纯粹的 `TopSafeAreaScrim` 毛玻璃渐隐遮罩，上滑后大标题和核心金额一起滑出屏幕，缺少真正顶级 iOS App（如 Apple Health、Apple Music、Copilot Money）那种 **「上滑平滑收起为紧凑吸顶顶栏（Collapsing Sticky Header）」** 的高级交互：
- 向下滚动浏览明细或图表时，用户仍能一眼看到当前页面标题与核心摘要（例如月支出 `$31.95/mo`、剩余额度、快捷 `+` 按钮）；
- 吸顶栏延伸至顶部安全区并带有通透毛玻璃与细底边，彻底优雅地承接滚上去的内容，彻底杜绝内容和状态栏/灵动岛的视觉打架。

## 2. What Changes
- [ ] **新增可复用吸顶折叠顶栏组件 `CollapsingHeaderBar` & 滚动偏移追踪器（`DesignSystem.swift`）**：
  - 使用轻量 `PreferenceKey`（`ScrollOffsetKey`）实时追踪每个 `ScrollView` 的垂直滚动距离（100% 兼容 iOS 17+，零卡顿）；
  - 未滚动时（`offset ≈ 0`）：顶栏完全隐身（保留通透极光大标题氛围）；
  - 上滑超过阈值（约 `36pt`–`90pt` 线性插值 + 弹簧微过渡）：顶栏顺滑浮现，延伸覆盖状态栏与灵动岛，带 `.ultraThinMaterial` 毛玻璃背景与 `0.5pt` 底部分割线，展示紧凑标题 + 页面专属核心缩写信息 + 快捷操作按钮。
- [ ] **4 个主页面接入各自专属的紧凑摘要顶栏**：
  - **`OverviewView`**：滑过 Hero 卡后，顶栏收起展示 **`SubPulse`** + 蓝色紧凑金额胶囊 **`$31.95/mo`** + 紧凑 **`👑 Pro`** 按钮（点顶栏可一键回顶！）；
  - **`SubscriptionListView`**：上滑后顶栏收起展示 **`Subscriptions`** + 紧凑计数胶囊（如 **`2/3`**）+ 紧凑 **`+`** 按钮（随时一键新增，不用再滑回顶部）；
  - **`UpcomingView`**：上滑后顶栏收起展示 **`Upcoming`** + 紧凑近期待付金额胶囊（如 **`$31.95`**）；
  - **`SettingsView`**：上滑后顶栏收起展示 **`Settings`** + 紧凑 **`Pro`** 状态标识。
- [ ] **替换旧的 `TopSafeAreaScrim`**：用这套真正的动态折叠顶栏取代静态渐隐遮罩；在滚动到顶部时保持纯净极光，一旦开始上滑立刻无缝过渡为完整毛玻璃吸顶顶栏。
- [ ] **兼容 iPhone Duo（5.4" 外屏 & 7.6" 展开内屏）与回顶体验**：吸顶顶栏自动适配左右内边距与最大栏宽，轻点顶栏标题可弹簧平滑滚回顶部（`ScrollViewReader`）。

## 3. Non-Goals
- 不改回僵硬的系统原生 `NavigationStack` 导航栏（保留自定义极光大标题、卡片动效与紧凑金额胶囊的自由度）。
- 不修改 SwiftData 数据模型、StoreKit 2 权益逻辑及多语言架构。

## 4. Impact & Risks
- **Performance**：`PreferenceKey` 仅在滚动偏移变化时更新轻量 `CGFloat`（平滑 clamped `0...1`），不触发整表重算，保持 120fps 顺滑。
- **Compatibility**：100% 原生 iOS 17+ SwiftUI，完美兼容 Light/Dark Mode、Dynamic Island、iPhone SE 及 iPhone Duo 折叠/展开态。
