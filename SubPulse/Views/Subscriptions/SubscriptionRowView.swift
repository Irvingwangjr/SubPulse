import SwiftUI

struct SubscriptionRowView: View {
    let item: SubscriptionItem
    let baseCurrency: Currency

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(item.accentColor.opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: item.iconSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(item.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)

                    if item.isTrial {
                        Text(NSLocalizedString("badge.trial", comment: ""))
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.15), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                }

                HStack(spacing: 6) {
                    Text(renewalBadgeText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(renewalBadgeColor)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(item.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.currency.formatted(item.amount))\(item.billingCycle.shortSuffix)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if item.currency != baseCurrency || item.billingCycle != .monthly {
                    Text("≈ \(baseCurrency.formatted(item.monthlyAmount(in: baseCurrency)))/mo")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
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
        if days <= 1 { return .red }
        if days <= 5 { return .orange }
        return .secondary
    }
}
