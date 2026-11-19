# SubPulse Project Guide

本项目遵循 **Spec-Driven（Proposal-Driven）** 开发模式，详细协作规范见 `AGENTS.md` 与 `specs/README.md`。

## 快速摘要
- **技术栈**：SwiftUI + SwiftData + StoreKit 2 + Swift Charts（iOS 17.0+，零后端）
- **Bundle ID**：`com.irvingwangjr.subpulse`
- **任何新功能/较大变更**：先在 `specs/changes/<date>-<slug>/` 创建 `proposal.md`、`design.md`、`tasks.md`，确认后再动代码。
- **活文档基准**：当前 v1.0.0 能力定义在 `specs/baseline/subpulse-mvp.md`。
