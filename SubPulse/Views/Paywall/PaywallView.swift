import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager

    @State private var selectedProductID: String = AppConfig.ProductID.proYearly
    @State private var statusBanner: String?
    @State private var crownPulse = false

    private var selectedProduct: Product? {
        storeManager.products.first { $0.id == selectedProductID } ?? storeManager.yearlyProduct ?? storeManager.monthlyProduct
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackgroundView(
                    accent: Color(hex: "#F97316"),
                    secondaryAccent: Color(hex: "#7C3AED")
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        headerSection
                        featureListSection
                        planSelectionSection
                        actionButtonsSection
                        legalDisclosureSection
                    }
                    .padding(20)
                }
                .scrollBounceBehavior(.always)
            }
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
                    .buttonStyle(BouncyButtonStyle(scale: 0.9))
                }
            }
            .sensoryFeedback(.selection, trigger: selectedProductID)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    crownPulse = true
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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FF7B29").opacity(0.28))
                    .frame(width: 96, height: 96)
                    .scaleEffect(crownPulse ? 1.15 : 0.95)
                    .blur(radius: 14)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFB340"), Color(hex: "#FF5E3A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                    .shadow(color: Color(hex: "#FF5E3A").opacity(0.35), radius: 14, y: 6)

                Image(systemName: "crown.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(NSLocalizedString("paywall.title", comment: ""))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text(NSLocalizedString("paywall.subtitle", comment: ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.top, 4)
    }

    private var featureListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "infinity", color: Color(hex: "#2563EB"), title: NSLocalizedString("paywall.feat_unlimited", comment: ""))
            featureRow(icon: "checkmark.seal.fill", color: Color(hex: "#10B981"), title: NSLocalizedString("paywall.feat_all_included", comment: ""))
            featureRow(icon: "sparkles", color: Color(hex: "#8B5CF6"), title: NSLocalizedString("paywall.feat_future", comment: ""))
            featureRow(icon: "heart.fill", color: Color(hex: "#F97316"), title: NSLocalizedString("paywall.feat_support", comment: ""))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tactileCard(cornerRadius: 24, padding: 18)
    }

    private func featureRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
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
                .frame(maxWidth: .infinity)
                .tactileCard(cornerRadius: 20, padding: 16)
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
            withAnimation(AppMotion.bouncy) {
                selectedProductID = product.id
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#FF9F0A"), Color(hex: "#FF5E3A")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
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
            .tactileCard(cornerRadius: 20, padding: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected
                            ? LinearGradient(
                                colors: [Color(hex: "#2563EB"), Color(hex: "#7C3AED")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
                        lineWidth: 2.2
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 0.99)
        }
        .buttonStyle(BouncyButtonStyle(scale: 0.96))
    }

    private func trialSubtitle(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else {
            return nil
        }
        return String(
            format: NSLocalizedString("paywall.free_trial_then", comment: ""),
            offer.period.value,
            product.displayPrice
        )
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
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#2563EB"), Color(hex: "#6D28D9")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .shadow(color: Color(hex: "#4F46E5").opacity(0.32), radius: 14, y: 6)
            }
            .buttonStyle(BouncyButtonStyle(scale: 0.96))
            .opacity(selectedProduct == nil || storeManager.isPurchasing ? 0.55 : 1.0)
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
            .font(.subheadline.weight(.semibold))
            .buttonStyle(BouncyButtonStyle(scale: 0.94))
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
