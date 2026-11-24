# Tasks: AI Subscription Focus

## Implementation
- [ ] `ServicePreset.ai`：新增约 15 个 AI 订阅预设，Copilot 改为 `.aiTools`，`popular` 中 AI 类置顶
- [ ] 新增 `AISpendSummary`（纯逻辑：count / monthly / yearly / shareOfTotal）
- [ ] 新增 `AIOnboardingView`（多选、实时合计、免费上限截断后弹 Paywall、跳过）
- [ ] `ContentView`：移除自动示例数据写入，改为按 `hasCompletedOnboarding` 展示引导页；老用户自动视为已完成
- [ ] 新增 `AISpendCard` 并接入 `OverviewView`（含空态入口、≥3 个时的提示）
- [ ] 新增 `AISpendShareImage` + `ImageRenderer` + `ShareLink` 分享
- [ ] 添加后提示「请核对扣费日期」

## Localization & Compliance
- [ ] `en.lproj` & `zh-Hans.lproj` 新增全部文案
- [ ] `Info.plist` 新增 `NSPhotoLibraryAddUsageDescription`
- [ ] 确认 `PrivacyInfo.xcprivacy` 无需变更（仍不收集数据）
- [ ] 更新 `LAUNCH_CHECKLIST.md` 中的审核备注（示例数据改为在 Settings 手动导入）
- [ ] 撰写 App Store 元数据草稿（副标题、关键词、截图文案），避免堆砌第三方商标

## Verification & Archive
- [ ] `swiftc -typecheck` 0 errors / 0 warnings
- [ ] `AISpendSummary` 最小单元测试通过
- [ ] 按 design.md §4 完成模拟器手测（由 Owner 在 Xcode 中执行）
- [ ] Update `specs/baseline/subpulse-mvp.md`
- [ ] Move change folder to `specs/archive/`
