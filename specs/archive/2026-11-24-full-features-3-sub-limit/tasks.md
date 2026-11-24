# Tasks: Full-Feature Free Tier with 3-Subscription Limit

## Implementation
- [x] Update `AppConfig.freeSubscriptionLimit` from `5` to `3`
- [x] Update `ServicePreset.sampleItems()` from 4 items to 2 items (USD AI subscription + EUR trial subscription)
- [x] Remove Pro blur/lock gate from `OverviewView` category chart
- [x] Remove Pro gate & `(Pro)` labels from reminder lead times in `SubscriptionFormView`
- [x] Unlock CSV export for all users in `SettingsView` and cap `Load Sample Subscriptions` to respect free quota
- [x] Update `PaywallView` feature list to match "all features included, unlimited subscriptions in Pro"

## Localization & StoreKit
- [x] Update `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings`
- [x] Update `SubPulse.storekit` localized descriptions to match the unlimited-subscriptions positioning

## Verification, Screenshots & Archive
- [x] Build for iOS Simulator with 0 errors and 0 warnings
- [x] Fresh-install & verify on iPhone 16 Pro Max simulator (2/3 quota, unblurred chart, unlocked reminders & CSV)
- [x] Re-capture and visually verify updated 6.9-inch App Store screenshots
- [x] Sync `specs/baseline/subpulse-mvp.md` and move change folder to `specs/archive/`
- [x] Commit and push to GitHub (`origin main`)
