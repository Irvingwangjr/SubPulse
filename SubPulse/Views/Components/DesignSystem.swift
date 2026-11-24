import SwiftUI
import UIKit

// MARK: - App Tabs

enum AppTab: Int, CaseIterable, Identifiable {
    case overview = 0
    case subscriptions = 1
    case upcoming = 2
    case settings = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .overview: return NSLocalizedString("tab.overview", comment: "")
        case .subscriptions: return NSLocalizedString("tab.subscriptions", comment: "")
        case .upcoming: return NSLocalizedString("tab.upcoming", comment: "")
        case .settings: return NSLocalizedString("tab.settings", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .overview: return "chart.pie.fill"
        case .subscriptions: return "rectangle.stack.fill"
        case .upcoming: return "calendar.badge.clock"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Centralized Spring Motion Tokens

enum AppMotion {
    static let snappy = Animation.spring(response: 0.34, dampingFraction: 0.74)
    static let bouncy = Animation.spring(response: 0.44, dampingFraction: 0.64)
    static let gentle = Animation.spring(response: 0.56, dampingFraction: 0.82)
}

// MARK: - Tactile Bouncy Button Style

struct BouncyButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(AppMotion.bouncy, value: configuration.isPressed)
    }
}

// MARK: - Breathing Pulse Dot (Free Trials & Urgent Alerts)

struct PulseDotView: View {
    let color: Color
    var size: CGFloat = 7
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.45))
                .frame(width: size, height: size)
                .scaleEffect(pulsing ? 2.1 : 1.0)
                .opacity(pulsing ? 0.0 : 0.7)
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulsing = true
            }
        }
    }
}

// MARK: - Soft Ambient Aurora Background

struct AmbientBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    var accent: Color = Color(hex: "#4F46E5")
    var secondaryAccent: Color = Color(hex: "#EC4899")

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(accent.opacity(colorScheme == .dark ? 0.24 : 0.13))
                        .frame(width: geo.size.width * 0.95, height: geo.size.width * 0.95)
                        .blur(radius: 75)
                        .offset(x: -geo.size.width * 0.28, y: -geo.size.height * 0.16)

                    Circle()
                        .fill(secondaryAccent.opacity(colorScheme == .dark ? 0.18 : 0.09))
                        .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                        .blur(radius: 80)
                        .offset(x: geo.size.width * 0.34, y: -geo.size.height * 0.06)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Tactile Elevated Card Modifier & Scroll Transition

struct TactileCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.045),
                        lineWidth: 0.75
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.055),
                radius: 14,
                x: 0,
                y: 6
            )
    }
}

extension View {
    func tactileCard(cornerRadius: CGFloat = 24, padding: CGFloat = 18) -> some View {
        modifier(TactileCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func scrollCardMotion() -> some View {
        self.scrollTransition(.interactive, axis: .vertical) { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1.0 : 0.965)
                .opacity(phase.isIdentity ? 1.0 : 0.86)
                .offset(y: phase.value * 8)
        }
    }
}

// MARK: - Scroll Distance Tracking & Collapsing Sticky Top Bar

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// Tracks positive downward scroll distance (0 at top, >0 as content scrolls upward).
    /// Uses native iOS 18 `onScrollGeometryChange` with an iOS 17 `.scrollView` coordinate space fallback.
    @ViewBuilder
    func onScrollDistanceChange(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            self.onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, newDistance in
                onChange(newDistance)
            }
        } else {
            self.onPreferenceChange(ScrollOffsetPreferenceKey.self) { minY in
                onChange(-minY)
            }
        }
    }

    @ViewBuilder
    func trackLegacyScrollOffset() -> some View {
        if #available(iOS 18.0, *) {
            self
        } else {
            self.background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .scrollView).minY
                    )
                }
            )
        }
    }
}

struct CollapsingTopBar<Badge: View, Trailing: View>: View {
    let title: String
    let barProgress: CGFloat
    let badgeProgress: CGFloat
    var maxWidth: CGFloat = 960
    let onTapToTop: () -> Void
    @ViewBuilder let badge: () -> Badge
    @ViewBuilder let trailing: () -> Trailing

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onTapToTop) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    badge()
                        .opacity(Double(badgeProgress))
                        .scaleEffect(0.88 + 0.12 * badgeProgress, anchor: .leading)
                        .offset(y: (1 - badgeProgress) * 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            trailing()
        }
        .frame(height: 46)
        .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 18)
        .frame(maxWidth: horizontalSizeClass == .regular ? maxWidth : .infinity)
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Color(.systemGroupedBackground)
                        .opacity(colorScheme == .dark ? 0.35 : 0.55)
                )
                .ignoresSafeArea(edges: .top)
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08))
                .frame(height: 0.5)
        }
        .opacity(Double(barProgress))
        .offset(y: (1 - barProgress) * -6)
        .allowsHitTesting(barProgress > 0.25)
    }
}

func clampedScrollProgress(distance: CGFloat, start: CGFloat, range: CGFloat) -> CGFloat {
    min(1, max(0, (distance - start) / max(1, range)))
}

