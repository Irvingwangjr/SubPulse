import Charts
import SwiftUI

struct OverviewView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let items: [SubscriptionItem]
    let baseCurrency: Currency
    let onShowPaywall: () -> Void
    let onJumpToSubscriptions: () -> Void

    @State private var appeared = false
    @State private var glowShift = false
    @State private var scrollDistance: CGFloat = 0

    private var barProgress: CGFloat {
        clampedScrollProgress(distance: scrollDistance, start: 10, range: 36)
    }

    private var summaryBadgeProgress: CGFloat {
        clampedScrollProgress(distance: scrollDistance, start: 42, range: 44)
    }

    private var monthlyTotal: Double {
        items.reduce(0) { $0 + $1.monthlyAmount(in: baseCurrency) }
    }

    private var yearlyTotal: Double {
        items.reduce(0) { $0 + $1.yearlyAmount(in: baseCurrency) }
    }

    private var dailyTotal: Double {
        monthlyTotal / 30.0
    }

    private var coffeeEquivalents: Int {
        let usdMonthly = items.reduce(0.0) { $0 + $1.monthlyAmount(in: .usd) }
        return max(1, Int((usdMonthly / 5.0).rounded()))
    }

    private var trialCount: Int {
        items.filter(\.isTrial).count
    }

    private var urgentTrialCount: Int {
        items.filter { $0.isTrial && $0.daysUntilRenewal <= 3 }.count
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
        ScrollViewReader { scrollProxy in
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 0)
                            .id("scrollTop")

                        VStack(spacing: 16) {
                            headerBar
                                .opacity(1.0 - Double(barProgress) * 0.85)
                            moodBanner
                                .offset(y: appeared ? 0 : 10)
                                .opacity(appeared ? 1 : 0)

                            if horizontalSizeClass == .regular {
                                // Hinge-safe 2-column split for iPhone Duo 7.6" unfolded display & iPad
                                HStack(alignment: .top, spacing: 24) {
                                    VStack(spacing: 16) {
                                        heroSummaryCard
                                            .scrollCardMotion()
                                        quickStatsRow
                                            .scrollCardMotion()
                                    }
                                    .frame(maxWidth: .infinity)

                                    VStack(spacing: 16) {
                                        upcomingAlertCard
                                            .scrollCardMotion()
                                        categoryChartCard
                                            .scrollCardMotion()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .offset(y: appeared ? 0 : 16)
                                .opacity(appeared ? 1 : 0)
                            } else {
                                heroSummaryCard
                                    .scrollCardMotion()
                                    .offset(y: appeared ? 0 : 14)
                                    .opacity(appeared ? 1 : 0)
                                quickStatsRow
                                    .scrollCardMotion()
                                    .offset(y: appeared ? 0 : 18)
                                    .opacity(appeared ? 1 : 0)
                                upcomingAlertCard
                                    .scrollCardMotion()
                                    .offset(y: appeared ? 0 : 22)
                                    .opacity(appeared ? 1 : 0)
                                categoryChartCard
                                    .scrollCardMotion()
                                    .offset(y: appeared ? 0 : 26)
                                    .opacity(appeared ? 1 : 0)
                            }

                            Spacer().frame(height: 92)
                        }
                        .frame(maxWidth: horizontalSizeClass == .regular ? 960 : .infinity)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 18)
                        .padding(.top, 10)
                    }
                    .trackLegacyScrollOffset()
                }
                .scrollBounceBehavior(.always)
                .onScrollDistanceChange { value in
                    scrollDistance = value
                }
            }
            .overlay(alignment: .top) {
                CollapsingTopBar(
                    title: "SubPulse",
                    barProgress: barProgress,
                    badgeProgress: summaryBadgeProgress,
                    onTapToTop: {
                        withAnimation(AppMotion.bouncy) {
                            scrollProxy.scrollTo("scrollTop", anchor: .top)
                        }
                    },
                    badge: {
                        Text("\(baseCurrency.formatted(monthlyTotal))/mo")
                            .font(.caption.weight(.bold))
                            .contentTransition(.numericText(value: monthlyTotal))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#2563EB"), Color(hex: "#6D28D9")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    },
                    trailing: {
                        if !storeManager.isPro {
                            Button(action: onShowPaywall) {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.caption2.weight(.bold))
                                    Text("Pro")
                                        .font(.caption.weight(.bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#FF9F0A"), Color(hex: "#FF5E3A")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: Capsule()
                                )
                            }
                            .buttonStyle(BouncyButtonStyle(scale: 0.92))
                        }
                    }
                )
            }
        }
        .onAppear {
            withAnimation(AppMotion.gentle) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                glowShift = true
            }
        }
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SubPulse")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(NSLocalizedString("overview.tagline", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !storeManager.isPro {
                Button(action: onShowPaywall) {
                    HStack(spacing: 5) {
                        Image(systemName: "crown.fill")
                            .font(.caption.weight(.bold))
                        Text("Pro")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FF9F0A"), Color(hex: "#FF5E3A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: Color(hex: "#FF7B29").opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.92))
            }
        }
        .padding(.bottom, 2)
    }

    private var moodBanner: some View {
        let isUrgent = urgentTrialCount > 0
        let hasUpcoming = !dueWithin7Days.isEmpty
        let tint: Color = isUrgent ? Color(hex: "#F97316") : (hasUpcoming ? Color(hex: "#4F46E5") : Color(hex: "#10B981"))

        let message: String = {
            if isUrgent {
                return String(format: NSLocalizedString("overview.mood_trial_soon", comment: ""), urgentTrialCount)
            } else if hasUpcoming {
                return String(format: NSLocalizedString("overview.mood_due_week", comment: ""), dueWithin7Days.count)
            } else {
                return NSLocalizedString("overview.mood_calm", comment: "")
            }
        }()

        return HStack(spacing: 12) {
            if isUrgent {
                PulseDotView(color: tint, size: 9)
                    .frame(width: 22)
            } else {
                Image(systemName: hasUpcoming ? "sparkles" : "sun.max.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 22)
            }

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint.opacity(0.24), lineWidth: 0.9)
        )
    }

    private var heroSummaryCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#1E3A8A"),
                            Color(hex: "#2563EB"),
                            Color(hex: "#6D28D9")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Soft animated ambient light orb inside the card
            Circle()
                .fill(Color(hex: "#38BDF8").opacity(0.32))
                .frame(width: 190, height: 190)
                .blur(radius: 44)
                .offset(x: glowShift ? 95 : 55, y: glowShift ? -55 : -30)

            Circle()
                .fill(Color(hex: "#F472B6").opacity(0.26))
                .frame(width: 150, height: 150)
                .blur(radius: 42)
                .offset(x: glowShift ? -90 : -55, y: glowShift ? 65 : 40)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(NSLocalizedString("overview.monthly_spend", comment: ""))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.86))
                    Spacer()
                    Text("\(baseCurrency.flag) \(baseCurrency.rawValue)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.18), in: Capsule())
                        .foregroundStyle(.white)
                }

                Text(baseCurrency.formatted(monthlyTotal))
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: monthlyTotal))
                    .animation(AppMotion.snappy, value: monthlyTotal)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                if monthlyTotal > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.caption)
                        Text(String(
                            format: NSLocalizedString("overview.daily_coffee", comment: ""),
                            baseCurrency.formatted(dailyTotal),
                            coffeeEquivalents
                        ))
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.15), in: Capsule())
                }

                Divider()
                    .overlay(.white.opacity(0.22))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("overview.yearly_projection", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                        Text(baseCurrency.formatted(yearlyTotal))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: yearlyTotal))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(NSLocalizedString("overview.active_subs", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                        Text("\(items.count)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: Double(items.count)))
                    }
                }
            }
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color(hex: "#3730A3").opacity(0.28), radius: 20, y: 10)
    }

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            metricTile(
                title: NSLocalizedString("overview.due_soon", comment: ""),
                value: dueWithin7Days.count,
                subtitle: NSLocalizedString("overview.next_7_days", comment: ""),
                icon: "bell.badge.fill",
                tint: Color(hex: "#F97316")
            )
            metricTile(
                title: NSLocalizedString("overview.free_trials", comment: ""),
                value: trialCount,
                subtitle: NSLocalizedString("overview.watch_closely", comment: ""),
                icon: "hourglass",
                tint: Color(hex: "#8B5CF6")
            )
        }
    }

    private func metricTile(title: String, value: Int, subtitle: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.16))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .contentTransition(.numericText(value: Double(value)))
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tactileCard(cornerRadius: 22, padding: 16)
    }

    private var upcomingAlertCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(NSLocalizedString("overview.upcoming_renewals", comment: ""))
                    .font(.headline.weight(.bold))
                Spacer()
                Button(action: onJumpToSubscriptions) {
                    Text(NSLocalizedString("overview.see_all", comment: ""))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.94))
            }

            if items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("subs.empty_desc", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button(action: onJumpToSubscriptions) {
                        Label(NSLocalizedString("subs.smart_import", comment: ""), systemImage: "doc.viewfinder")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(BouncyButtonStyle(scale: 0.94))
                }
                .padding(.vertical, 4)
            } else if dueWithin7Days.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Text(NSLocalizedString("overview.no_upcoming", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                VStack(spacing: 14) {
                    ForEach(dueWithin7Days.prefix(3)) { item in
                        SubscriptionRowView(item: item, baseCurrency: baseCurrency, showProgressBar: true)
                        if item.id != dueWithin7Days.prefix(3).last?.id {
                            Divider()
                                .opacity(0.6)
                        }
                    }
                }
            }
        }
        .tactileCard(cornerRadius: 24, padding: 18)
    }

    private var categoryChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(NSLocalizedString("overview.category_breakdown", comment: ""))
                    .font(.headline.weight(.bold))
                Spacer()
            }

            if categoryBreakdown.isEmpty {
                Text(NSLocalizedString("overview.empty_chart", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 14) {
                    Chart(categoryBreakdown, id: \.category) { entry in
                        BarMark(
                            x: .value("Amount", entry.monthlyTotal),
                            y: .value("Category", entry.category.localizedTitle)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [entry.category.tintColor, entry.category.tintColor.opacity(0.72)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                    .frame(height: CGFloat(max(categoryBreakdown.count * 44, 112)))
                    .chartXAxis {
                        AxisMarks(position: .bottom)
                    }

                    VStack(spacing: 8) {
                        ForEach(categoryBreakdown, id: \.category) { entry in
                            HStack {
                                Circle()
                                    .fill(entry.category.tintColor)
                                    .frame(width: 9, height: 9)
                                Text(entry.category.localizedTitle)
                                    .font(.caption.weight(.medium))
                                Spacer()
                                Text("\(baseCurrency.formatted(entry.monthlyTotal))/mo")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .tactileCard(cornerRadius: 24, padding: 18)
    }
}
