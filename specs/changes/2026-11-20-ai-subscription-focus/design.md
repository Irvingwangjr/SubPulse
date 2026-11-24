# Design: AI Subscription Focus

## 1. Architecture & Data Model

**无 SwiftData schema 变更**，全部基于现有 `SubscriptionItem.categoryRaw == "aiTools"` 判定。

| 文件 | 变更 |
| --- | --- |
| `Models/ServicePreset.swift` | 新增 `static let ai: [ServicePreset]`（约 15 个），`popular` 改为 `ai + others`；Copilot 分类改为 `.aiTools`；`sampleItems()` 保留不变（仅 Settings 手动导入使用）。 |
| `Models/AISpendSummary.swift`（新） | 纯函数结构体：输入 `[SubscriptionItem]` + `baseCurrency`，输出 `count`、`monthly`、`yearly`、`shareOfTotal`。便于单元测试，不依赖 UI。 |
| `Views/Onboarding/AIOnboardingView.swift`（新） | 多选网格（预设 chip），底部「添加 N 个」+「跳过」。 |
| `Views/Overview/AISpendCard.swift`（新） | 概览页卡片；含「分享」按钮。 |
| `Views/Overview/AISpendShareImage.swift`（新） | 固定尺寸（1080×1350 逻辑比例 4:5）的分享画面，用 `ImageRenderer` 渲染成 `UIImage`，经 `ShareLink` 分享。 |
| `Views/ContentView.swift` | 移除 `seedDemoDataIfNeeded()`；改为 `@AppStorage("hasCompletedOnboarding")` 为 `false` 且 `items.isEmpty` 时以 `fullScreenCover` 展示引导页。 |
| `Views/Overview/OverviewView.swift` | 在 `heroSummaryCard` 下方插入 `AISpendCard`（仅当存在 AI 订阅时显示；无 AI 订阅时显示一个「添加你的 AI 订阅」入口）。 |

**老用户兼容**：已有 `hasSeededDemoData == true` 或已有数据的用户，直接视为已完成引导，不弹引导页。

## 2. UI / UX Flow

**首启引导**
1. 标题：「你在为哪些 AI 工具付费？」/ "Which AI tools are you paying for?"
2. 预设 chip 多选（图标 + 名称 + 参考价）。
3. 底部按钮实时显示「添加 3 个 · 约 $60/月」。
4. **免费上限处理**：非 Pro 用户选择超过 5 个时，按钮文案变为「添加前 5 个，解锁全部」→ 先添加前 5 个，再弹 Paywall。
5. 「跳过」直接进入空态概览页。
6. 添加后的条目 `nextBillingDate` 默认今天起 +30 天（月付）/ +365 天（年付），并在概览页顶部提示「请核对扣费日期」。

**AI 支出卡片（概览页）**
- 主数字：`$87.00 / mo`；副信息：`5 AI subscriptions · $1,044 / yr · 46% of total`。
- AI 订阅 ≥ 3 个时，底部一行提示：「5 个 AI 订阅，你真的都在用吗？」
- 右上角分享按钮 → 系统分享面板（图片）。

**分享图片**
- 大字：「I spend **$87/mo** on AI」；列出最多 6 个 AI 订阅名与价格；底部水印 `Tracked with SubPulse`。
- 不包含任何个人信息、备注或日期。

**状态**
- 空态：无 AI 订阅 → 卡片变为「+ 添加 AI 订阅」入口，点击打开引导页（复用）。
- Pro 门控：本次新增功能均为免费，不新增门控。

## 3. Edge Cases & Compatibility

- **多币种**：AI 支出统一折算到用户主币种（复用 `monthlyAmount(in:)`）。
- **周付/季付/年付**：均折算为月度与年度，复用现有 `BillingCycle` 逻辑。
- **总支出为 0**：`shareOfTotal` 返回 `nil`，不显示百分比，避免除零。
- **本地化**：所有新文案提供 `en` 与 `zh-Hans`；分享图片文案跟随系统语言。
- **ImageRenderer**：iOS 16+ 可用，项目最低 iOS 17，无兼容问题；渲染需在 `@MainActor`。
- **Dynamic Type / 深色模式**：卡片跟随系统；分享图片使用固定配色，保证导出效果一致。

## 4. Verification Plan

- **编译**：`swiftc -typecheck`（本机）+ 用户在 Xcode 中 Archive 一次，0 错误 0 警告。
- **单元逻辑**：为 `AISpendSummary` 写最小测试（多币种折算、空列表、总额为 0）。
- **模拟器手测**：
  1. 全新安装 → 出现引导页 → 选 3 个 → 概览页 AI 卡片数字正确。
  2. 非 Pro 选 7 个 → 只添加 5 个并弹出 Paywall。
  3. 跳过引导 → 空态入口可再次打开引导。
  4. 分享 → 选择「存储图像」不崩溃，图片内容正确。
  5. 老用户（已有数据）升级后不弹引导页。
  6. 中英文切换文案完整。
