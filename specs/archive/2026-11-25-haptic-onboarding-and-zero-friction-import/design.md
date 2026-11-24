# Design: Haptic Kinetic Onboarding & Zero-Friction Import

## 1. Cold-Launch Root Presentation (Zero Flash)
- On first launch (`!hasCompletedOnboarding`), `ContentView` renders `OnboardingView` directly as the root view instead of presenting a `.fullScreenCover` over `OverviewView`. This guarantees Frame 1 is the dark aurora splash with zero light-mode flash or bottom-sheet slide lag.
- Replaying onboarding from `SettingsView` uses `.fullScreenCover(isPresented: $showingOnboardingReplay)` and passes `existingCount: items.count` so replaying respects remaining free slots and never re-seeds demo items over existing data.

## 2. ChatGPT-Style Kinetic Typewriter + Taptic Rhythm
- Left-aligned editorial typewriter stage (`alignment: .topLeading`) with an inline solid white circle cursor (`Image(systemName: "circle.fill")`) riding right behind the trailing character and `animation(nil, value: typedText)` for zero ghosting or horizontal jitter.
- Exact 5-stage loop per phrase across 4 color-shifting aurora themes (`#38BDF8`, `#F97316`, `#34D399`, `#A78BFA`):
  1. **Cursor Intro Blink**: Solid white `●` blinks twice over `~1.0s` (`250ms` on / `250ms` off × 2).
  2. **Rapid Left-to-Right Type-Out**: Streams character-by-character (`34ms/char` EN, `60ms/char` ZH) with a pre-warmed `UIImpactFeedbackGenerator(.soft)` firing micro-haptics (`intensity: 0.58`) every 2 EN chars / every ZH char.
  3. **Reading Pause**: Holds full phrase for `~1.18s` with one gentle cursor breath.
  4. **Snappy Right-to-Left Retraction**: Erases character-by-character back to the lone cursor (`20ms/char` EN, `36ms/char` ZH) with softer retraction haptics (`intensity: 0.35`).
  5. **Aurora Theme Shift**: Smoothly cross-fades the ambient gradient & pulse badge to the next phrase accent.

## 3. On-Device Vision OCR & Clipboard Parser (`ScreenshotOCRParser`)
- Runs `VNRecognizeTextRequest` (`.accurate`, `usesLanguageCorrection = true`, `recognitionLanguages = ["en-US", "zh-Hans"]`) on a detached background task.
- Sorts text boxes top-to-bottom / left-to-right, extracts multi-currency amounts (`USD`, `EUR`, `GBP`, `JPY`, `CNY`, `CAD`, `AUD`, `HKD`, `SGD`), infers service names from neighboring lines (filtering Apple UI chrome strings in EN/ZH), detects billing cycle, free-trial keywords, and renewal dates via `NSDataDetector`, and enriches matching services with `ServicePreset` icons/colors.
- Uses `PhotosUI.PhotosPicker(matching: .images)` (out-of-process, zero photo permission dialog).
