# Proposal: AI Subscription Focus（定位收窄为「AI 订阅管家」）

- **Change ID**: `2026-11-20-ai-subscription-focus`
- **Status**: Draft
- **Owner**: Irving

## 1. Why

- **通用订阅追踪是红海**：Rocket Money、Bobby 等已占据心智，SubPulse 作为后来者靠「多币种 + 隐私」很难被搜到、更难被短视频推广。
- **AI 订阅是 2026 年的新痛点**：重度用户同时订阅 ChatGPT、Claude、Cursor、Midjourney、Perplexity 等，单月 $50–$200+ 却很少有人算过总账。「你每月在 AI 上花多少钱？」是一个可以在 3 秒短视频里讲清楚、自带传播性的钩子。
- **首启体验有硬伤**：当前首次启动会把 4 条示例订阅写入用户真实数据，而免费版上限是 5 条 —— 新用户不删示例就只能再加 1 条便撞上 Paywall，既困惑又像「诱导付费」。
- **改动成本低**：代码已有 `aiTools` 分类和 ChatGPT / Claude 预设，无需改数据模型即可完成定位切换。

## 2. What Changes

- [ ] **AI 服务预设扩充**：新增约 15 个主流 AI 订阅预设（价格仅作默认值、可编辑），并把 GitHub Copilot 归入 `aiTools`。预设列表中 AI 类置顶。
- [ ] **首启引导替换示例数据**：首次启动展示「你在为哪些 AI 工具付费？」多选卡片，一键批量添加；**不再自动写入示例数据**（Settings 中「导入示例数据」保留，供审核与演示）。
- [ ] **概览页新增「AI 支出」卡片**（免费）：AI 订阅数量、月支出、年化支出、占总支出比例；当 AI 订阅 ≥ 3 个时给出温和提示「你真的都在用吗？」。
- [ ] **可分享的「AI 支出卡片」图片**（免费，带 `Tracked with SubPulse` 水印）：通过系统分享面板导出为图片，作为自然增长渠道。
- [ ] **App Store 元数据重写**（非代码）：副标题、关键词、截图文案转向「AI subscription tracker」。

## 3. Non-Goals

- 不接入任何后端、不做实时汇率、不读取邮件/银行账单自动识别订阅。
- **不在 App 内调用任何大模型**（避免 API 成本、隐私标签变化和「AI 功能」相关审核）。
- 不调整价格与 Free / Pro 权益边界（免费上限仍为 5 个）。
- 不修改 SwiftData 数据模型，不做 AI 子分类（如「聊天助手 / 编程 / 图像」）——留待验证需求后再说。
- 不做桌面小组件、iCloud 同步。

## 4. Impact & Risks

- **Data / Migration**：无 schema 变更。Copilot 预设改分类只影响**新添加**的条目，已有数据不动。
- **StoreKit / Monetization**：权益不变。去掉自动示例数据后，用户首周更可能真实填满 5 个订阅，Paywall 触发更「正当」。引导页批量添加须遵守免费上限（超出部分引导至 Paywall，而非静默丢弃）。
- **App Review / Privacy**：
  - 预设中出现第三方服务名称属于正常的追踪类用途，但**只用 SF Symbols、不使用第三方 Logo**；App 名称与关键词中**避免直接堆砌第三方商标**（Guideline 2.3.7 / 5.2.1），用 "AI subscriptions" 等通用词。
  - 分享图片走系统分享面板；为防用户选择「存储图像」时崩溃，需在 `Info.plist` 增加 `NSPhotoLibraryAddUsageDescription`。仍然不收集任何数据，Privacy Nutrition Label 保持「Data Not Collected」。
  - 审核备注需同步更新：说明示例数据改为在 Settings 中手动导入。
- **预设价格过时风险**：AI 服务价格变动频繁，预设价格标注为「参考价，可编辑」，不承诺准确。
