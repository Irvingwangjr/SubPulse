# SubPulse — Multi-Currency Subscription & Renewal Tracker (iOS)

A clean, zero-backend, privacy-first iOS utility app built with **SwiftUI + SwiftData + StoreKit 2 + Swift Charts**, designed to be ready for overseas App Store launch.

## Why This App?

- **Real overseas pain point**: Track recurring subscriptions & free trials across multiple currencies (USD, EUR, GBP, JPY, etc.) with automatic base-currency conversion and local renewal reminders.
- **Zero backend & minimal privacy friction**: 100% on-device storage via `SwiftData` — qualifies for **"Data Not Collected"** in App Store Privacy Nutrition Labels.
- **Complete StoreKit 2 subscription loop**:
  - **Free tier**: Up to 5 subscriptions, multi-currency conversion, 1-day renewal reminders, monthly/yearly totals.
  - **Pro tier** (`$2.99/mo` or `$19.99/yr` with 7-day free trial): Unlimited subscriptions, custom advance reminder alerts (3 / 7 / 14 days), full Swift Charts spending breakdown, CSV export.
- **Ready-to-test locally**: Pre-wired with `SubPulse.storekit` in the shared Xcode scheme so you can test purchases, free trials, and Restore Purchases directly in the iOS Simulator without setting up App Store Connect first.

## Quick Start

1. Open `SubPulse.xcodeproj` in **Xcode 16+**.
2. Select an iOS 17+ Simulator (e.g., iPhone 16) and press **⌘R** to run.
3. Go to **Settings → Upgrade to Pro** to test StoreKit 2 purchases locally via `SubPulse.storekit`.
4. To deploy your compliance pages (Privacy Policy / Terms / Support), publish the `docs/` folder to GitHub Pages or Cloudflare Pages.
5. Follow `LAUNCH_CHECKLIST.md` step-by-step to submit to the overseas App Store.

## SwiftUI ↔ Flutter / Jetpack Compose Cheat Sheet

If you come from **Android (Compose)** or **Flutter**, this codebase maps directly to concepts you already know:

| SwiftUI (This Project) | Flutter | Jetpack Compose |
| --- | --- | --- |
| `VStack` / `HStack` / `ZStack` | `Column` / `Row` / `Stack` | `Column` / `Row` / `Box` |
| `@State` | `StatefulWidget` + `setState` | `remember { mutableStateOf(...) }` |
| `@Observable` + `@Environment` | `ChangeNotifier` + `Provider` | `ViewModel` + `CompositionLocal` |
| `@Query` (SwiftData) | `StreamBuilder` over Isar/Drift | `Flow` / Room `collectAsState` |
| `NavigationStack` + `.sheet` | `Navigator` + `showModalBottomSheet` | `NavHost` + `ModalBottomSheet` |
| `StoreManager` (StoreKit 2) | `in_app_purchase` / RevenueCat | Google Play Billing Library |
| `Localizable.strings` | ARB / `intl` | `strings.xml` |

## Project Layout

```text
SubPulse/
├── SubPulse.xcodeproj/          # Xcode 16 project + shared scheme with StoreKit config
├── SubPulse/
│   ├── Models/                  # SwiftData models, currencies, popular service presets
│   ├── Services/                # StoreKit 2, local notifications, CSV export
│   ├── Views/                   # Overview, Subscriptions, Upcoming, Paywall, Settings
│   └── Resources/               # SubPulse.storekit + en / zh-Hans localization
├── docs/                        # Static Privacy Policy, Terms of Service, Support site
└── LAUNCH_CHECKLIST.md          # Step-by-step overseas App Store submission playbook
```
