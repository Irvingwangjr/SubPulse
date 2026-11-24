# Proposal: Swipe-to-Delete Subscription Cards

> **Date**: 2026-11-25  
> **Status**: Implemented & Archived

## Why
Custom `ScrollView` + `.tactileCard()` layouts gave SubPulse floating glass cards and 2-column iPhone Duo / iPad grids, but previously only supported deletion via long-press `.contextMenu`. Adding native-feeling left-swipe deletion makes removing unwanted subscriptions or finished trials effortless.

## What Changes
- Added reusable `SwipeToDeleteCard` container in `DesignSystem.swift`:
  - Light left swipe (`>= 43pt`, snapping to `86pt`) reveals a rounded red gradient **Delete** button with subtle selection haptic.
  - Deep full swipe (`>= 168pt`) triggers a crisp `.rigid` haptic pulse and deletes immediately upon release with smooth slide-off animation.
  - Single-row mutual exclusion via `@Binding var activeSwipeID: UUID?`.
- Wired `SwipeToDeleteCard` into `SubscriptionListView` and `UpcomingView`, ensuring deletion cancels pending local notifications and immediately saves SwiftData context.

## Non-Goals
- Does not replace `ScrollView` with `List` (preserves floating card aesthetics, `.scrollCardMotion()`, and Regular 2-column grids).
- Does not remove onboarding demo data seeding yet (deferred per user preference).
