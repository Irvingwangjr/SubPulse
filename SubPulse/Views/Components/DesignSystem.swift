import SwiftUI

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

    func topSafeAreaScrim() -> some View {
        modifier(TopSafeAreaScrimModifier())
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

// MARK: - Top Safe-Area Progressive Frosted Scrim (Status Bar & Dynamic Island)

struct TopSafeAreaScrimModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let topInset = proxy.safeAreaInsets.top
                    VStack(spacing: 0) {
                        ZStack {
                            Rectangle()
                                .fill(.regularMaterial)
                                .mask(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .black, location: 0.0),
                                            .init(color: .black, location: 0.74),
                                            .init(color: .clear, location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            LinearGradient(
                                stops: [
                                    .init(color: Color(.systemGroupedBackground).opacity(colorScheme == .dark ? 0.96 : 0.94), location: 0.0),
                                    .init(color: Color(.systemGroupedBackground).opacity(colorScheme == .dark ? 0.82 : 0.78), location: 0.68),
                                    .init(color: Color(.systemGroupedBackground).opacity(0.0), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .frame(height: max(topInset, 20) + 18)
                        Spacer(minLength: 0)
                    }
                    .offset(y: -topInset)
                }
                .allowsHitTesting(false)
            }
    }
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
