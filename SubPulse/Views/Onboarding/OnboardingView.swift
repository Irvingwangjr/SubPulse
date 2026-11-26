import CoreHaptics
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

@MainActor
private final class KineticHapticEngine {
    private var engine: CHHapticEngine?
    private let rigidFallback = UIImpactFeedbackGenerator(style: .rigid)
    private let mediumFallback = UIImpactFeedbackGenerator(style: .medium)

    init() {
        prepare()
    }

    func prepare() {
        rigidFallback.prepare()
        mediumFallback.prepare()
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let eng = try CHHapticEngine()
            eng.playsHapticsOnly = true
            eng.isAutoShutdownEnabled = false
            eng.resetHandler = { [weak eng] in
                try? eng?.start()
            }
            try eng.start()
            self.engine = eng
        } catch {
            self.engine = nil
        }
    }

    func tick(intensity: Float, sharpness: Float) {
        if let engine {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            do {
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
                return
            } catch {
                try? engine.start()
            }
        }
        if sharpness > 0.6 {
            rigidFallback.impactOccurred(intensity: CGFloat(intensity))
            rigidFallback.prepare()
        } else {
            mediumFallback.impactOccurred(intensity: CGFloat(intensity))
            mediumFallback.prepare()
        }
    }

    func stop() {
        engine?.stop(completionHandler: nil)
    }
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let baseCurrency: Currency
    let existingCount: Int
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var selectedPresets: Set<ServicePreset> = []
    @State private var quotaHintVisible = false

    // Kinetic ChatGPT-style typewriter splash state
    @State private var phraseIndex = 0
    @State private var typedText = ""
    @State private var cursorVisible = true
    @State private var orbBreath = false

    // OCR screenshot import inside onboarding page 2
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isScanningOCR = false
    @State private var ocrCandidates: [ParsedSubscriptionCandidate] = []
    @State private var ocrEmptyHint = false

    private let kineticPhrases: [(accentHex: String, textKey: String)] = [
        ("#38BDF8", "onboarding.kinetic_1"),
        ("#F97316", "onboarding.kinetic_2"),
        ("#34D399", "onboarding.kinetic_3"),
        ("#A78BFA", "onboarding.kinetic_4")
    ]

    private var currentFullPhrase: String {
        NSLocalizedString(kineticPhrases[phraseIndex].textKey, comment: "")
    }

    private var kineticCursorLine: Text {
        let content = Text(typedText)
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
        let spacer = Text(typedText.isEmpty ? "" : " ")
            .font(.system(size: 32, weight: .bold, design: .rounded))
        let dot = Text(Image(systemName: "circle.fill"))
            .font(.system(size: 18, weight: .bold))
            .baselineOffset(3)
            .foregroundStyle(cursorVisible ? Color.white : Color.white.opacity(0.08))
        return content + spacer + dot
    }

    private var remainingFreeSlots: Int {
        storeManager.isPro ? .max : max(0, AppConfig.freeSubscriptionLimit - existingCount)
    }

    private var selectedMonthlyTotal: Double {
        selectedPresets.reduce(0.0) { total, preset in
            let converted = preset.currency.convert(preset.defaultAmount, to: baseCurrency)
            return total + preset.cycle.monthlyEquivalent(of: converted)
        }
    }

    private var pageAccent: Color {
        switch currentPage {
        case 0: return Color(hex: kineticPhrases[phraseIndex].accentHex)
        case 1: return Color(hex: "#6366F1")
        default: return Color(hex: "#10B981")
        }
    }

    var body: some View {
        ZStack {
            // Dynamic color-shifting ambient background
            LinearGradient(
                colors: [
                    Color(hex: "#0B1120"),
                    pageAccent.opacity(0.32),
                    Color(hex: "#0F172A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.7), value: currentPage)
            .animation(.easeInOut(duration: 0.9), value: phraseIndex)

            Circle()
                .fill(pageAccent.opacity(0.34))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .scaleEffect(orbBreath ? 1.15 : 0.9)
                .offset(y: currentPage == 0 ? -120 : -240)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                topProgressBar

                TabView(selection: $currentPage) {
                    kineticWelcomePage.tag(0)
                    quickPickWallPage.tag(1)
                    smartScanAndFinishPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppMotion.bouncy, value: currentPage)
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 560 : .infinity)
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.selection, trigger: currentPage)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                orbBreath = true
            }
        }
        .task {
            await runKineticLoop()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePickedPhoto(newItem) }
        }
    }

    // MARK: - Top Progress Indicator

    private var topProgressBar: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { idx in
                    Capsule()
                        .fill(idx == currentPage ? Color.white : Color.white.opacity(0.25))
                        .frame(width: idx == currentPage ? 26 : 8, height: 6)
                        .animation(AppMotion.bouncy, value: currentPage)
                }
            }

            Spacer()

            Button(NSLocalizedString("onboarding.skip", comment: "")) {
                finishOnboarding()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.72))
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Page 0: ChatGPT-Style Kinetic Typewriter Splash

    private var kineticWelcomePage: some View {
        VStack(alignment: .leading, spacing: 26) {
            Spacer()

            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(pageAccent.opacity(0.28))
                            .frame(width: 72, height: 72)
                            .scaleEffect(orbBreath ? 1.18 : 0.92)
                            .blur(radius: 12)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#2563EB"), pageAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                            .shadow(color: pageAccent.opacity(0.55), radius: 18, y: 6)

                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse, value: phraseIndex)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("SUBPULSE")
                            .font(.caption.weight(.bold))
                            .tracking(2.2)
                            .foregroundStyle(.white.opacity(0.78))
                        Text(NSLocalizedString("overview.tagline", comment: ""))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(pageAccent.opacity(0.95))
                    }
                }

                // Strictly single-line left-to-right silky typewriter + solid circle cursor
                kineticCursorLine
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .animation(nil, value: typedText)
                    .animation(.easeInOut(duration: 0.14), value: cursorVisible)

                Text(NSLocalizedString("onboarding.welcome_sub", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 26)

            Spacer()

            VStack(spacing: 14) {
                Button {
                    triggerHaptic(.medium)
                    withAnimation(AppMotion.bouncy) {
                        currentPage = 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(NSLocalizedString("onboarding.start_cta", comment: ""))
                            .font(.headline.weight(.bold))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(Color(hex: "#0B1120"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .white.opacity(0.22), radius: 16, y: 6)
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.96))

                Text(NSLocalizedString("onboarding.swipe_hint", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Page 1: 5-Second Popular Services Icon Wall

    private var quickPickWallPage: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(NSLocalizedString("onboarding.pick_title", comment: ""))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(String(
                    format: NSLocalizedString("onboarding.pick_subtitle", comment: ""),
                    AppConfig.freeSubscriptionLimit
                ))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 22)
            .padding(.top, 6)

            if quotaHintVisible {
                Text(String(
                    format: NSLocalizedString("onboarding.pick_limit_hint", comment: ""),
                    AppConfig.freeSubscriptionLimit
                ))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: "#FBBF24"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "#FBBF24").opacity(0.16), in: Capsule())
                .transition(.scale.combined(with: .opacity))
            }

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
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(hex: preset.colorHex).opacity(isSelected ? 0.34 : 0.18))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: preset.symbol)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(Color(hex: preset.colorHex))
                                    }

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white, Color(hex: "#2563EB"))
                                            .offset(x: 6, y: -6)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }

                                Text(preset.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                Text("\(preset.currency.formatted(preset.defaultAmount))\(preset.cycle.shortSuffix)")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.65))
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(isSelected ? Color.white.opacity(0.16) : Color.white.opacity(0.07))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(
                                        isSelected ? Color(hex: "#60A5FA") : Color.white.opacity(0.1),
                                        lineWidth: isSelected ? 2 : 0.8
                                    )
                            )
                            .scaleEffect(isSelected ? 1.03 : 1.0)
                        }
                        .buttonStyle(BouncyButtonStyle(scale: 0.93))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
            }
            .scrollBounceBehavior(.always)

            VStack(spacing: 10) {
                if !selectedPresets.isEmpty {
                    Text(String(
                        format: NSLocalizedString("onboarding.selected_summary", comment: ""),
                        selectedPresets.count,
                        baseCurrency.formatted(selectedMonthlyTotal)
                    ))
                    .font(.caption.weight(.bold))
                    .contentTransition(.numericText())
                    .foregroundStyle(Color(hex: "#93C5FD"))
                }

                Button {
                    triggerHaptic(.medium)
                    withAnimation(AppMotion.bouncy) {
                        currentPage = 2
                    }
                } label: {
                    Text(selectedPresets.isEmpty
                        ? NSLocalizedString("onboarding.pick_skip_cta", comment: "")
                        : String(format: NSLocalizedString("onboarding.pick_continue_cta", comment: ""), selectedPresets.count)
                    )
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color(hex: "#0B1120"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.96))
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Page 2: Zero-Input Apple Screenshot OCR + Notifications

    private var smartScanAndFinishPage: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#10B981").opacity(0.2))
                        .frame(width: 68, height: 68)
                    Image(systemName: "doc.viewfinder.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color(hex: "#34D399"))
                }

                Text(NSLocalizedString("onboarding.scan_title", comment: ""))
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString("onboarding.scan_subtitle", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.74))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Two zero-friction actions
                    HStack(spacing: 10) {
                        Button {
                            if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                openURL(url)
                            }
                        } label: {
                            Label(NSLocalizedString("import.open_apple_subs", comment: ""), systemImage: "apple.logo")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(BouncyButtonStyle(scale: 0.95))

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label(NSLocalizedString("import.pick_screenshot", comment: ""), systemImage: "photo.on.rectangle.angled")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color(hex: "#0B1120"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color(hex: "#34D399"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }

                    if isScanningOCR {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text(NSLocalizedString("import.scanning", comment: ""))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding()
                    } else if !ocrCandidates.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(format: NSLocalizedString("import.found_count", comment: ""), ocrCandidates.count))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color(hex: "#34D399"))

                            ForEach($ocrCandidates) { $candidate in
                                HStack {
                                    Button {
                                        triggerHaptic(.light)
                                        candidate.isSelected.toggle()
                                    } label: {
                                        Image(systemName: candidate.isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(candidate.isSelected ? Color(hex: "#34D399") : .white.opacity(0.4))
                                    }
                                    Text(candidate.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(candidate.currency.formatted(candidate.amount))\(candidate.billingCycle.shortSuffix)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    } else if ocrEmptyHint {
                        Text(NSLocalizedString("import.none_found", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                    }

                    // Privacy reassurance pill
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(Color(hex: "#34D399"))
                        Text(NSLocalizedString("onboarding.privacy_note", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.78))
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 22)
            }
            .scrollBounceBehavior(.always)

            VStack(spacing: 10) {
                Button {
                    Task {
                        _ = await NotificationManager.shared.requestAuthorization()
                        finishOnboarding()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                        Text(NSLocalizedString("onboarding.finish_cta", comment: ""))
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(Color(hex: "#0B1120"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .white.opacity(0.2), radius: 14, y: 6)
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.96))
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Helpers

    private func togglePreset(_ preset: ServicePreset) {
        withAnimation(AppMotion.bouncy) {
            if selectedPresets.contains(preset) {
                selectedPresets.remove(preset)
                quotaHintVisible = false
                triggerHaptic(.medium)
            } else if selectedPresets.count < remainingFreeSlots {
                selectedPresets.insert(preset)
                quotaHintVisible = false
                triggerHaptic(.medium)
            } else {
                quotaHintVisible = true
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }

    private func handlePickedPhoto(_ item: PhotosPickerItem) async {
        isScanningOCR = true
        ocrEmptyHint = false
        defer { isScanningOCR = false }

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            let parsed = await ScreenshotOCRParser.recognizeAndParse(image: image)
            ocrCandidates = parsed
            ocrEmptyHint = parsed.isEmpty
            if !parsed.isEmpty {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func finishOnboarding() {
        let cal = Calendar.current
        let today = Date()
        let allowed = remainingFreeSlots
        var inserted: [SubscriptionItem] = []

        // Insert OCR-picked items first
        for candidate in ocrCandidates where candidate.isSelected {
            if inserted.count >= allowed { break }
            let item = SubscriptionItem(
                name: candidate.name,
                amount: candidate.amount,
                currency: candidate.currency,
                billingCycle: candidate.billingCycle,
                category: candidate.category,
                nextBillingDate: candidate.nextBillingDate,
                reminderDaysBefore: 1,
                isTrial: candidate.isTrial,
                notes: "Imported from screenshot",
                iconSymbol: candidate.iconSymbol,
                colorHex: candidate.colorHex
            )
            modelContext.insert(item)
            inserted.append(item)
        }

        // Insert quick-picked presets
        for (idx, preset) in selectedPresets.enumerated() {
            if inserted.count >= allowed { break }
            let dueDate = cal.date(byAdding: .day, value: 4 + idx * 5, to: today) ?? today
            let item = SubscriptionItem(
                name: preset.name,
                amount: preset.defaultAmount,
                currency: preset.currency,
                billingCycle: preset.cycle,
                category: preset.category,
                nextBillingDate: dueDate,
                reminderDaysBefore: 1,
                isTrial: false,
                iconSymbol: preset.symbol,
                colorHex: preset.colorHex
            )
            modelContext.insert(item)
            inserted.append(item)
        }

        try? modelContext.save()
        if !inserted.isEmpty {
            Task {
                await NotificationManager.shared.rescheduleAll(inserted)
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onComplete()
    }

    @MainActor
    private func runKineticLoop() async {
        let haptics = KineticHapticEngine()
        defer { haptics.stop() }

        while !Task.isCancelled {
            guard currentPage == 0 else {
                try? await Task.sleep(nanoseconds: 300_000_000)
                continue
            }

            typedText = ""
            cursorVisible = true

            // 1. Cursor blinks twice over ~1.0s with gentle pulse before typing begins
            for _ in 0..<2 {
                guard !Task.isCancelled, currentPage == 0 else { break }
                cursorVisible = true
                haptics.tick(intensity: 0.45, sharpness: 0.3)
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled, currentPage == 0 else { break }
                cursorVisible = false
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            guard !Task.isCancelled else { return }
            guard currentPage == 0 else { continue }

            // 2. Rapid silky left-to-right character typing with crisp CoreHaptics ticks
            cursorVisible = true
            let phrase = currentFullPhrase
            let characters = Array(phrase)
            let isCJK = characters.contains { $0.unicodeScalars.first.map { $0.value >= 0x4E00 && $0.value <= 0x9FFF } ?? false }
            let typeDelayNs: UInt64 = isCJK ? 65_000_000 : 38_000_000
            let eraseDelayNs: UInt64 = isCJK ? 38_000_000 : 22_000_000
            let typeHapticStride = isCJK ? 1 : 2
            let eraseHapticStride = isCJK ? 1 : 2

            for (idx, char) in characters.enumerated() {
                guard !Task.isCancelled else { return }
                if currentPage != 0 { break }
                typedText.append(char)
                if idx.isMultiple(of: typeHapticStride) && char != " " {
                    haptics.tick(intensity: 0.90, sharpness: 0.85)
                }
                try? await Task.sleep(nanoseconds: typeDelayNs)
            }
            guard !Task.isCancelled else { return }
            guard currentPage == 0 else { continue }

            // Satisfying landing thump when the full line completes
            haptics.tick(intensity: 0.95, sharpness: 0.40)

            // 3. Brief reading pause with a gentle cursor breath
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled, currentPage == 0 else { continue }
            cursorVisible = false
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled, currentPage == 0 else { continue }
            cursorVisible = true
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled, currentPage == 0 else { continue }

            // 4. Snappy right-to-left retraction back to the lone cursor
            var removedCount = 0
            while !typedText.isEmpty {
                guard !Task.isCancelled else { return }
                if currentPage != 0 { break }
                typedText.removeLast()
                removedCount += 1
                if removedCount.isMultiple(of: eraseHapticStride) {
                    haptics.tick(intensity: 0.65, sharpness: 0.90)
                }
                try? await Task.sleep(nanoseconds: eraseDelayNs)
            }
            guard !Task.isCancelled else { return }
            guard currentPage == 0 else { continue }

            // 5. Shift ambient aurora color to next phrase
            withAnimation(.easeInOut(duration: 0.55)) {
                phraseIndex = (phraseIndex + 1) % kineticPhrases.count
            }
            try? await Task.sleep(nanoseconds: 140_000_000)
        }
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
