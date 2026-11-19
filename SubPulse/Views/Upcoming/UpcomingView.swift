import SwiftUI

struct UpcomingView: View {
    let items: [SubscriptionItem]
    let baseCurrency: Currency

    private var sortedItems: [SubscriptionItem] {
        items.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    private var dueSoonItems: [SubscriptionItem] {
        sortedItems.filter { $0.daysUntilRenewal <= 7 }
    }

    private var thisMonthItems: [SubscriptionItem] {
        sortedItems.filter { $0.daysUntilRenewal > 7 && $0.daysUntilRenewal <= 30 }
    }

    private var laterItems: [SubscriptionItem] {
        sortedItems.filter { $0.daysUntilRenewal > 30 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedItems.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("upcoming.empty_title", comment: ""),
                        systemImage: "calendar.badge.checkmark",
                        description: Text(NSLocalizedString("upcoming.empty_desc", comment: ""))
                    )
                } else {
                    List {
                        if !dueSoonItems.isEmpty {
                            sectionView(
                                title: NSLocalizedString("upcoming.section_7days", comment: ""),
                                list: dueSoonItems
                            )
                        }
                        if !thisMonthItems.isEmpty {
                            sectionView(
                                title: NSLocalizedString("upcoming.section_30days", comment: ""),
                                list: thisMonthItems
                            )
                        }
                        if !laterItems.isEmpty {
                            sectionView(
                                title: NSLocalizedString("upcoming.section_later", comment: ""),
                                list: laterItems
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(NSLocalizedString("tab.upcoming", comment: ""))
        }
    }

    private func sectionView(title: String, list: [SubscriptionItem]) -> some View {
        let subtotal = list.reduce(0.0) { $0 + $1.currency.convert($1.amount, to: baseCurrency) }
        return Section {
            ForEach(list) { item in
                HStack {
                    SubscriptionRowView(item: item, baseCurrency: baseCurrency)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        item.advanceBillingDate()
                        Task {
                            await NotificationManager.shared.scheduleReminder(for: item)
                        }
                    } label: {
                        Label(NSLocalizedString("action.mark_paid", comment: ""), systemImage: "checkmark.circle.fill")
                    }
                    .tint(.green)
                }
            }
        } header: {
            HStack {
                Text(title)
                Spacer()
                Text(baseCurrency.formatted(subtotal))
                    .font(.caption.weight(.semibold))
            }
        }
    }
}
