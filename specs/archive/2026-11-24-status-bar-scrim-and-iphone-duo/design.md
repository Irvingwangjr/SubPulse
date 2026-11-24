# Design: Top Safe-Area Scroll Fade & iPhone Duo Adaptive Layout

## 1. Status Bar & Dynamic Island Overlap Fix (`TopSafeAreaScrim`)
- **Problem**: Custom `ScrollView` screens have no opaque navigation bar; scrolling content slides underneath the system status bar (`09:41`, Dynamic Island, signal/battery) and collides visually.
- **Design**:
  - Add `.topSafeAreaScrim()` ViewModifier in `DesignSystem.swift`:
    - Uses `GeometryReader` (or `.safeAreaInset(edge: .top, spacing: 0)`) + an `ignoresSafeArea(edges: .top)` overlay pinned to `.top` with height `safeAreaTop + 18`:
      - Top `safeAreaTop` band: `.ultraThinMaterial` masked with a vertical linear gradient (`alpha 1.0` from `0...72%`, smoothly fading to `0.0` by `100%`) plus a subtle `Color(.systemGroupedBackground)` top wash (`0.82 → 0.0`).
      - `.allowsHitTesting(false)` so scroll-to-top tap and touch gestures remain unaffected.
  - Result: At rest, the ambient aurora softly shines through; when scrolling up, cards dissolve cleanly *before* crossing `09:41` and the Dynamic Island.

## 2. iPhone Duo Dual-Screen Adaptive Layout (`5.4"` Compact ↔ `7.6"` Regular)

| Screen | Compact (`5.4"` Outer / Standard iPhone) | Regular (`7.6"` Inner Unfolded / iPad) |
| --- | --- | --- |
| `FloatingTabBar` | Full width (`horizontal: 18pt`), compact `minimumScaleFactor(0.8)` for 5.4" narrow outer screens | Centered pill constrained to `maxWidth: 440` |
| `OverviewView` | Single-column vertical stack | Header + Mood Banner full-width (`maxWidth: 960`), followed by **2-column split (`spacing: 24`, hinge-safe center gutter)**: Left = Hero Card + Metric Tiles; Right = Upcoming Renewals + Category Chart |
| `SubscriptionListView` | Single-column `LazyVStack` | Header + Search + Free Quota bar full-width, subscription cards in **2-column `LazyVGrid` (`spacing: 20`)** so cards sit cleanly on either side of the center hinge |
| `UpcomingView` | Single-column timeline cards | Section groups render cards in **2-column `LazyVGrid` (`spacing: 20`)** |
| `SettingsView` | Single-column stacked cards | Pro Banner full-width (`maxWidth: 880`), Preferences + Data side-by-side (`2-column`), Legal card cleanly aligned below |

## 3. Narrow Outer Display (`5.4"`) Polish
- Ensure `OverviewView` Hero card coffee pill uses `.lineLimit(1)` + `.minimumScaleFactor(0.82)`.
- Ensure `FloatingTabBar` labels use `.minimumScaleFactor(0.8)` and tighter horizontal padding (`4pt`) so 4 tabs never truncate on narrow outer widths.
- Ensure `SubscriptionListView` Free Quota banner never squeezes the `Upgrade` capsule button on narrow screens.

## 4. Verification Plan
1. `xcodebuild` builds cleanly with 0 errors / 0 warnings.
2. **iPhone 16 Pro Max** simulator: scroll Overview upward and verify `$31.95` fades cleanly behind the status bar scrim without colliding with `09:41` or Dynamic Island.
3. **iPhone SE (3rd gen)** simulator (compact narrow proxy for 5.4" outer screen): verify zero clipping in Hero card, rows, and FloatingTabBar.
4. **iPad mini (A17 Pro)** simulator (regular ~8.3" proxy for 7.6" unfolded inner screen): verify 2-column hinge-safe layouts on Overview / Subscriptions / Upcoming / Settings and centered FloatingTabBar.
5. Refresh 6.9-inch screenshots, sync `specs/baseline/subpulse-mvp.md`, archive, and push to GitHub.
