# Design: Collapsing Sticky Glass Top Bar with Compact Summary

## 1. Scroll-Driven Collapsing Mechanics (`DesignSystem.swift`)
- **`ScrollOffsetPreferenceKey`**:
  - Tracks `minY` of an invisible `0pt` probe inside each `ScrollView` in a named coordinate space (`"subpulse.scroll"`).
  - Normalized collapse progress:
    - `barProgress = clamp((-offset - 16) / 40, 0, 1)` → smoothly fades in the frosted `.ultraThinMaterial` top bar & hairline bottom divider as soon as scrolling begins (so content *never* hits bare status bar!).
    - `summaryProgress = clamp((-offset - 60) / 50, 0, 1)` (on Overview, timed right as the Hero card scrolls past the top) → smoothly scales & fades in the compact `$31.95/mo` summary pill (`scale: 0.92 → 1.0`, `offsetY: 6 → 0`, `opacity: 0 → 1`)!
- **`CollapsingTopBar<CenterContent, TrailingContent>`**:
  - Anchored via `.safeAreaInset(edge: .top, spacing: 0)` OR `.overlay(alignment: .top)` with `.ignoresSafeArea(edges: .top)`:
    - Actually, using `.overlay(alignment: .top)` with `GeometryReader` safe-area height (`topInset + 48`) ensures the `ScrollView` does **not** jump/shift height while the bar fades in!
    - Inside the `48pt` bar below `topInset`:
      - Leading: Compact rounded bold page title (`17pt` semibold/bold)
      - Center / Inline badge: Compact summary pill (e.g., `$31.95/mo` on Overview, `2 / 3` on Subscriptions, `$31.95` due on Upcoming)
      - Trailing: Compact interactive action button (`Pro` mini capsule or `+` mini circle button)
    - Tapping the bar smoothly scrolls back to top (`withAnimation(AppMotion.bouncy) { scrollProxy.scrollTo("scrollTop", anchor: .top) }`)!
    - Hit-testing is enabled ONLY when `barProgress > 0.25` so it never intercepts touches on the large header when at rest!

## 2. Per-Screen Collapsed Bar Content

| Screen | Title | Compact Summary Pill | Trailing Action |
| --- | --- | --- | --- |
| **Overview** | `SubPulse` | `$31.95/mo` (electric indigo pill, `.numericText()`) | Mini `👑 Pro` pill (if free) |
| **Subscriptions** | `Subscriptions` | `2 / 3` (free) or `4 plans` (Pro) | Mini gradient `+` button |
| **Upcoming** | `Upcoming` | `$31.95` (amber pill for 7-day subtotal) | — |
| **Settings** | `Settings` | `Pro` badge (if Pro) | Mini `👑 Pro` pill (if free) |

## 3. Edge Cases & Polish
- **Overscroll Pull-Down (`offset > 0`)**: `barProgress == 0`, top bar stays completely invisible so rubber-band pull-down feels completely airy and unobstructed!
- **Hero Scroll Collision**: Because `barProgress` reaches `1.0` after just `56pt` of upward scroll (before the Hero card even reaches the status bar!), scrolled cards always pass cleanly behind a crisp frosted bar — ZERO overlap with `09:41` or Dynamic Island.
- **iPhone Duo Regular (7.6" unfolded)**: Inner content inside `CollapsingTopBar` respects the same `maxWidth: 960` (or `880` on Settings) centered alignment as the page body, while the frosted material spans full edge-to-edge width.

## 4. Verification Plan
1. `xcodebuild` builds cleanly with 0 errors / 0 warnings.
2. On `iPhone 16 Pro Max` simulator:
   - Verify at-rest Overview looks identical and airy (no bar visible);
   - Scroll Overview upward and capture a live scrolled screenshot verifying the crisp frosted top bar showing `SubPulse` + `$31.95/mo` + `Pro`, with Hero card cleanly tucked behind the translucent bar and zero `09:41` collision!
   - Verify tap-to-scroll-to-top and `+` button accessibility in the collapsed Subscriptions bar.
3. Sync `specs/baseline/subpulse-mvp.md`, archive, and push to GitHub.
