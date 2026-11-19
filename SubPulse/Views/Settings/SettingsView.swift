import StoreKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager

    let items: [SubscriptionItem]
    @Binding var baseCurrencyCode: String
    let onShowPaywall: () -> Void

    @State private var notificationStatusText = ""
    @State private var showingResetConfirmation = false
    @State private var showingManageSubscriptions = false
    @State private var exportFileURL: URL?

    private var baseCurrency: Currency {
        Currency.from(code: baseCurrencyCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("SubPulse Pro") {
                    if storeManager.isPro {
                        HStack {
                            Label(NSLocalizedString("settings.pro_active", comment: ""), systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Text("Active")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Button(NSLocalizedString("settings.manage_subscription", comment: "")) {
                            showingManageSubscriptions = true
                        }
                    } else {
                        Button(action: onShowPaywall) {
                            HStack {
                                Label(NSLocalizedString("settings.upgrade_pro", comment: ""), systemImage: "crown.fill")
                                    .foregroundStyle(.orange)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section(NSLocalizedString("settings.preferences", comment: "")) {
                    Picker(NSLocalizedString("settings.base_currency", comment: ""), selection: $baseCurrencyCode) {
                        ForEach(Currency.allCases) { currency in
                            Text("\(currency.flag) \(currency.displayName)").tag(currency.rawValue)
                        }
                    }

                    HStack {
                        Text(NSLocalizedString("settings.notifications", comment: ""))
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundStyle(.secondary)
                    }

                    Button(NSLocalizedString("settings.enable_notifications", comment: "")) {
                        Task {
                            _ = await NotificationManager.shared.requestAuthorization()
                            await NotificationManager.shared.rescheduleAll(items)
                            await refreshNotificationStatus()
                        }
                    }
                }

                Section(NSLocalizedString("settings.data", comment: "")) {
                    if storeManager.isPro {
                        if let url = exportFileURL {
                            ShareLink(item: url) {
                                Label(NSLocalizedString("settings.export_csv", comment: ""), systemImage: "square.and.arrow.up")
                            }
                        } else {
                            Button {
                                exportFileURL = CSVExporter.exportURL(for: items, baseCurrency: baseCurrency)
                            } label: {
                                Label(NSLocalizedString("settings.prepare_csv", comment: ""), systemImage: "doc.text")
                            }
                        }
                    } else {
                        Button(action: onShowPaywall) {
                            HStack {
                                Label(NSLocalizedString("settings.export_csv", comment: ""), systemImage: "square.and.arrow.up")
                                Spacer()
                                Text("Pro")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    Button(NSLocalizedString("settings.load_samples", comment: "")) {
                        for sample in ServicePreset.sampleItems() {
                            modelContext.insert(sample)
                        }
                    }

                    Button(NSLocalizedString("settings.delete_all", comment: ""), role: .destructive) {
                        showingResetConfirmation = true
                    }
                }

                Section(NSLocalizedString("settings.legal", comment: "")) {
                    Link(NSLocalizedString("settings.privacy", comment: ""), destination: AppConfig.privacyPolicyURL)
                    Link(NSLocalizedString("settings.terms", comment: ""), destination: AppConfig.termsOfServiceURL)
                    Link(NSLocalizedString("settings.support", comment: ""), destination: AppConfig.supportURL)
                }

                Section {
                    HStack {
                        Text(NSLocalizedString("settings.version", comment: ""))
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text(NSLocalizedString("settings.privacy_footer", comment: ""))
                }
            }
            .navigationTitle(NSLocalizedString("tab.settings", comment: ""))
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
            .task {
                await refreshNotificationStatus()
                if storeManager.isPro {
                    exportFileURL = CSVExporter.exportURL(for: items, baseCurrency: baseCurrency)
                }
            }
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
        for item in items {
            NotificationManager.shared.cancelReminder(for: item.id)
            modelContext.delete(item)
        }
    }
}
