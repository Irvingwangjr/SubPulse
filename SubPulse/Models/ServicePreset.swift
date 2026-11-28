import Foundation

struct ServicePreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let defaultAmount: Double
    let currency: Currency
    let cycle: BillingCycle
    let category: SubscriptionCategory
    let symbol: String
    let colorHex: String

    private static var isJapanLocale: Bool {
        Locale.current.language.languageCode?.identifier == "ja"
            || Locale.current.region?.identifier == "JP"
            || Locale.current.currency?.identifier.uppercased() == "JPY"
    }

    private static var isEuroLocale: Bool {
        Locale.current.currency?.identifier.uppercased() == "EUR"
            || Locale.current.language.languageCode?.identifier == "de"
    }

    static let japanPopular: [ServicePreset] = [
        ServicePreset(name: "Amazonプライム", defaultAmount: 600, currency: .jpy, cycle: .monthly, category: .utilities, symbol: "shippingbox.fill", colorHex: "#FF9900"),
        ServicePreset(name: "Netflix スタンダード", defaultAmount: 1590, currency: .jpy, cycle: .monthly, category: .streaming, symbol: "play.tv.fill", colorHex: "#E50914"),
        ServicePreset(name: "YouTube Premium", defaultAmount: 1280, currency: .jpy, cycle: .monthly, category: .streaming, symbol: "play.rectangle.fill", colorHex: "#FF0000"),
        ServicePreset(name: "Spotify Premium", defaultAmount: 980, currency: .jpy, cycle: .monthly, category: .music, symbol: "music.note", colorHex: "#1DB954"),
        ServicePreset(name: "iCloud+ 200GB", defaultAmount: 450, currency: .jpy, cycle: .monthly, category: .cloud, symbol: "icloud.fill", colorHex: "#0A84FF"),
        ServicePreset(name: "Apple One", defaultAmount: 1200, currency: .jpy, cycle: .monthly, category: .cloud, symbol: "apple.logo", colorHex: "#5E5CE6"),
        ServicePreset(name: "ChatGPT Plus", defaultAmount: 3000, currency: .jpy, cycle: .monthly, category: .aiTools, symbol: "sparkles", colorHex: "#10A37F"),
        ServicePreset(name: "Claude Pro", defaultAmount: 3000, currency: .jpy, cycle: .monthly, category: .aiTools, symbol: "brain.head.profile", colorHex: "#D97757"),
        ServicePreset(name: "U-NEXT", defaultAmount: 2189, currency: .jpy, cycle: .monthly, category: .streaming, symbol: "film.fill", colorHex: "#00A0E9"),
        ServicePreset(name: "ABEMAプレミアム", defaultAmount: 1080, currency: .jpy, cycle: .monthly, category: .streaming, symbol: "tv.fill", colorHex: "#00C853"),
        ServicePreset(name: "dアニメストア", defaultAmount: 550, currency: .jpy, cycle: .monthly, category: .streaming, symbol: "sparkles.tv.fill", colorHex: "#FF6B00"),
        ServicePreset(name: "Nintendo Switch Online", defaultAmount: 2400, currency: .jpy, cycle: .yearly, category: .gaming, symbol: "gamecontroller.fill", colorHex: "#E60012")
    ]

    static let euroPopular: [ServicePreset] = [
        ServicePreset(name: "Netflix Standard", defaultAmount: 13.99, currency: .eur, cycle: .monthly, category: .streaming, symbol: "play.tv.fill", colorHex: "#E50914"),
        ServicePreset(name: "Spotify Premium", defaultAmount: 10.99, currency: .eur, cycle: .monthly, category: .music, symbol: "music.note", colorHex: "#1DB954"),
        ServicePreset(name: "Amazon Prime", defaultAmount: 8.99, currency: .eur, cycle: .monthly, category: .utilities, symbol: "shippingbox.fill", colorHex: "#FF9900"),
        ServicePreset(name: "iCloud+ 200GB", defaultAmount: 2.99, currency: .eur, cycle: .monthly, category: .cloud, symbol: "icloud.fill", colorHex: "#0A84FF"),
        ServicePreset(name: "YouTube Premium", defaultAmount: 12.99, currency: .eur, cycle: .monthly, category: .streaming, symbol: "play.rectangle.fill", colorHex: "#FF0000"),
        ServicePreset(name: "ChatGPT Plus", defaultAmount: 22.99, currency: .eur, cycle: .monthly, category: .aiTools, symbol: "sparkles", colorHex: "#10A37F"),
        ServicePreset(name: "Claude Pro", defaultAmount: 21.99, currency: .eur, cycle: .monthly, category: .aiTools, symbol: "brain.head.profile", colorHex: "#D97757"),
        ServicePreset(name: "Apple One", defaultAmount: 19.95, currency: .eur, cycle: .monthly, category: .cloud, symbol: "apple.logo", colorHex: "#5E5CE6"),
        ServicePreset(name: "Disney+", defaultAmount: 9.99, currency: .eur, cycle: .monthly, category: .streaming, symbol: "wand.and.stars", colorHex: "#113CCF"),
        ServicePreset(name: "Notion Plus", defaultAmount: 10.00, currency: .eur, cycle: .monthly, category: .productivity, symbol: "doc.text.fill", colorHex: "#3A3A3C"),
        ServicePreset(name: "Nintendo Online", defaultAmount: 19.99, currency: .eur, cycle: .yearly, category: .gaming, symbol: "gamecontroller.fill", colorHex: "#E60012"),
        ServicePreset(name: "Fitnessstudio", defaultAmount: 39.90, currency: .eur, cycle: .monthly, category: .fitness, symbol: "figure.run", colorHex: "#FF6B35")
    ]

    static let globalPopular: [ServicePreset] = [
        ServicePreset(name: "ChatGPT Plus", defaultAmount: 20.00, currency: .usd, cycle: .monthly, category: .aiTools, symbol: "sparkles", colorHex: "#10A37F"),
        ServicePreset(name: "Claude Pro", defaultAmount: 20.00, currency: .usd, cycle: .monthly, category: .aiTools, symbol: "brain.head.profile", colorHex: "#D97757"),
        ServicePreset(name: "iCloud+ 200GB", defaultAmount: 2.99, currency: .usd, cycle: .monthly, category: .cloud, symbol: "icloud.fill", colorHex: "#0A84FF"),
        ServicePreset(name: "Netflix Standard", defaultAmount: 15.49, currency: .usd, cycle: .monthly, category: .streaming, symbol: "play.tv.fill", colorHex: "#E50914"),
        ServicePreset(name: "Spotify Premium", defaultAmount: 11.99, currency: .usd, cycle: .monthly, category: .music, symbol: "music.note", colorHex: "#1DB954"),
        ServicePreset(name: "YouTube Premium", defaultAmount: 13.99, currency: .usd, cycle: .monthly, category: .streaming, symbol: "play.rectangle.fill", colorHex: "#FF0000"),
        ServicePreset(name: "GitHub Copilot", defaultAmount: 10.00, currency: .usd, cycle: .monthly, category: .productivity, symbol: "chevron.left.forwardslash.chevron.right", colorHex: "#24292F"),
        ServicePreset(name: "Notion Plus", defaultAmount: 10.00, currency: .usd, cycle: .monthly, category: .productivity, symbol: "doc.text.fill", colorHex: "#3A3A3C"),
        ServicePreset(name: "Apple One", defaultAmount: 19.95, currency: .usd, cycle: .monthly, category: .cloud, symbol: "apple.logo", colorHex: "#5E5CE6"),
        ServicePreset(name: "Amazon Prime", defaultAmount: 139.00, currency: .usd, cycle: .yearly, category: .utilities, symbol: "shippingbox.fill", colorHex: "#FF9900"),
        ServicePreset(name: "Nintendo Online", defaultAmount: 19.99, currency: .usd, cycle: .yearly, category: .gaming, symbol: "gamecontroller.fill", colorHex: "#E60012"),
        ServicePreset(name: "Gym Membership", defaultAmount: 45.00, currency: .usd, cycle: .monthly, category: .fitness, symbol: "figure.run", colorHex: "#FF6B35")
    ]

    static var popular: [ServicePreset] {
        if isJapanLocale { return japanPopular }
        if isEuroLocale { return euroPopular }
        return globalPopular
    }

    static var allKnownForMatching: [ServicePreset] {
        japanPopular + globalPopular + euroPopular
    }

    static func sampleItems() -> [SubscriptionItem] {
        let cal = Calendar.current
        let today = Date()

        if isJapanLocale {
            return [
                SubscriptionItem(
                    name: "Netflix スタンダード",
                    amount: 1590,
                    currency: .jpy,
                    billingCycle: .monthly,
                    category: .streaming,
                    nextBillingDate: cal.date(byAdding: .day, value: 3, to: today) ?? today,
                    reminderDaysBefore: 1,
                    isTrial: false,
                    notes: "家族で共有中",
                    iconSymbol: "play.tv.fill",
                    colorHex: "#E50914"
                ),
                SubscriptionItem(
                    name: "U-NEXT",
                    amount: 2189,
                    currency: .jpy,
                    billingCycle: .monthly,
                    category: .streaming,
                    nextBillingDate: cal.date(byAdding: .day, value: 2, to: today) ?? today,
                    reminderDaysBefore: 1,
                    isTrial: true,
                    notes: "無料トライアル終了前に確認",
                    iconSymbol: "film.fill",
                    colorHex: "#00A0E9"
                )
            ]
        }

        return [
            SubscriptionItem(
                name: "ChatGPT Plus",
                amount: 20.00,
                currency: .usd,
                billingCycle: .monthly,
                category: .aiTools,
                nextBillingDate: cal.date(byAdding: .day, value: 3, to: today) ?? today,
                reminderDaysBefore: 1,
                isTrial: false,
                notes: "Work & research assistant",
                iconSymbol: "sparkles",
                colorHex: "#10A37F"
            ),
            SubscriptionItem(
                name: "Spotify",
                amount: 10.99,
                currency: .eur,
                billingCycle: .monthly,
                category: .music,
                nextBillingDate: cal.date(byAdding: .day, value: 2, to: today) ?? today,
                reminderDaysBefore: 1,
                isTrial: true,
                notes: "Cancel before EU trial converts",
                iconSymbol: "music.note",
                colorHex: "#1DB954"
            )
        ]
    }
}
