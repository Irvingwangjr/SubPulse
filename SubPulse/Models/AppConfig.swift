import Foundation

enum AppConfig {
    static let freeSubscriptionLimit = 5

    // Live GitHub Pages URLs (served from /docs on main branch)
    static let privacyPolicyURL = URL(string: "https://irvingwangjr.github.io/SubPulse/privacy.html")!
    static let termsOfServiceURL = URL(string: "https://irvingwangjr.github.io/SubPulse/terms.html")!
    static let supportURL = URL(string: "https://irvingwangjr.github.io/SubPulse/")!
    static let supportEmail = "kiinkrft@gmail.com"

    enum ProductID {
        static let proMonthly = "com.irvingwangjr.subpulse.pro.monthly"
        static let proYearly = "com.irvingwangjr.subpulse.pro.yearly"
        static let all: [String] = [proMonthly, proYearly]
    }
}
