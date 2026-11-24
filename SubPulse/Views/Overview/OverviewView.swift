import Charts
import SwiftUI

struct OverviewView: View {
    @Environment(StoreManager.self) private var storeManager

    let items: [SubscriptionItem]
    let baseCurrency: Currency
    let onShowPaywall: () -> Void

    private var monthlyTotal: Double {
        items.reduce(0) { $0 + $1.monthlyAmount(in: baseCurrency) }
    }

    private var yearlyTotal: Double {
        items.reduce(0) { $0 + $1.yearlyAmount(in: baseCurrency) }
    }

    private var trialCount: Int {
        items.filter(\.isTrial).count
    }

    private var dueWithin7Days: [SubscriptionItem] {
        items
            .filter { $0.daysUntilRenewal <= 7 }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    private var categoryBreakdown: [(category: SubscriptionCategory, monthlyTotal: Double)] {
        let grouped = Dictionary(grouping: items, by: \.category)
        return grouped
            .map { category, list in
                (category, list.reduce(0) { $0 + $1.monthlyAmount(in: baseCurrency) })
            }
            .filter { $0.monthlyTotal > 0 }
            .sorted { $0.monthlyTotal > $1.monthlyTotal }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroSummaryCard
                    quickStatsRow
                    upcomingAlertCard
                    categoryChartCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SubPulse")
            .toolbar {
                if !storeManager.isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: onShowPaywall) {
                            Label("Pro", systemImage: "crown.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(.orange)
                    }
                }
            }
        }
    }

    private var heroSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(NSLocalizedString("overview.monthly_spend", comment: ""))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("\(baseCurrency.flag) \(baseCurrency.rawValue)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.18), in: Capsule())
                    .foregroundStyle(.white)
            }

            Text(baseCurrency.formatted(monthlyTotal))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Divider()
                .overlay(.white.opacity(0.25))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("overview.yearly_projection", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(baseCurrency.formatted(yearlyTotal))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(NSLocalizedString("overview.active_subs", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("\(items.count)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1D4ED8"), Color(hex: "#4F46E5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .shadow(color: Color(hex: "#1D4ED8").opacity(0.22), radius: 12, y: 6)
    }

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            metricTile(
                title: NSLocalizedString("overview.due_soon", comment: ""),
                value: "\(dueWithin7Days.count)",
                subtitle: NSLocalizedString("overview.next_7_days", comment: ""),
                icon: "bell.badge.fill",
                tint: .orange
            )
            metricTile(
                title: NSLocalizedString("overview.free_trials", comment: ""),
                value: "\(trialCount)",
                subtitle: NSLocalizedString("overview.watch_closely", comment: ""),
                icon: "hourglass",
                tint: .purple
            )
        }
    }

    private func metricTile(title: String, value: String, subtitle: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var upcomingAlertCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("overview.upcoming_renewals", comment: ""))
                    .font(.headline)
                Spacer()
                Text(NSLocalizedString("overview.next_7_days", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dueWithin7Days.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(NSLocalizedString("overview.no_upcoming", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                ForEach(dueWithin7Days.prefix(3)) { item in
                    SubscriptionRowView(item: item, baseCurrency: baseCurrency)
                    if item.id != dueWithin7Days.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var categoryChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("overview.category_breakdown", comment: ""))
                    .font(.headline)
                Spacer()
            }

            if categoryBreakdown.isEmpty {
                Text(NSLocalizedString("overview.empty_chart", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 12) {
                    Chart(categoryBreakdown, id: \.category) { entry in
                        BarMark(
                            x: .value("Amount", entry.monthlyTotal),
                            y: .value("Category", entry.category.localizedTitle)
                        )
                        .foregroundStyle(entry.category.tintColor)
                        .cornerRadius(6)
                    }
                    .frame(height: CGFloat(max(categoryBreakdown.count * 40, 110)))
                    .chartXAxis {
                        AxisMarks(position: .bottom)
                    }

                    VStack(spacing: 6) {
                        ForEach(categoryBreakdown, id: \.category) { entry in
                            HStack {
                                Circle()
                                    .fill(entry.category.tintColor)
                                    .frame(width: 8, height: 8)
                                Text(entry.category.localizedTitle)
                                    .font(.caption)
                                Spacer()
                                Text("\(baseCurrency.formatted(entry.monthlyTotal))/mo")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
