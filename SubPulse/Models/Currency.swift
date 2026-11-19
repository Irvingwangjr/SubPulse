import Foundation

/// Supported currencies with display metadata and offline reference FX rates (relative to 1 USD).
/// Keeping conversion offline avoids external API keys, network dependencies, and privacy disclosures.
enum Currency: String, CaseIterable, Identifiable, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"
    case cny = "CNY"
    case hkd = "HKD"
    case sgd = "SGD"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .cad: return "CA$"
        case .aud: return "A$"
        case .cny: return "CN¥"
        case .hkd: return "HK$"
        case .sgd: return "S$"
        }
    }

    var displayName: String {
        switch self {
        case .usd: return "US Dollar (USD)"
        case .eur: return "Euro (EUR)"
        case .gbp: return "British Pound (GBP)"
        case .jpy: return "Japanese Yen (JPY)"
        case .cad: return "Canadian Dollar (CAD)"
        case .aud: return "Australian Dollar (AUD)"
        case .cny: return "Chinese Yuan (CNY)"
        case .hkd: return "Hong Kong Dollar (HKD)"
        case .sgd: return "Singapore Dollar (SGD)"
        }
    }

    var flag: String {
        switch self {
        case .usd: return "🇺🇸"
        case .eur: return "🇪🇺"
        case .gbp: return "🇬🇧"
        case .jpy: return "🇯🇵"
        case .cad: return "🇨🇦"
        case .aud: return "🇦🇺"
        case .cny: return "🇨🇳"
        case .hkd: return "🇭🇰"
        case .sgd: return "🇸🇬"
        }
    }

    /// Approximate units per 1 USD for offline portfolio rollups.
    var unitsPerUSD: Double {
        switch self {
        case .usd: return 1.0
        case .eur: return 0.92
        case .gbp: return 0.79
        case .jpy: return 152.0
        case .cad: return 1.38
        case .aud: return 1.53
        case .cny: return 7.24
        case .hkd: return 7.78
        case .sgd: return 1.34
        }
    }

    var usesDecimals: Bool {
        self != .jpy
    }

    func convert(_ amount: Double, to target: Currency) -> Double {
        if self == target { return amount }
        let amountInUSD = amount / self.unitsPerUSD
        return amountInUSD * target.unitsPerUSD
    }

    func formatted(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = rawValue
        formatter.currencySymbol = symbol
        formatter.maximumFractionDigits = usesDecimals ? 2 : 0
        formatter.minimumFractionDigits = usesDecimals ? 2 : 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)\(String(format: "%.2f", amount))"
    }

    static func from(code: String) -> Currency {
        Currency(rawValue: code.uppercased()) ?? .usd
    }
}
