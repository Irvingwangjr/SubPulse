import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ShareableCardImage: Transferable {
    let pngData: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.pngData
        }
    }
}

/// Privacy-safe 4:5 social share card showing aggregate spend & top category breakdown only.
struct SpendShareCardGraphic: View {
    let baseCurrency: Currency
    let monthlyTotal: Double
    let yearlyTotal: Double
    let dailyTotal: Double
    let coffeeEquivalents: Int
    let activeCount: Int
    let topCategories: [(category: SubscriptionCategory, monthlyTotal: Double)]

    private var totalCategorySpend: Double {
        max(0.01, topCategories.reduce(0) { $0 + $1.monthlyTotal })
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#0F172A"),
                    Color(hex: "#1E3A8A"),
                    Color(hex: "#5B21B6")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(hex: "#38BDF8").opacity(0.28))
                .frame(width: 220, height: 220)
                .blur(radius: 48)
                .offset(x: 110, y: -140)

            Circle()
                .fill(Color(hex: "#F472B6").opacity(0.24))
                .frame(width: 200, height: 200)
                .blur(radius: 52)
                .offset(x: -110, y: 160)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SubPulse")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(NSLocalizedString("share.card_subtitle", comment: ""))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    Text("\(baseCurrency.flag) \(baseCurrency.rawValue)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.16), in: Capsule())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("overview.yearly_projection", comment: ""))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))

                    Text(baseCurrency.formatted(yearlyTotal))
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    if monthlyTotal > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.caption)
                            Text(String(
                                format: NSLocalizedString("overview.daily_coffee", comment: ""),
                                baseCurrency.formatted(dailyTotal),
                                coffeeEquivalents
                            ))
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(.white.opacity(0.94))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.15), in: Capsule())
                    }
                }

                HStack(spacing: 12) {
                    statPill(
                        label: NSLocalizedString("overview.monthly_spend", comment: ""),
                        value: baseCurrency.formatted(monthlyTotal)
                    )
                    statPill(
                        label: NSLocalizedString("overview.active_subs", comment: ""),
                        value: "\(activeCount)"
                    )
                }

                if !topCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("overview.category_breakdown", comment: ""))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.8))

                        ForEach(topCategories.prefix(3), id: \.category) { entry in
                            let ratio = min(1.0, max(0.08, entry.monthlyTotal / totalCategorySpend))
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(entry.category.localizedTitle)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(baseCurrency.formatted(entry.monthlyTotal))\(BillingCycle.monthly.shortSuffix)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(.white.opacity(0.16))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(entry.category.tintColor)
                                        .frame(width: 280 * ratio, height: 8)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                    Text(NSLocalizedString("share.watermark", comment: ""))
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(.white.opacity(0.72))
            }
            .padding(24)
        }
        .frame(width: 360, height: 450)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        )
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct SpendShareCardSheet: View {
    @Environment(\.dismiss) private var dismiss

    let baseCurrency: Currency
    let monthlyTotal: Double
    let yearlyTotal: Double
    let dailyTotal: Double
    let coffeeEquivalents: Int
    let activeCount: Int
    let topCategories: [(category: SubscriptionCategory, monthlyTotal: Double)]

    @State private var renderedImage: UIImage?
    @State private var shareableImage: ShareableCardImage?

    private var cardGraphic: SpendShareCardGraphic {
        SpendShareCardGraphic(
            baseCurrency: baseCurrency,
            monthlyTotal: monthlyTotal,
            yearlyTotal: yearlyTotal,
            dailyTotal: dailyTotal,
            coffeeEquivalents: coffeeEquivalents,
            activeCount: activeCount,
            topCategories: topCategories
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackgroundView(
                    accent: Color(hex: "#2563EB"),
                    secondaryAccent: Color(hex: "#7C3AED")
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        cardGraphic
                            .shadow(color: Color(hex: "#1E3A8A").opacity(0.32), radius: 22, y: 12)
                            .scaleEffect(0.95)

                        Text(NSLocalizedString("share.privacy_note", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        if let shareableImage, let renderedImage {
                            ShareLink(
                                item: shareableImage,
                                preview: SharePreview(
                                    NSLocalizedString("share.card_title", comment: ""),
                                    image: Image(uiImage: renderedImage)
                                )
                            ) {
                                Label(NSLocalizedString("share.cta", comment: ""), systemImage: "square.and.arrow.up")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
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
                            .padding(.horizontal, 20)
                        } else {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(NSLocalizedString("share.card_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("action.cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
            .task {
                renderCardImage()
            }
        }
    }

    @MainActor
    private func renderCardImage() {
        let renderer = ImageRenderer(content: cardGraphic)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage, let data = uiImage.pngData() {
            renderedImage = uiImage
            shareableImage = ShareableCardImage(pngData: data)
        }
    }
}
