import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager

    @State private var selectedProductID: String = AppConfig.ProductID.proYearly
    @State private var statusBanner: String?

    private var selectedProduct: Product? {
        storeManager.products.first { $0.id == selectedProductID } ?? storeManager.yearlyProduct ?? storeManager.monthlyProduct
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    headerSection
                    featureListSection
                    planSelectionSection
                    actionButtonsSection
                    legalDisclosureSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                if storeManager.products.isEmpty {
                    await storeManager.loadProducts()
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, Color(hex: "#FF3B30")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                Image(systemName: "crown.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }

            Text(NSLocalizedString("paywall.title", comment: ""))
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(NSLocalizedString("paywall.subtitle", comment: ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    private var featureListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "infinity", color: .blue, title: NSLocalizedString("paywall.feat_unlimited", comment: ""))
            featureRow(icon: "checkmark.seal.fill", color: .green, title: NSLocalizedString("paywall.feat_all_included", comment: ""))
            featureRow(icon: "sparkles", color: .purple, title: NSLocalizedString("paywall.feat_future", comment: ""))
            featureRow(icon: "heart.fill", color: .orange, title: NSLocalizedString("paywall.feat_support", comment: ""))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func featureRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 26)
            Text(title)
                .font(.subheadline.weight(.medium))
        }
    }

    private var planSelectionSection: some View {
        VStack(spacing: 12) {
            if storeManager.isLoadingProducts {
                ProgressView()
                    .padding()
            } else if storeManager.products.isEmpty {
                VStack(spacing: 10) {
                    Text(NSLocalizedString("paywall.load_failed", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button(NSLocalizedString("action.retry", comment: "")) {
                        Task { await storeManager.loadProducts() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                if let yearly = storeManager.yearlyProduct {
                    planCard(
                        product: yearly,
                        badge: NSLocalizedString("paywall.best_value", comment: ""),
                        subtitle: trialSubtitle(for: yearly) ?? NSLocalizedString("paywall.yearly_desc", comment: "")
                    )
                }
                if let monthly = storeManager.monthlyProduct {
                    planCard(
                        product: monthly,
                        badge: nil,
                        subtitle: NSLocalizedString("paywall.monthly_desc", comment: "")
                    )
                }
            }
        }
    }

    private func planCard(product: Product, badge: String?, subtitle: String) -> some View {
        let isSelected = selectedProductID == product.id
        return Button {
            selectedProductID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func trialSubtitle(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else {
            return nil
        }
        return String(
            format: NSLocalizedString("paywall.free_trial_then", comment: ""),
            trialDurationText(for: offer.period),
            product.displayPrice
        )
    }

    /// App Store Connect only offers trial durations like "1 week" / "1 month", so the
    /// period unit must be honored — `period.value` alone would render a 1-week trial as "1-day".
    private func trialDurationText(for period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return String(format: NSLocalizedString("paywall.trial_days", comment: ""), period.value)
        case .week:
            return String(format: NSLocalizedString("paywall.trial_days", comment: ""), period.value * 7)
        case .month:
            return String(format: NSLocalizedString("paywall.trial_months", comment: ""), period.value)
        case .year:
            return String(format: NSLocalizedString("paywall.trial_years", comment: ""), period.value)
        @unknown default:
            return String(format: NSLocalizedString("paywall.trial_days", comment: ""), period.value)
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if let error = storeManager.errorMessage ?? statusBanner {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                guard let product = selectedProduct else { return }
                Task {
                    let success = await storeManager.purchase(product)
                    if success {
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    if storeManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(NSLocalizedString("paywall.continue", comment: ""))
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedProduct == nil || storeManager.isPurchasing)

            Button(NSLocalizedString("paywall.restore", comment: "")) {
                Task {
                    let restored = await storeManager.restorePurchases()
                    if restored {
                        dismiss()
                    } else {
                        statusBanner = NSLocalizedString("paywall.restore_none", comment: "")
                    }
                }
            }
            .font(.subheadline.weight(.medium))
            .disabled(storeManager.isPurchasing)
        }
    }

    private var legalDisclosureSection: some View {
        VStack(spacing: 10) {
            Text(NSLocalizedString("paywall.legal_disclosure", comment: ""))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link(NSLocalizedString("settings.terms", comment: ""), destination: AppConfig.termsOfServiceURL)
                Text("•").foregroundStyle(.tertiary)
                Link(NSLocalizedString("settings.privacy", comment: ""), destination: AppConfig.privacyPolicyURL)
            }
            .font(.caption)
        }
        .padding(.top, 4)
    }
}
