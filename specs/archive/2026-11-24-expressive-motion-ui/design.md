# Design: Expressive, Emotional & Tactile Motion UI Overhaul

## 1. Visual Direction ("Warm Aurora & Tactile Glass")
- **Color & Surface**:
  - Subtle warm/cool ambient radial glows behind the top of primary screens (adaptive for both Light Mode & Dark Mode).
  - Elevated `24pt` continuous-corner cards with crisp hairline inner highlight strokes and soft tinted drop shadows instead of flat `insetGrouped` system rows.
  - Hero Spend Card: rich multi-stop deep indigo → royal blue → violet-cyan gradient with subtle animated ambient orb highlight, rounded tabular `.numericText()` animated spend figure, and daily coffee-equivalent emotional caption (`≈ $1.06/day • less than a coffee`).
- **Emotional Microcopy (EN + ZH-Hans)**:
  - **Mood Banner** on Overview dynamically reacts to user state:
    - Trial expiring ≤3 days: warm coral-amber glowing pill — *"Heads up! 1 free trial ends soon — don't get caught off guard."* / *"盯紧啦！有 1 个免费试用快到期，别被悄悄扣年费"*
    - Renewals within 7 days (no trial): upbeat indigo pill — *"2 renewals coming up this week — you're totally on top of it."* / *"本周有 2 笔续费，一切尽在掌握"*
    - All clear (0 due in 7 days): soothing mint-emerald pill — *"Smooth sailing ✨ Nothing bills in the next 7 days."* / *"安心躺平 ✨ 未来 7 天没有任何扣费"*

## 2. Motion & Tactile Architecture

### 2.1 Shared Design System (`SubPulse/Views/Components/DesignSystem.swift`)
- `AppMotion`: centralized spring tokens:
  - `snappy`: `.spring(response: 0.34, dampingFraction: 0.74)`
  - `bouncy`: `.spring(response: 0.44, dampingFraction: 0.66)`
  - `gentle`: `.spring(response: 0.55, dampingFraction: 0.82)`
- `BouncyButtonStyle`: tactile press-down scale (`0.96`) with spring rebound.
- `PulseDotView`: gentle breathing halo dot for active free trials & urgent alerts.
- `AmbientBackgroundView`: soft top ambient glow layer that gives depth without harming readability.
- `FloatingTabBar`: floating `.ultraThinMaterial` pill dock at the bottom with:
  - `matchedGeometryEffect(id: "activeTabPill", in: namespace)` liquid sliding highlight pill;
  - `.symbolEffect(.bounce, value: selectedTab)` on active icon;
  - `.sensoryFeedback(.selection, trigger: selectedTab)` tactile tick.

### 2.2 Screen-by-Screen Upgrades
1. **`ContentView.swift`**:
   - Replace default `TabView` with custom animated stage + `FloatingTabBar` overlay.
   - Smooth directional crossfade + subtle scale/offset spring transition when switching tabs (plus `safeAreaInset(edge: .bottom)` padding so scroll content glides cleanly behind the floating glass dock).
2. **`OverviewView.swift`**:
   - `ScrollView` with `.scrollBounceBehavior(.always)` and staggered entrance spring animation.
   - Dynamic Mood Banner + Aurora Hero Card (with `.contentTransition(.numericText())` + daily insight badge) + tactile 2-column glowing metric tiles + Upcoming Renewals cards + unblurred smooth Swift Charts card with `.scrollTransition` subtle jelly scaling.
3. **`SubscriptionListView.swift` & `SubscriptionRowView.swift`**:
   - Replace stiff `List` with custom `ScrollView` + `.scrollBounceBehavior(.always)` + `.scrollTransition` cards!
   - `SubscriptionRowView` becomes a tactile rounded card featuring:
     - Soft-glowing tinted app badge;
     - Breathing `PulseDotView` inside the `TRIAL` pill;
     - Sleek **renewal countdown progress bar** along the bottom edge of the card (color shifts from calm indigo → warm amber → coral red as due date approaches);
     - Quick action menu / inline swipe-or-context actions ("Mark Renewed" with bounce + haptic celebration, "Edit", "Delete").
   - Category filter bar with `matchedGeometryEffect` sliding capsule indicator and bouncy list filtering animation.
4. **`UpcomingView.swift`**:
   - Replace stiff `List` with custom `ScrollView` + `.scrollBounceBehavior(.always)` timeline cards, subtle vertical timeline accent indicator, `.scrollTransition` motion, and one-tap bouncy "Mark Renewed" button with celebratory haptic feedback.
5. **`PaywallView.swift`**:
   - Ambient glowing header with gentle breathing crown aura, animated plan selection border + subtle scale spring (`scaleEffect(isSelected ? 1.02 : 1.0)`), tactile gradient CTA button, while keeping 100% of Guideline 3.1.2 disclosures & links intact.
6. **`SettingsView.swift`**:
   - Keep clean iOS Settings readability while adding `.scrollBounceBehavior(.always)`, upgraded Pro gradient card banner, and bottom inset clearance for the floating glass tab bar.

## 3. Edge Cases & Verification Plan
- **Xcode Project File**: Register new `DesignSystem.swift` in `SubPulse.xcodeproj/project.pbxproj` (`PBXBuildFile`, `PBXFileReference`, `PBXGroup`, `PBXSourcesBuildPhase`).
- **Safe Area & Floating Dock**: Ensure all 4 tabs have sufficient bottom scroll padding (~100pt) so the last card/version row never gets hidden behind the floating glass tab bar.
- **Light & Dark Mode**: Verify readability and contrast of ambient glows, card backgrounds, and hairline borders.
- **Build & Visual Verification**:
  - `xcodebuild` 0 errors / 0 warnings;
  - Fresh install on `iPhone 16 Pro Max` simulator, visually verify all 5 screenshots (including Light & quick Dark check) and verify tab transitions & bounce interactively.
