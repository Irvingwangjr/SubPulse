import StoreKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let items: [SubscriptionItem]
    @Binding var baseCurrencyCode: String
    let onShowPaywall: () -> Void
    let onReplayOnboarding: () -> Void

    @State private var notificationStatusText = ""
    @State private var showingResetConfirmation = false
    @State private var showingManageSubscriptions = false
    @State private var exportFileURL: URL?
    @State private var scrollDistance: CGFloat = 0

    private var barProgress: CGFloat {
        clampedScrollProgress(distance: scrollDistance, start: 10, range: 36)
    }

    private var baseCurrency: Currency {
        Currency.from(code: baseCurrencyCode)
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                AmbientBackgroundView(
                    accent: Color(hex: "#6366F1"),
                    secondaryAccent: Color(hex: "#0EA5E9")
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 0)
                            .id("scrollTop")

                        VStack(alignment: .leading, spacing: 18) {
                            Text(NSLocalizedString("tab.settings", comment: ""))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .opacity(1.0 - Double(barProgress) * 0.85)

                            proBannerCard
                                .scrollCardMotion()

                            if horizontalSizeClass == .regular {
                                HStack(alignment: .top, spacing: 24) {
                                    preferencesCard
                                        .scrollCardMotion()
                                        .frame(maxWidth: .infinity)
                                    dataCard
                                        .scrollCardMotion()
                                        .frame(maxWidth: .infinity)
                                }
                            } else {
                                preferencesCard
                                    .scrollCardMotion()
                                dataCard
                                    .scrollCardMotion()
                            }

                            legalCard
                                .scrollCardMotion()

                            VStack(spacing: 6) {
                                Text("\(NSLocalizedString("settings.version", comment: "")) \(appVersion)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(NSLocalizedString("settings.privacy_footer", comment: ""))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)

                            Spacer().frame(height: 92)
                        }
                        .frame(maxWidth: horizontalSizeClass == .regular ? 880 : .infinity)
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
                    title: NSLocalizedString("tab.settings", comment: ""),
                    barProgress: barProgress,
                    badgeProgress: barProgress,
                    maxWidth: 880,
                    onTapToTop: {
                        withAnimation(AppMotion.bouncy) {
                            scrollProxy.scrollTo("scrollTop", anchor: .top)
                        }
                    },
                    badge: {
                        if storeManager.isPro {
                            Text("Pro")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color(hex: "#10B981"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#10B981").opacity(0.14), in: Capsule())
                        }
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
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
        .confirmationDialog(
            NSLocalizedString("settings.delete_confirm_title", comment: ""),
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("settings.delete_all", comment: ""), role: .destructive) {
                deleteAllItems()
            }
            Button(NSLocalizedString("action.cancel", comment: ""), role: .cancel) {}
        }
        .task(id: "\(items.count)-\(baseCurrencyCode)") {
            await refreshNotificationStatus()
            exportFileURL = CSVExporter.exportURL(for: items, baseCurrency: baseCurrency)
        }
    }

    private var proBannerCard: some View {
        Group {
            if storeManager.isPro {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(NSLocalizedString("settings.pro_active", comment: ""), systemImage: "checkmark.seal.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color(hex: "#10B981"))
                        Spacer()
                        Text("Active")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#10B981").opacity(0.14), in: Capsule())
                            .foregroundStyle(Color(hex: "#10B981"))
                    }
                    Button(NSLocalizedString("settings.manage_subscription", comment: "")) {
                        showingManageSubscriptions = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(BouncyButtonStyle())
                }
                .tactileCard(cornerRadius: 24, padding: 18)
            } else {
                Button(action: onShowPaywall) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.22))
                                .frame(width: 48, height: 48)
                            Image(systemName: "crown.fill")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(NSLocalizedString("settings.upgrade_pro", comment: ""))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                            Text(NSLocalizedString("settings.pro_card_subtitle", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.88))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FF9F0A"), Color(hex: "#FF5E3A"), Color(hex: "#EC4899")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
                    .shadow(color: Color(hex: "#FF5E3A").opacity(0.32), radius: 16, y: 8)
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.97))
            }
        }
    }

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(NSLocalizedString("settings.preferences", comment: "").uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                HStack {
                    Label(NSLocalizedString("settings.base_currency", comment: ""), systemImage: "dollarsign.circle.fill")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Picker(NSLocalizedString("settings.base_currency", comment: ""), selection: $baseCurrencyCode) {
                        ForEach(Currency.allCases) { currency in
                            Text("\(currency.flag) \(currency.rawValue)").tag(currency.rawValue)
                        }
                    }
                    .labelsHidden()
                    .tint(Color.accentColor)
                }

                Divider().opacity(0.6)

                HStack {
                    Label(NSLocalizedString("settings.notifications", comment: ""), systemImage: "bell.fill")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(notificationStatusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider().opacity(0.6)

                Button {
                    Task {
                        _ = await NotificationManager.shared.requestAuthorization()
                        await NotificationManager.shared.rescheduleAll(items)
                        await refreshNotificationStatus()
                    }
                } label: {
                    HStack {
                        Text(NSLocalizedString("settings.enable_notifications", comment: ""))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.98))
            }
            .tactileCard(cornerRadius: 22, padding: 16)
        }
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(NSLocalizedString("settings.data", comment: "").uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                if let url = exportFileURL {
                    ShareLink(item: url) {
                        HStack {
                            Label(NSLocalizedString("settings.export_csv", comment: ""), systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } else {
                    Button {
                        exportFileURL = CSVExporter.exportURL(for: items, baseCurrency: baseCurrency)
                    } label: {
                        HStack {
                            Label(NSLocalizedString("settings.prepare_csv", comment: ""), systemImage: "doc.text")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                    .buttonStyle(BouncyButtonStyle(scale: 0.98))
                }

                Divider().opacity(0.6)

                Button {
                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Label(NSLocalizedString("settings.open_apple_subs", comment: ""), systemImage: "apple.logo")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.98))

                Divider().opacity(0.6)

                Button(action: onReplayOnboarding) {
                    HStack {
                        Label(NSLocalizedString("settings.replay_onboarding", comment: ""), systemImage: "hand.wave.fill")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.98))

                Divider().opacity(0.6)

                Button {
                    loadSampleSubscriptions()
                } label: {
                    HStack {
                        Label(NSLocalizedString("settings.load_samples", comment: ""), systemImage: "sparkles")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.98))

                Divider().opacity(0.6)

                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    HStack {
                        Label(NSLocalizedString("settings.delete_all", comment: ""), systemImage: "trash")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.98))
            }
            .tactileCard(cornerRadius: 22, padding: 16)
        }
    }

    private var legalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(NSLocalizedString("settings.legal", comment: "").uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                Link(destination: AppConfig.privacyPolicyURL) {
                    HStack {
                        Text(NSLocalizedString("settings.privacy", comment: ""))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider().opacity(0.6)

                Link(destination: AppConfig.termsOfServiceURL) {
                    HStack {
                        Text(NSLocalizedString("settings.terms", comment: ""))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider().opacity(0.6)

                Link(destination: AppConfig.supportURL) {
                    HStack {
                        Text(NSLocalizedString("settings.support", comment: ""))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .tactileCard(cornerRadius: 22, padding: 16)
        }
    }

    private func loadSampleSubscriptions() {
        if !storeManager.isPro && items.count >= AppConfig.freeSubscriptionLimit {
            onShowPaywall()
            return
        }
        let samples = ServicePreset.sampleItems()
        let allowed = storeManager.isPro
            ? samples.count
            : max(0, AppConfig.freeSubscriptionLimit - items.count)
        withAnimation(AppMotion.bouncy) {
            for sample in samples.prefix(allowed) {
                modelContext.insert(sample)
            }
            try? modelContext.save()
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func refreshNotificationStatus() async {
        let status = await NotificationManager.shared.authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            notificationStatusText = NSLocalizedString("status.enabled", comment: "")
        case .denied:
            notificationStatusText = NSLocalizedString("status.denied", comment: "")
        case .notDetermined:
            notificationStatusText = NSLocalizedString("status.not_set", comment: "")
        @unknown default:
            notificationStatusText = ""
        }
    }

    private func deleteAllItems() {
        withAnimation(AppMotion.snappy) {
            for item in items {
                NotificationManager.shared.cancelReminder(for: item.id)
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }
}
