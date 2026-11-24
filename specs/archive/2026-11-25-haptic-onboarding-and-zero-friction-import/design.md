# Design: Haptic Kinetic Onboarding & Zero-Friction Import

## 1. Cold-Launch Root Presentation (Zero Flash)
- On first launch (`!hasCompletedOnboarding`), `ContentView` renders `OnboardingView` directly as the root view instead of presenting a `.fullScreenCover` over `OverviewView`. This guarantees Frame 1 is the dark aurora splash with zero light-mode flash or bottom-sheet slide lag.
- Replaying onboarding from `SettingsView` uses `.fullScreenCover(isPresented: $showingOnboardingReplay)` and passes `existingCount: items.count` so replaying respects remaining free slots and never re-seeds demo items over existing data.

## 2. Ghost-Free Kinetic Typography + Taptic Rhythm
- Early iteration using `.contentTransition(.interpolate)` caused double-vision ghosting because centered text shifted horizontally as words appended.
- Replaced with a fixed-layout `AttributedString` (`kineticAttributedText`): every token in the active phrase occupies its final position from tick 1; tokens `< visibleWordCount` render in `.white`, remaining tokens render in `.clear`.
- Synchronized `180ms` loop triggers `UIImpactFeedbackGenerator(style: .soft)` on every token and subtly pulses the glowing center emblem (`scaleEffect` spring).
- Localization tokenizing: strings containing `|` split on `|` and join with `""` (native Chinese chunk cadence); otherwise split on `" "` and join with `" "` (English word cadence).

## 3. On-Device Vision OCR & Clipboard Parser (`ScreenshotOCRParser`)
- Runs `VNRecognizeTextRequest` (`.accurate`, `usesLanguageCorrection = true`, `recognitionLanguages = ["en-US", "zh-Hans"]`) on a detached background task.
- Sorts text boxes top-to-bottom / left-to-right, extracts multi-currency amounts (`USD`, `EUR`, `GBP`, `JPY`, `CNY`, `CAD`, `AUD`, `HKD`, `SGD`), infers service names from neighboring lines (filtering Apple UI chrome strings in EN/ZH), detects billing cycle, free-trial keywords, and renewal dates via `NSDataDetector`, and enriches matching services with `ServicePreset` icons/colors.
- Uses `PhotosUI.PhotosPicker(matching: .images)` (out-of-process, zero photo permission dialog).
