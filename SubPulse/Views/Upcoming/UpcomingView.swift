import SwiftUI

struct UpcomingView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let items: [SubscriptionItem]
    let baseCurrency: Currency

    @State private var renewTick = 0

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
        ZStack {
            AmbientBackgroundView(
                accent: Color(hex: "#F97316"),
                secondaryAccent: Color(hex: "#6366F1")
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("tab.upcoming", comment: ""))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text(NSLocalizedString("upcoming.subtitle", comment: ""))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if sortedItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 36))
                                .foregroundStyle(.green)
                            Text(NSLocalizedString("upcoming.empty_title", comment: ""))
                                .font(.headline.weight(.bold))
                            Text(NSLocalizedString("upcoming.empty_desc", comment: ""))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .tactileCard(cornerRadius: 24, padding: 30)
                        .padding(.top, 16)
                    } else {
                        if !dueSoonItems.isEmpty {
                            sectionBlock(
                                title: NSLocalizedString("upcoming.section_7days", comment: ""),
                                tint: Color(hex: "#F97316"),
                                list: dueSoonItems
                            )
                        }
                        if !thisMonthItems.isEmpty {
                            sectionBlock(
                                title: NSLocalizedString("upcoming.section_30days", comment: ""),
                                tint: Color(hex: "#4F46E5"),
                                list: thisMonthItems
                            )
                        }
                        if !laterItems.isEmpty {
                            sectionBlock(
                                title: NSLocalizedString("upcoming.section_later", comment: ""),
                                tint: Color(hex: "#10B981"),
                                list: laterItems
                            )
                        }
                    }

                    Spacer().frame(height: 92)
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 960 : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 18)
                .padding(.top, 10)
            }
            .scrollBounceBehavior(.always)
        }
        .topSafeAreaScrim()
        .sensoryFeedback(.success, trigger: renewTick)
    }

    private func sectionBlock(title: String, tint: Color, list: [SubscriptionItem]) -> some View {
        let subtotal = list.reduce(0.0) { $0 + $1.currency.convert($1.amount, to: baseCurrency) }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 7) {
                    Circle()
                        .fill(tint)
                        .frame(width: 8, height: 8)
                    Text(title.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(baseCurrency.formatted(subtotal))
                    .font(.caption.weight(.bold))
                    .contentTransition(.numericText(value: subtotal))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.12), in: Capsule())
                    .foregroundStyle(tint)
            }

            if horizontalSizeClass == .regular {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ],
                    spacing: 14
                ) {
                    ForEach(list) { item in
                        upcomingItemCard(item)
                    }
                }
                .animation(AppMotion.bouncy, value: list.map(\.id))
            } else {
                VStack(spacing: 12) {
                    ForEach(list) { item in
                        upcomingItemCard(item)
                    }
                }
                .animation(AppMotion.bouncy, value: list.map(\.id))
            }
        }
    }

    private func upcomingItemCard(_ item: SubscriptionItem) -> some View {
        VStack(spacing: 12) {
            SubscriptionRowView(item: item, baseCurrency: baseCurrency, showProgressBar: true)

            HStack {
                Spacer()
                Button {
                    withAnimation(AppMotion.bouncy) {
                        item.advanceBillingDate()
                        renewTick += 1
                    }
                    Task {
                        await NotificationManager.shared.scheduleReminder(for: item)
                    }
                } label: {
                    Label(NSLocalizedString("action.mark_paid", comment: ""), systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "#10B981"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#10B981").opacity(0.12), in: Capsule())
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.92))
            }
        }
        .tactileCard(cornerRadius: 22, padding: 16)
        .scrollCardMotion()
    }
}
