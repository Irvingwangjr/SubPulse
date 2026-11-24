import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @Query(sort: \SubscriptionItem.nextBillingDate) private var items: [SubscriptionItem]

    @AppStorage("baseCurrencyCode") private var baseCurrencyCode: String = Currency.usd.rawValue
    @AppStorage("hasSeededDemoData") private var hasSeededDemoData: Bool = false

    @State private var selectedTab: AppTab = .overview
    @State private var previousTab: AppTab = .overview
    @State private var showingPaywall = false

    private var baseCurrency: Currency {
        Currency.from(code: baseCurrencyCode)
    }

    private var slideEdge: Edge {
        selectedTab.rawValue >= previousTab.rawValue ? .trailing : .leading
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .overview:
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
                case .subscriptions:
                    SubscriptionListView(
                        items: items,
                        baseCurrency: baseCurrency,
                        onShowPaywall: { showingPaywall = true }
                    )
                case .upcoming:
                    UpcomingView(
                        items: items,
                        baseCurrency: baseCurrency
                    )
                case .settings:
                    SettingsView(
                        items: items,
                        baseCurrencyCode: $baseCurrencyCode,
                        onShowPaywall: { showingPaywall = true }
                    )
                }
            }
            .id(selectedTab)
            .transition(
                .asymmetric(
                    insertion: .opacity
                        .combined(with: .move(edge: slideEdge))
                        .combined(with: .scale(scale: 0.985)),
                    removal: .opacity
                        .combined(with: .scale(scale: 0.985))
                )
            )
            .animation(AppMotion.snappy, value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $selectedTab)
                .zIndex(10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: selectedTab) { oldValue, _ in
            previousTab = oldValue
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environment(storeManager)
        }
        .task {
            seedDemoDataIfNeeded()
            await NotificationManager.shared.rescheduleAll(items)
        }
    }

    private func seedDemoDataIfNeeded() {
        guard !hasSeededDemoData else { return }
        hasSeededDemoData = true
        if items.isEmpty {
            for sample in ServicePreset.sampleItems() {
                modelContext.insert(sample)
            }
            try? modelContext.save()
        }
    }
}
