import Foundation
import SwiftData
import SwiftUI

enum BillingCycle: String, CaseIterable, Identifiable, Codable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .weekly: return NSLocalizedString("cycle.weekly", comment: "")
        case .monthly: return NSLocalizedString("cycle.monthly", comment: "")
        case .quarterly: return NSLocalizedString("cycle.quarterly", comment: "")
        case .yearly: return NSLocalizedString("cycle.yearly", comment: "")
        }
    }

    var shortSuffix: String {
        switch self {
        case .weekly: return "/wk"
        case .monthly: return "/mo"
        case .quarterly: return "/qtr"
        case .yearly: return "/yr"
        }
    }

    /// Normalize a recurring amount into its monthly equivalent.
    func monthlyEquivalent(of amount: Double) -> Double {
        switch self {
        case .weekly: return amount * 52.0 / 12.0
        case .monthly: return amount
        case .quarterly: return amount / 3.0
        case .yearly: return amount / 12.0
        }
    }

    /// Normalize a recurring amount into its yearly equivalent.
    func yearlyEquivalent(of amount: Double) -> Double {
        switch self {
        case .weekly: return amount * 52.0
        case .monthly: return amount * 12.0
        case .quarterly: return amount * 4.0
        case .yearly: return amount
        }
    }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

enum SubscriptionCategory: String, CaseIterable, Identifiable, Codable {
    case streaming
    case aiTools
    case productivity
    case cloud
    case music
    case fitness
    case gaming
    case utilities
    case other

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .streaming: return NSLocalizedString("category.streaming", comment: "")
        case .aiTools: return NSLocalizedString("category.ai_tools", comment: "")
        case .productivity: return NSLocalizedString("category.productivity", comment: "")
        case .cloud: return NSLocalizedString("category.cloud", comment: "")
        case .music: return NSLocalizedString("category.music", comment: "")
        case .fitness: return NSLocalizedString("category.fitness", comment: "")
        case .gaming: return NSLocalizedString("category.gaming", comment: "")
        case .utilities: return NSLocalizedString("category.utilities", comment: "")
        case .other: return NSLocalizedString("category.other", comment: "")
        }
    }

    var defaultSymbol: String {
        switch self {
        case .streaming: return "play.tv.fill"
        case .aiTools: return "sparkles"
        case .productivity: return "checkmark.seal.fill"
        case .cloud: return "icloud.fill"
        case .music: return "music.note"
        case .fitness: return "figure.run"
        case .gaming: return "gamecontroller.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .other: return "creditcard.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .streaming: return Color(hex: "#E50914")
        case .aiTools: return Color(hex: "#10A37F")
        case .productivity: return Color(hex: "#5E6AD2")
        case .cloud: return Color(hex: "#0A84FF")
        case .music: return Color(hex: "#1DB954")
        case .fitness: return Color(hex: "#FF6B35")
        case .gaming: return Color(hex: "#AF52DE")
        case .utilities: return Color(hex: "#FF9F0A")
        case .other: return Color(hex: "#8E8E93")
        }
    }

    var defaultHex: String {
        switch self {
        case .streaming: return "#E50914"
        case .aiTools: return "#10A37F"
        case .productivity: return "#5E6AD2"
        case .cloud: return "#0A84FF"
        case .music: return "#1DB954"
        case .fitness: return "#FF6B35"
        case .gaming: return "#AF52DE"
        case .utilities: return "#FF9F0A"
        case .other: return "#8E8E93"
        }
    }
}

@Model
final class SubscriptionItem {
    var id: UUID
    var name: String
    var amount: Double
    var currencyCode: String
    var billingCycleRaw: String
    var categoryRaw: String
    var nextBillingDate: Date
    var reminderDaysBefore: Int
    var isTrial: Bool
    var notes: String
    var iconSymbol: String
    var colorHex: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        currency: Currency = .usd,
        billingCycle: BillingCycle = .monthly,
        category: SubscriptionCategory = .other,
        nextBillingDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
        reminderDaysBefore: Int = 1,
        isTrial: Bool = false,
        notes: String = "",
        iconSymbol: String? = nil,
        colorHex: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currencyCode = currency.rawValue
        self.billingCycleRaw = billingCycle.rawValue
        self.categoryRaw = category.rawValue
        self.nextBillingDate = nextBillingDate
        self.reminderDaysBefore = reminderDaysBefore
        self.isTrial = isTrial
        self.notes = notes
        self.iconSymbol = iconSymbol ?? category.defaultSymbol
        self.colorHex = colorHex ?? category.defaultHex
        self.createdAt = createdAt
    }

    var currency: Currency {
        get { Currency.from(code: currencyCode) }
        set { currencyCode = newValue.rawValue }
    }

    var billingCycle: BillingCycle {
        get { BillingCycle(rawValue: billingCycleRaw) ?? .monthly }
        set { billingCycleRaw = newValue.rawValue }
    }

    var category: SubscriptionCategory {
        get { SubscriptionCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var accentColor: Color {
        Color(hex: colorHex)
    }

    var daysUntilRenewal: Int {
        let calendar = Calendar.current
        let startToday = calendar.startOfDay(for: Date())
        let startBilling = calendar.startOfDay(for: nextBillingDate)
        return calendar.dateComponents([.day], from: startToday, to: startBilling).day ?? 0
    }

    func monthlyAmount(in baseCurrency: Currency) -> Double {
        let converted = currency.convert(amount, to: baseCurrency)
        return billingCycle.monthlyEquivalent(of: converted)
    }

    func yearlyAmount(in baseCurrency: Currency) -> Double {
        let converted = currency.convert(amount, to: baseCurrency)
        return billingCycle.yearlyEquivalent(of: converted)
    }

    func advanceBillingDate() {
        var candidate = billingCycle.nextDate(after: nextBillingDate)
        let today = Calendar.current.startOfDay(for: Date())
        while Calendar.current.startOfDay(for: candidate) < today {
            candidate = billingCycle.nextDate(after: candidate)
        }
        nextBillingDate = candidate
        if isTrial {
            isTrial = false
        }
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (10, 132, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
