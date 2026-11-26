import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @Query(sort: \SubscriptionItem.nextBillingDate) private var items: [SubscriptionItem]

    @AppStorage("baseCurrencyCode") private var baseCurrencyCode: String = Currency.usd.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var selectedTab: AppTab = .overview
    @State private var showingPaywall = false
    @State private var showingOnboardingReplay = false

    private var baseCurrency: Currency {
        Currency.from(code: baseCurrencyCode)
    }

    private var hasUrgentTrial: Bool {
        items.contains { $0.isTrial && $0.daysUntilRenewal <= 3 }
    }

    private var tabAccent: Color {
        switch selectedTab {
        case .overview: return hasUrgentTrial ? Color(hex: "#F97316") : Color(hex: "#4F46E5")
        case .subscriptions: return Color(hex: "#2563EB")
        case .upcoming: return Color(hex: "#F97316")
        case .settings: return Color(hex: "#6366F1")
        }
    }

    private var tabSecondaryAccent: Color {
        switch selectedTab {
        case .overview: return Color(hex: "#EC4899")
        case .subscriptions: return Color(hex: "#8B5CF6")
        case .upcoming: return Color(hex: "#6366F1")
        case .settings: return Color(hex: "#0EA5E9")
        }
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(
                    baseCurrency: baseCurrency,
                    existingCount: items.count,
                    onComplete: {
                        withAnimation(AppMotion.bouncy) {
                            hasCompletedOnboarding = true
                        }
                    }
                )
                .environment(storeManager)
                .transition(.opacity.combined(with: .scale(scale: 1.03)))
            } else {
                mainAppContent
                    .transition(.opacity)
            }
        }
        .animation(AppMotion.gentle, value: hasCompletedOnboarding)
    }

    private var mainAppContent: some View {
        ZStack(alignment: .bottom) {
            AmbientBackgroundView(
                accent: tabAccent,
                secondaryAccent: tabSecondaryAccent
            )
            .animation(.easeInOut(duration: 0.45), value: selectedTab)

            TabView(selection: $selectedTab) {
                OverviewView(
                    items: items,
                    baseCurrency: baseCurrency,
                    onShowPaywall: { showingPaywall = true },
                    onJumpToSubscriptions: {
                        withAnimation(AppMotion.bouncy) {
                            selectedTab = .subscriptions
                        }
                    }
                )
                .tag(AppTab.overview)

                SubscriptionListView(
                    items: items,
                    baseCurrency: baseCurrency,
                    onShowPaywall: { showingPaywall = true }
                )
                .tag(AppTab.subscriptions)

                UpcomingView(
                    items: items,
                    baseCurrency: baseCurrency
                )
                .tag(AppTab.upcoming)

                SettingsView(
                    items: items,
                    baseCurrencyCode: $baseCurrencyCode,
                    onShowPaywall: { showingPaywall = true },
                    onReplayOnboarding: { showingOnboardingReplay = true }
                )
                .tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(.container, edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $selectedTab)
                .zIndex(10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environment(storeManager)
        }
        .fullScreenCover(isPresented: $showingOnboardingReplay) {
            OnboardingView(
                baseCurrency: baseCurrency,
                existingCount: items.count,
                onComplete: {
                    showingOnboardingReplay = false
                }
            )
            .environment(storeManager)
        }
        .task {
            await NotificationManager.shared.rescheduleAll(items)
        }
    }
}
