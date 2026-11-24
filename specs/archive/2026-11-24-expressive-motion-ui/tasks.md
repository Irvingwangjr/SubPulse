# Tasks: Expressive, Emotional & Tactile Motion UI Overhaul

## Design System & Navigation
- [x] Create `SubPulse/Views/Components/DesignSystem.swift` (spring tokens, `BouncyButtonStyle`, `PulseDotView`, `AmbientBackgroundView`, `FloatingTabBar` with `matchedGeometryEffect` + haptics)
- [x] Register `DesignSystem.swift` in `SubPulse.xcodeproj/project.pbxproj`
- [x] Upgrade `ContentView.swift` to use animated spring tab transitions + `FloatingTabBar`

## Screen Upgrades
- [x] Upgrade `OverviewView.swift` (emotional Mood Banner, Aurora Hero Card with numeric rolling text + daily insight, `.scrollBounceBehavior(.always)`, `.scrollTransition` cards, staggered entrance)
- [x] Upgrade `SubscriptionRowView.swift` & `SubscriptionListView.swift` (tactile cards with countdown progress bar & breathing trial dot, `ScrollView` + bounce + `.scrollTransition`, `matchedGeometryEffect` category pills, quick renew/delete actions with haptics)
- [x] Upgrade `UpcomingView.swift` (`ScrollView` + bounce timeline cards with 1-tap bouncy Renew button + haptics)
- [x] Upgrade `PaywallView.swift` (ambient glow aura, breathing crown badge, spring-selected plan cards, gradient CTA)
- [x] Polish `SettingsView.swift` (Pro gradient banner card, `.scrollBounceBehavior(.always)`, floating dock bottom clearance)

## Localization
- [x] Add emotional mood & daily insight copy to `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings`

## Verification, Screenshots & Archive
- [x] Build for iOS Simulator with 0 errors and 0 warnings
- [x] Fresh-install & verify on `iPhone 16 Pro Max` simulator (visual inspection of all screens)
- [x] Recapture updated 6.9-inch App Store screenshots
- [x] Sync `specs/baseline/subpulse-mvp.md` and archive to `specs/archive/`
- [x] Commit and push to GitHub (`origin main`)