// MARK: - Floating Translucent Glass Tab Bar

struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var pillNamespace
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    guard selectedTab != tab else { return }
                    withAnimation(AppMotion.bouncy) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                            .symbolEffect(.bounce, value: isSelected)
                            .scaleEffect(isSelected ? 1.08 : 0.96)

                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                    }
                    .foregroundStyle(isSelected ? Color.white : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 4)
                    .contentShape(Capsule())
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#2563EB"), Color(hex: "#6366F1")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(hex: "#4F46E5").opacity(0.35), radius: 8, y: 3)
                                .matchedGeometryEffect(id: "activeTabPill", in: pillNamespace)
                        }
                    }
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.92))
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(6)
        .frame(maxWidth: horizontalSizeClass == .regular ? 440 : .infinity)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.75),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.14),
            radius: 22,
            x: 0,
            y: 10
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

// MARK: - Swipe-to-Delete Card Container (ScrollView-Friendly)

struct SwipeToDeleteCard<Content: View>: View {
    let itemID: UUID
    var cornerRadius: CGFloat = 22
    @Binding var activeSwipeID: UUID?
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var isHorizontalDrag: Bool?
    @State private var didFireFullSwipeHaptic = false
    @State private var isDeleting = false

    private let revealWidth: CGFloat = 86
    private let fullSwipeThreshold: CGFloat = 168

    private var deleteButtonWidth: CGFloat {
        max(revealWidth, -offset - 10)
    }

    private var revealProgress: Double {
        min(1.0, max(0.0, Double(-offset) / 44.0))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if offset < -2 || isDeleting {
                Button(role: .destructive) {
                    performDelete()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .bold))
                            .scaleEffect(offset <= -fullSwipeThreshold ? 1.18 : 1.0)
                        Text(NSLocalizedString("action.delete", comment: ""))
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: deleteButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FF453A"), Color(hex: "#DC2626")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
                    .opacity(revealProgress)
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.22, dampingFraction: 0.72), value: offset <= -fullSwipeThreshold)
            }

            content()
                .overlay {
                    if offset < -4 {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                closeSwipe()
                            }
                    }
                }
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 14, coordinateSpace: .local)
                        .onChanged { value in
                            let dx = value.translation.width
                            let dy = value.translation.height

                            if isHorizontalDrag == nil {
                                if abs(dx) > abs(dy) * 1.25 {
                                    isHorizontalDrag = true
                                    dragStartOffset = offset
                                    if activeSwipeID != itemID {
                                        activeSwipeID = itemID
                                    }
                                } else {
                                    isHorizontalDrag = false
                                    return
                                }
                            }

                            guard isHorizontalDrag == true else { return }

                            var proposed = dragStartOffset + dx
                            if proposed > 0 {
                                proposed = 0
                            } else if proposed < -240 {
                                proposed = -240 + (proposed + 240) * 0.25
                            }

                            offset = proposed

                            if proposed <= -fullSwipeThreshold && !didFireFullSwipeHaptic {
                                didFireFullSwipeHaptic = true
                                let gen = UIImpactFeedbackGenerator(style: .rigid)
                                gen.prepare()
                                gen.impactOccurred(intensity: 0.95)
                            } else if proposed > -fullSwipeThreshold && didFireFullSwipeHaptic {
                                didFireFullSwipeHaptic = false
                                let gen = UIImpactFeedbackGenerator(style: .soft)
                                gen.impactOccurred(intensity: 0.6)
                            }
                        }
                        .onEnded { value in
                            defer { isHorizontalDrag = nil }
                            guard isHorizontalDrag == true else { return }

                            let predictedX = dragStartOffset + value.predictedEndTranslation.width
                            if offset <= -fullSwipeThreshold || (offset <= -118 && predictedX <= -220) {
                                performDelete()
                            } else if offset <= -revealWidth * 0.5 || (dragStartOffset == 0 && predictedX <= -revealWidth) {
                                withAnimation(AppMotion.snappy) {
                                    offset = -revealWidth
                                    activeSwipeID = itemID
                                }
                                UISelectionFeedbackGenerator().selectionChanged()
                            } else {
                                closeSwipe()
                            }
                            didFireFullSwipeHaptic = false
                        }
                )
        }
        .onChange(of: activeSwipeID) { _, newID in
            if newID != itemID && offset != 0 && !isDeleting {
                withAnimation(AppMotion.snappy) {
                    offset = 0
                }
            }
        }
    }

    private func closeSwipe() {
        withAnimation(AppMotion.snappy) {
            offset = 0
            if activeSwipeID == itemID {
                activeSwipeID = nil
            }
        }
    }

    private func performDelete() {
        guard !isDeleting else { return }
        isDeleting = true
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        withAnimation(AppMotion.snappy) {
            offset = -420
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 140_000_000)
            if activeSwipeID == itemID {
                activeSwipeID = nil
            }
            onDelete()
        }
    }
}
