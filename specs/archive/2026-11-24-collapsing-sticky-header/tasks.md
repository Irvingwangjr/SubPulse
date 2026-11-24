# Tasks: Collapsing Sticky Glass Top Bar with Compact Summary

## Implementation
- [x] Add `ScrollOffsetPreferenceKey`, `ScrollOffsetTracker`, and `CollapsingTopBar` to `DesignSystem.swift` (replacing static `TopSafeAreaScrimModifier`)
- [x] Integrate `ScrollViewReader` + `CollapsingTopBar` (`SubPulse` + `$XX.XX/mo` + mini `Pro` pill) into `OverviewView.swift`
- [x] Integrate `ScrollViewReader` + `CollapsingTopBar` (`Subscriptions` + quota/count pill + mini `+` button) into `SubscriptionListView.swift`
- [x] Integrate `ScrollViewReader` + `CollapsingTopBar` (`Upcoming` + 7-day subtotal pill) into `UpcomingView.swift`
- [x] Integrate `ScrollViewReader` + `CollapsingTopBar` (`Settings` + Pro status/pill) into `SettingsView.swift`

## Verification & Archive
- [x] Build for iOS Simulator with 0 errors and 0 warnings
- [x] Visually verify both at-rest AND scrolled-down collapsing top bar on `iPhone 16 Pro Max` simulator (zero `09:41` collision, crisp summary pill)
- [x] Sync `specs/baseline/subpulse-mvp.md`, archive change folder to `specs/archive/`, and push to GitHub
