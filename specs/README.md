# SubPulse Spec-Driven Development

本项目采用 **Proposal-Driven / Spec-Driven** 研发流：每个需求先对齐规格，再写代码，避免需求漂移和返工。

## 工作流

```text
需求想法 → specs/changes/<date>-<slug>/{proposal,design,tasks}.md
        → 评审确认
        → 按 tasks.md 编码 & 编译验证
        → 更新 specs/baseline/ 并归档到 specs/archive/
```

## 什么时候必须走 Proposal？
- 新增功能模块（例如：桌面 Widget、iCloud 同步、实时汇率、新增本地化语言等）
- 修改 SwiftData 数据模型（涉及数据迁移风险）
- 修改 StoreKit 2 权益边界、价格策略或 Paywall 结构
- 改动 App Store 隐私声明、权限请求或合规文案

## 什么时候可直接改？
- 纯文案错别字、单处样式微调、明确的单点 Bug 修复（完成后同步提交说明即可）
