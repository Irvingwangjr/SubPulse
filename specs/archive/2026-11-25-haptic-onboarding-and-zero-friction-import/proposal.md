# Proposal: Haptic Kinetic Onboarding & Zero-Friction Subscription Import

> **Date**: 2026-11-25  
> **Status**: Implemented & Archived

## Why
1. **First-Impression & Activation**: Cold-launching straight into a dense dashboard feels abrupt; adding a ChatGPT-style kinetic word-by-word welcome screen synchronized with soft Taptic Engine haptics establishes a premium, tactile feel in the first 3 seconds.
2. **Eliminate Manual Entry Friction**: Users drop off when forced to manually type service names, prices, currencies, and renewal dates. Apple iOS does not expose a third-party API to read another app's Apple ID subscriptions (`StoreKit` only sees SubPulse's own IAPs). We bridge that gap without sacrificing our 100% on-device privacy ("Data Not Collected") positioning.

## What Changes
1. **3-Page Swipeable Haptic Onboarding (`OnboardingView`)**:
   - **Page 0 — Kinetic Haptic Splash**: Dark aurora canvas with breathing pulse emblem, color-shifting accents across 3 rotating statements, stable-layout `AttributedString` word/chunk-by-chunk reveal synced 1:1 with `UIImpactFeedbackGenerator(.soft)` ticks (zero ghosting/jitter).
   - **Page 1 — 5-Second Popular Services Icon Wall**: 3-column bouncy grid of 12 popular presets (`ChatGPT Plus`, `Claude Pro`, `iCloud+`, `Netflix`, `Spotify`, `YouTube`, etc.) with live rolling monthly spend total and 3-subscription free-tier quota guard.
   - **Page 2 — Apple Subscriptions Deep Link + On-Device Vision OCR + Notifications**: One-tap jump to `itms-apps://apps.apple.com/account/subscriptions`, out-of-process `PhotosPicker` screenshot import, on-device Apple Vision OCR candidate review, privacy reassurance card, and notification permission prompt on launch.
2. **Reusable Smart Import Sheet (`SmartImportView`) & On-Device OCR Engine (`ScreenshotOCRParser`)**:
   - Accessible anytime via the `Quick / Scan` pill in `SubscriptionListView` (both expanded header, collapsed `CollapsingTopBar`, and empty state).
   - Supports **Quick Pick Wall**, **Screenshot Vision OCR** (`en-US` + `zh-Hans`), and **Clipboard Receipt Text Parsing** (`UIPasteboard`).
3. **Settings Shortcuts**:
   - Added **Open Apple Subscriptions** deep link and **Replay Welcome & Quick Setup** (`fullScreenCover`) in `SettingsView`.
4. **Full Dual Localization (`en` + `zh-Hans`)**:
   - Complete English and Simplified Chinese copy, using `|`-delimited kinetic chunks in Chinese so Taptic beats align naturally without awkward spaces.

## Non-Goals
- No third-party bank account aggregation (Plaid) or email inbox OAuth scraping (preserves 100% on-device "Data Not Collected" App Store privacy nutrition label).
- No `NSPhotoLibraryUsageDescription` prompt (uses iOS out-of-process `PhotosPicker`).
