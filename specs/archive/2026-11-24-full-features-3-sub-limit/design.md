# Design: Full-Feature Free Tier with 3-Subscription Limit

## 1. Architecture & File-Level Changes

| File | Change |
| --- | --- |
| `SubPulse/Models/AppConfig.swift` | `freeSubscriptionLimit = 3` (was `5`). |
| `SubPulse/Models/ServicePreset.swift` | Update `sampleItems()` from 4 items to 2 items: `ChatGPT Plus` (`$20.00/mo`, AI Tools, due in 3 days) and `Spotify Premium Trial` (`€10.99/mo`, Music, `isTrial: true`, due in 2 days). Showcases multi-currency conversion, trial badge, upcoming alerts, and 2-bar category chart while leaving 1 free slot (`2 / 3`). |
| `SubPulse/Views/Overview/OverviewView.swift` | Remove `blur(radius:)`, Pro lock button, and blurred overlay on `categoryChartCard`. Render full Swift Charts breakdown unconditionally. Keep top-right Crown button for free users as a non-intrusive Pro entry. |
| `SubPulse/Views/Subscriptions/SubscriptionFormView.swift` | Remove `proReminderLabel` suffix and `.onChange` paywall interception on `reminderDaysBefore` picker. All reminder lead times (1 / 3 / 7 / 14 days) work for all users. |
| `SubPulse/Views/Settings/SettingsView.swift` | Unlock CSV Export for all users (prepare CSV dynamically on appear & whenever `items.count` or `baseCurrencyCode` changes). Update `Load Sample Subscriptions` so free users cannot exceed `AppConfig.freeSubscriptionLimit`: if `items.count >= limit && !storeManager.isPro`, present paywall; otherwise insert up to remaining slots (`limit - items.count`). |
| `SubPulse/Views/Paywall/PaywallView.swift` | Update feature rows to accurately reflect the new value proposition (no false claims that charts/alerts/CSV are locked): e.g., Unlimited subscriptions & trials, Track every currency & renewal without limits, Full access to all future Pro enhancements, Support independent privacy-first development. |
| `SubPulse/Resources/en.lproj/Localizable.strings` & `zh-Hans.lproj/Localizable.strings` | Update `subs.free_quota_desc`, `paywall.subtitle`, `paywall.feat_*`, and remove obsolete `overview.unlock_analytics`. |

## 2. UI / UX Flow & Edge Cases

- **First Launch (Fresh Install)**:
  - Seeds 2 sample subscriptions (`2 / 3`).
  - Overview shows `$31.95/mo` (`$20.00` + `€10.99 ≈ $11.95`), 2 upcoming renewals, 1 trial, and a sharp, unblurred 2-category Swift Chart.
  - Subscriptions banner shows `Free Plan: 2 / 3 subscriptions`.
- **Adding Subscriptions**:
  - Adding the 3rd subscription opens `SubscriptionFormView` normally (`3 / 3`).
  - Tapping `+` when `items.count >= 3` and `!storeManager.isPro` presents `PaywallView`.
- **Pro Expiration / Existing >3 Subscriptions**:
  - All existing items remain fully visible, editable, renewable, exportable, and deletable.
  - Only creating new subscriptions beyond 3 is gated.
- **CSV Export Freshness**:
  - Ensure `exportFileURL` refreshes when `items.count` or `baseCurrencyCode` changes so exported CSV always reflects current data.

## 3. Verification Plan
1. Clean Simulator build via `xcodebuild` (`0 errors`, `0 warnings`).
2. Reinstall & launch on `iPhone 16 Pro Max` simulator (fresh app data so 2-item seed runs cleanly).
3. Verify visually on simulator:
   - Overview shows unblurred Category Breakdown chart and `2` active plans.
   - Subscriptions shows `Free Plan: 2 / 3 subscriptions`.
   - New Subscription shows all reminder lead times without `(Pro)` labels.
   - Settings shows unlocked `Export CSV` without `Pro` badge.
   - Paywall reflects the updated "Unlimited Subscriptions" positioning.
4. Re-capture updated 6.9-inch (`1320 × 2868`) App Store screenshots and verify every PNG visually.
5. Update `specs/baseline/subpulse-mvp.md` and archive this change folder to `specs/archive/`.
