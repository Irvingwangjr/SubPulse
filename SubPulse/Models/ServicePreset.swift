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

    static let popular: [ServicePreset] = [
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
        ServicePreset(name: "Gym Membership", defaultAmount: 45.00, currency: .eur, cycle: .monthly, category: .fitness, symbol: "figure.run", colorHex: "#FF6B35")
    ]

    static func sampleItems() -> [SubscriptionItem] {
        let cal = Calendar.current
        let today = Date()
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
