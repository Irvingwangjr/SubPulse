# Proposal: Full-Feature Free Tier with 3-Subscription Limit

- **Change ID**: `2026-11-24-full-features-3-sub-limit`
- **Status**: Archived
- **Owner**: Irving

## 1. Why
目前 Pro 付费墙同时锁定了「订阅数量（>5）、分类支出图表（首页模糊打码）、提前 3/7/14 天提醒、CSV 导出」。这种「锁功能」策略有两个缺点：
1. 新用户首次打开即看到首页图表马赛克与多个 Pro 锁，削弱产品第一印象与“真好用”的 Aha Moment；
2. 免费额度设为 5 个时，许多轻度用户不需要升级即可满足需求，反而削弱核心付费触发点。

改为海外独立工具 App 验证过的 **「全功能完整开放 + 免费限 3 个订阅」** 策略：让所有免费用户完整体验图表、多币种折算、自定义提前提醒和 CSV 导出，靠清晰透明的 **3 个订阅上限** 自然驱动高意向用户升级 Pro，同时对 App Store 审核（Guideline 4.2 / 3.1.2）更加友好。

## 2. What Changes
- [ ] **调整免费数量上限**：`AppConfig.freeSubscriptionLimit` 从 `5` 改为 `3`。
- [ ] **全面解除功能锁（Free & Pro 共享完整功能）**：
  - `OverviewView`：移除分类支出柱状图的模糊遮罩与 Pro 锁定浮层，所有用户直接查看清晰完整的 Swift Charts 分类图表。
  - `SubscriptionFormView`：提前提醒周期（1 / 3 / 7 / 14 天）全部免费可用，移除 `(Pro)` 后缀与拦截跳转。
  - `SettingsView`：CSV 导出功能对所有用户开放，移除 `Pro` 门控。
- [ ] **精简默认示例数据（4 条 → 2 条）**：
  - 首次启动仅预置 **2 条** 高代表性示例数据（美元 AI 订阅 + 欧元免费试用订阅），保留多币种折算、试用徽章和双分类图表展示，同时给新用户留出 **1 个免费新建名额**，避免刚打开就被迫付费。
- [ ] **防止「导入示例数据」绕过 3 个上限**：
  - 免费用户在 Settings 点击「Load Sample Subscriptions」时，最多补足至 3 个；已满 3 个时直接弹出 Paywall。
- [ ] **重构 Paywall 文案与双语本地化（`en` / `zh-Hans`）**：
  - 明确传达「免费版已含全部完整功能（限 3 个订阅），Pro 解锁无限订阅追踪 & 支持独立开发」。
- [ ] **更新 6.9" App Store 上架截图**：重截无马赛克图表的 Overview / Subscriptions / Settings 截图并同步提交。

## 3. Non-Goals
- 不修改 StoreKit 2 Product ID（`com.irvingwangjr.subpulse.pro.monthly` / `.yearly`）、定价与 7 天试用配置。
- 不修改 SwiftData `SubscriptionItem` Schema（无迁移成本）。
- 暂不引入 Lifetime 买断内购（如需买断，后续单开 Proposal）。

## 4. Impact & Risks
- **Data / Migration**：零 Schema 变更。对于本机已存 ≥3 条订阅的免费用户（或 Pro 过期用户），**绝不删除或锁定已有数据**——用户仍可正常查看、编辑、标记续费、导出 CSV、删除，仅在尝试**新增**订阅时触发 Paywall。
- **StoreKit / Monetization**：权益边界简化为单一数量门控（3 vs Unlimited）；App Store Connect 填写订阅描述时需同步强调“Unlock unlimited subscriptions”。
- **App Review / Privacy**：正向影响，审核员无需购买即可体验完整图表、多档提醒与导出能力；无新增权限或隐私声明变化。
