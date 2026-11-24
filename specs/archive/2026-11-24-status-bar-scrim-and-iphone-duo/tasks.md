# Tasks: Top Safe-Area Scroll Fade & iPhone Duo Adaptive Layout

## Implementation
- [x] Add `TopSafeAreaScrim` modifier and narrow-screen / wide-screen responsive tuning to `DesignSystem.swift` (`FloatingTabBar` `maxWidth: 440` centered, `minimumScaleFactor` on labels)
- [x] Apply `.topSafeAreaScrim()` and `horizontalSizeClass == .regular` 2-column hinge-safe layout to `OverviewView.swift`
- [x] Apply `.topSafeAreaScrim()` and 2-column `LazyVGrid` on Regular width to `SubscriptionListView.swift`
- [x] Apply `.topSafeAreaScrim()` and 2-column `LazyVGrid` on Regular width to `UpcomingView.swift`
- [x] Apply `.topSafeAreaScrim()` and Regular 2-column layout to `SettingsView.swift`

## Multi-Device Verification & Archive
- [x] Build for iOS Simulator with 0 errors and 0 warnings
- [x] Verify scrolled status-bar fade on `iPhone 16 Pro Max` simulator (no `$31.95` / `09:41` overlap)
- [x] Verify narrow outer-screen layout on `iPhone SE (3rd gen)` simulator
- [x] Verify unfolded Regular 2-column layout on `iPad mini (A17 Pro)` simulator
- [x] Update `specs/baseline/subpulse-mvp.md`, archive spec folder, and push to GitHub
