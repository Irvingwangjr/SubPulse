import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct SmartImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(StoreManager.self) private var storeManager

    let existingCount: Int
    let onShowPaywall: () -> Void

    @State private var mode = 0 // 0: Quick Pick Wall, 1: Scan Screenshot / Paste
    @State private var selectedPresets: Set<ServicePreset> = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isScanning = false
    @State private var candidates: [ParsedSubscriptionCandidate] = []
    @State private var statusMessage: String?

    private var remainingFreeSlots: Int {
        storeManager.isPro ? .max : max(0, AppConfig.freeSubscriptionLimit - existingCount)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackgroundView(
                    accent: Color(hex: "#2563EB"),
                    secondaryAccent: Color(hex: "#10B981")
                )

                VStack(spacing: 14) {
                    Picker("Mode", selection: $mode) {
                        Text(NSLocalizedString("import.tab_quick_pick", comment: "")).tag(0)
                        Text(NSLocalizedString("import.tab_scan_ocr", comment: "")).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    if mode == 0 {
                        quickPickSection
                    } else {
                        scanAndPasteSection
                    }
                }
            }
            .navigationTitle(NSLocalizedString("import.nav_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("action.cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task { await scanPhoto(newItem) }
            }
        }
    }

    private var quickPickSection: some View {
        VStack(spacing: 12) {
            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(ServicePreset.popular) { preset in
                        let isSelected = selectedPresets.contains(preset)
                        Button {
                            togglePreset(preset)
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color(hex: preset.colorHex).opacity(0.18))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: preset.symbol)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(Color(hex: preset.colorHex))
                                    }

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.white, Color.accentColor)
                                            .offset(x: 6, y: -6)
                                    }
                                }

                                Text(preset.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                Text("\(preset.currency.formatted(preset.defaultAmount))\(preset.cycle.shortSuffix)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 6)
                            .frame(maxWidth: .infinity)
                            .tactileCard(cornerRadius: 18, padding: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(BouncyButtonStyle(scale: 0.94))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
            }
            .scrollBounceBehavior(.always)

            Button {
                importSelectedPresets()
            } label: {
                Text(String(format: NSLocalizedString("import.add_selected_cta", comment: ""), selectedPresets.count))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#2563EB"), Color(hex: "#6366F1")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .buttonStyle(BouncyButtonStyle(scale: 0.96))
            .disabled(selectedPresets.isEmpty)
            .opacity(selectedPresets.isEmpty ? 0.5 : 1.0)
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
    }

    private var scanAndPasteSection: some View {
        VStack(spacing: 14) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("import.ocr_guide_title", comment: ""))
                            .font(.headline.weight(.bold))
                        Text(NSLocalizedString("import.ocr_guide_desc", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Button {
                                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                    openURL(url)
                                }
                            } label: {
                                Label(NSLocalizedString("import.open_apple_subs", comment: ""), systemImage: "apple.logo")
                                    .font(.caption.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(BouncyButtonStyle())

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label(NSLocalizedString("import.pick_screenshot", comment: ""), systemImage: "photo.on.rectangle.angled")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(Color(hex: "#10B981"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        Button {
                            parseClipboard()
                        } label: {
                            Label(NSLocalizedString("import.paste_clipboard", comment: ""), systemImage: "doc.on.clipboard")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                    .tactileCard(cornerRadius: 22, padding: 16)

                    if isScanning {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(NSLocalizedString("import.scanning", comment: ""))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else if let statusMessage {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if !candidates.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(format: NSLocalizedString("import.found_count", comment: ""), candidates.count))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color(hex: "#10B981"))

                            ForEach($candidates) { $candidate in
                                HStack(spacing: 12) {
                                    Button {
                                        candidate.isSelected.toggle()
                                    } label: {
                                        Image(systemName: candidate.isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(candidate.isSelected ? Color(hex: "#10B981") : .secondary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(candidate.name)
                                            .font(.subheadline.weight(.semibold))
                                        Text("\(candidate.billingCycle.localizedTitle) • \(candidate.nextBillingDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(candidate.currency.formatted(candidate.amount))\(candidate.billingCycle.shortSuffix)")
                                        .font(.subheadline.weight(.bold))
                                }
                                .tactileCard(cornerRadius: 18, padding: 14)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
            }
            .scrollBounceBehavior(.always)

            let selectedCount = candidates.filter(\.isSelected).count
            if !candidates.isEmpty {
                Button {
                    importOCRCandidates()
                } label: {
                    Text(String(format: NSLocalizedString("import.add_selected_cta", comment: ""), selectedCount))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.96))
                .disabled(selectedCount == 0)
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
            }
        }
    }

    private func togglePreset(_ preset: ServicePreset) {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        if selectedPresets.contains(preset) {
            selectedPresets.remove(preset)
        } else if selectedPresets.count < remainingFreeSlots {
            selectedPresets.insert(preset)
        } else {
            dismiss()
            onShowPaywall()
        }
    }

    private func scanPhoto(_ item: PhotosPickerItem) async {
        isScanning = true
        statusMessage = nil
        defer { isScanning = false }

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            let parsed = await ScreenshotOCRParser.recognizeAndParse(image: image)
            candidates = parsed
            if parsed.isEmpty {
                statusMessage = NSLocalizedString("import.none_found", comment: "")
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func parseClipboard() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            statusMessage = NSLocalizedString("import.clipboard_empty", comment: "")
            return
        }
        let parsed = ScreenshotOCRParser.parseText(text)
        candidates = parsed
        if parsed.isEmpty {
            statusMessage = NSLocalizedString("import.none_found", comment: "")
        } else {
            statusMessage = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func importSelectedPresets() {
        let cal = Calendar.current
        let today = Date()
        var inserted: [SubscriptionItem] = []
        for (idx, preset) in selectedPresets.prefix(remainingFreeSlots).enumerated() {
            let item = SubscriptionItem(
                name: preset.name,
                amount: preset.defaultAmount,
                currency: preset.currency,
                billingCycle: preset.cycle,
                category: preset.category,
                nextBillingDate: cal.date(byAdding: .day, value: 7 + idx * 5, to: today) ?? today,
                reminderDaysBefore: 1,
                iconSymbol: preset.symbol,
                colorHex: preset.colorHex
            )
            modelContext.insert(item)
            inserted.append(item)
        }
        try? modelContext.save()
        Task { await NotificationManager.shared.rescheduleAll(inserted) }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private func importOCRCandidates() {
        let chosen = candidates.filter(\.isSelected)
        if !storeManager.isPro && remainingFreeSlots == 0 {
            dismiss()
            onShowPaywall()
            return
        }
        var inserted: [SubscriptionItem] = []
        for c in chosen.prefix(remainingFreeSlots) {
            let item = SubscriptionItem(
                name: c.name,
                amount: c.amount,
                currency: c.currency,
                billingCycle: c.billingCycle,
                category: c.category,
                nextBillingDate: c.nextBillingDate,
                reminderDaysBefore: 1,
                isTrial: c.isTrial,
                notes: "Imported via Smart Scan",
                iconSymbol: c.iconSymbol,
                colorHex: c.colorHex
            )
            modelContext.insert(item)
            inserted.append(item)
        }
        try? modelContext.save()
        Task { await NotificationManager.shared.rescheduleAll(inserted) }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
