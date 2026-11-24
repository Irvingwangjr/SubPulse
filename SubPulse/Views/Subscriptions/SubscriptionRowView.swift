import SwiftUI

struct SubscriptionRowView: View {
    let item: SubscriptionItem
    let baseCurrency: Currency
    var showProgressBar: Bool = true

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [item.accentColor.opacity(0.24), item.accentColor.opacity(0.11)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                    Image(systemName: item.iconSymbol)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(item.accentColor)
                }
                .shadow(color: item.accentColor.opacity(0.22), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.body.weight(.semibold))
                            .lineLimit(1)

                        if item.isTrial {
                            HStack(spacing: 4) {
                                PulseDotView(color: Color(hex: "#9333EA"), size: 5)
                                Text(NSLocalizedString("badge.trial", comment: ""))
                                    .font(.caption2.weight(.bold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.purple.opacity(0.13), in: Capsule())
                            .foregroundStyle(Color(hex: "#9333EA"))
                        }
                    }

                    HStack(spacing: 6) {
                        Text(renewalBadgeText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(renewalBadgeColor)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Text(item.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(item.currency.formatted(item.amount))\(item.billingCycle.shortSuffix)")
                        .font(.subheadline.weight(.bold))
                        .contentTransition(.numericText())
                        .lineLimit(1)

                    if item.currency != baseCurrency || item.billingCycle != .monthly {
                        Text("≈ \(baseCurrency.formatted(item.monthlyAmount(in: baseCurrency)))/mo")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if showProgressBar {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [urgencyProgressColor.opacity(0.75), urgencyProgressColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(12, geo.size.width * cycleProgress))
                    }
                }
                .frame(height: 4)
            }
        }
    }

    private var cycleProgress: CGFloat {
        let cycleDays: Double = {
            switch item.billingCycle {
            case .weekly: return 7
            case .monthly: return 30
            case .quarterly: return 90
            case .yearly: return 365
            }
        }()
        let remaining = max(0, Double(item.daysUntilRenewal))
        let elapsedRatio = 1.0 - min(1.0, remaining / cycleDays)
        return CGFloat(max(0.08, elapsedRatio))
    }

    private var urgencyProgressColor: Color {
        let days = item.daysUntilRenewal
        if days <= 2 { return Color(hex: "#EF4444") }
        if days <= 6 { return Color(hex: "#F97316") }
        return item.accentColor
    }

    private var renewalBadgeText: String {
        let days = item.daysUntilRenewal
        if days < 0 {
            return String(format: NSLocalizedString("renewal.overdue", comment: ""), abs(days))
        } else if days == 0 {
            return NSLocalizedString("renewal.today", comment: "")
        } else if days == 1 {
            return NSLocalizedString("renewal.tomorrow", comment: "")
        } else {
            return String(format: NSLocalizedString("renewal.in_days", comment: ""), days)
        }
    }

    private var renewalBadgeColor: Color {
        let days = item.daysUntilRenewal
        if days <= 1 { return Color(hex: "#EF4444") }
        if days <= 5 { return Color(hex: "#F97316") }
        return .secondary
    }
}
