import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @Query(sort: \SubscriptionItem.nextBillingDate) private var items: [SubscriptionItem]

    @AppStorage("baseCurrencyCode") private var baseCurrencyCode: String = Currency.usd.rawValue
    @AppStorage("hasSeededDemoData") private var hasSeededDemoData: Bool = false

    @State private var selectedTab = 0
    @State private var showingPaywall = false

    private var baseCurrency: Currency {
        Currency.from(code: baseCurrencyCode)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewView(
                items: items,
                baseCurrency: baseCurrency,
                onShowPaywall: { showingPaywall = true }
            )
            .tabItem {
                Label(NSLocalizedString("tab.overview", comment: ""), systemImage: "chart.pie.fill")
            }
            .tag(0)

            SubscriptionListView(
                items: items,
                baseCurrency: baseCurrency,
                onShowPaywall: { showingPaywall = true }
            )
            .tabItem {
                Label(NSLocalizedString("tab.subscriptions", comment: ""), systemImage: "rectangle.stack.fill")
            }
            .tag(1)

            UpcomingView(
                items: items,
                baseCurrency: baseCurrency
            )
            .tabItem {
                Label(NSLocalizedString("tab.upcoming", comment: ""), systemImage: "calendar.badge.clock")
            }
            .tag(2)

            SettingsView(
                items: items,
                baseCurrencyCode: $baseCurrencyCode,
                onShowPaywall: { showingPaywall = true }
            )
            .tabItem {
                Label(NSLocalizedString("tab.settings", comment: ""), systemImage: "gearshape.fill")
            }
            .tag(3)
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
