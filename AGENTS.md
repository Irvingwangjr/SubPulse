# SubPulse AI Agent Development Rules (Spec-Driven / Proposal-Driven)

本项目采用 **Spec-Driven（Proposal-Driven）开发规范**。所有 AI Agent 与开发者在新增功能、改动架构或调整核心业务流程时，必须严格遵守以下流程：

## 核心铁律

1. **先写 Proposal，再写代码**：除极小的 typo 修复或单行 bugfix 外，**严禁在未确认 Proposal 前直接修改 `SubPulse/` 业务代码**。
2. **单一事实来源（Single Source of Truth）**：`specs/baseline/` 描述当前线上/主分支的真实行为；所有变更必须以增量 Proposal 形式提出，落地后再同步回 baseline。

## 标准变更流程

对于任意新需求或较大改动，按以下 4 步推进：

1. **创建变更目录**：在 `specs/changes/<yyyy-mm-dd>-<short-slug>/` 下创建：
   - `proposal.md`：背景与动机（Why）、变更范围（What Changes）、明确不做的内容（Non-Goals）、风险与影响（Impact，含 App Store 审核/隐私/StoreKit 影响）。
   - `design.md`：数据模型变化、UI/交互流、关键边界条件、技术选型与兼容性（iOS 17+ / SwiftData 迁移）。
   - `tasks.md`：可勾选、可验证的实施与验证清单。
2. **等待确认**：把 Proposal 核心决策呈现给用户，**获得确认后**才开始编码。
3. **按单实施与验证**：严格按 `tasks.md` 逐项实现，并在完成后验证编译与关键行为。
4. **同步与归档**：
   - 将已落地的行为更新到 `specs/baseline/`；
   - 将完成的变更目录移入 `specs/archive/`。

## 目录结构

```text
specs/
├── README.md                    # 规范说明
├── baseline/                    # 当前主分支的真实功能与架构规格
│   └── subpulse-mvp.md
├── changes/                     # 进行中 / 待确认的变更 Proposal
├── archive/                     # 已完成并归档的历史 Proposal
└── templates/                   # proposal / design / tasks 模板
```
