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

### 2.2 Views & Flows
- **Overview**：主币种月/年支出汇总卡、7 天内到期与试用统计、近期续费列表、Swift Charts 分类支出柱状图（免费版模糊预览，Pro 解锁）。
- **Subscriptions**：搜索、分类筛选、左滑删除、右滑一键“已续费”（自动推进 `nextBillingDate` 并清除 `isTrial`）、12 个海外常见服务快捷预设。
- **Upcoming**：按「未来 7 天 / 未来 30 天 / 更晚」分组展示待扣费项及分组小计。
- **Settings**：主币种切换、通知权限检查与刷新、CSV 导出（Pro）、示例数据导入、一键清空本地数据、隐私/条款/支持外链。

### 2.3 Local Notifications (`NotificationManager`)
- 基于 `UNUserNotificationCenter`，按 `nextBillingDate - reminderDaysBefore` 的上午 9:00 触发本地提醒，区分试用转正提醒与普通续费提醒。

### 2.4 Monetization (`StoreManager` + `PaywallView`)
- **Free Tier**：最多 5 个订阅、基础 1 天前提醒、多币种折算、月/年总览。
- **Pro Tier**：
  - `com.irvingwangjr.subpulse.pro.monthly`（$2.99/mo）
  - `com.irvingwangjr.subpulse.pro.yearly`（$19.99/yr，含 7 天免费试用）
  - 解锁：无限订阅、3/7/14 天提前提醒、完整分类图表、CSV 导出。
- 严格遵循 Apple Guideline 3.1.2：展示清晰续费声明、Restore Purchases 按钮、Terms & Privacy 链接。

## 3. Overseas Compliance Baseline
- `ITSAppUsesNonExemptEncryption = NO`
- `PrivacyInfo.xcprivacy` 声明 `UserDefaults (CA92.1)` 且 `NSPrivacyTracking = false`
- 支持 `en`（主语言）与 `zh-Hans` 双语本地化
- 线上合规网页托管于 `https://irvingwangjr.github.io/SubPulse/`，支持邮箱 `kiinkrft@gmail.com`
