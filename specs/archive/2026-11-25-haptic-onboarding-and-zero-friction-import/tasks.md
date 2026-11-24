# Tasks: Haptic Kinetic Onboarding & Zero-Friction Import

- [x] Build `ScreenshotOCRParser.swift` (Apple Vision `VNRecognizeTextRequest` + clipboard text parser + `ServicePreset` enrichment).
- [x] Build 3-page swipeable `OnboardingView.swift` (ChatGPT-style haptic kinetic splash, 5-second Popular Services Icon Wall, Apple Subscriptions deep link & Vision OCR import).
- [x] Build `SmartImportView.swift` (Quick Pick Wall + Scan Screenshot / Paste Clipboard sheet respecting free quota).
- [x] Register all 3 new source files in `SubPulse.xcodeproj/project.pbxproj`.
- [x] Wire `OnboardingView` as zero-flash root on first launch in `ContentView.swift` and replayable cover from `SettingsView.swift`.
- [x] Wire `SmartImportView` into `SubscriptionListView.swift` (`Quick / Scan` pill, collapsed top bar action, empty-state CTA) and Apple Subscriptions shortcut in `SettingsView.swift`.
- [x] Add complete `en` and `zh-Hans` localized strings and validate with `plutil -lint`.
- [x] Build cleanly (`xcodebuild`, 0 errors, 0 warnings) and visually verify Chinese & English cold-launch kinetic onboarding on iPhone 16 Pro Max simulator.
- [x] Sync `specs/baseline/subpulse-mvp.md` and archive spec records.
