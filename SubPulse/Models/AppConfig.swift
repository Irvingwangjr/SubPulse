import Foundation

enum AppConfig {
    static let freeSubscriptionLimit = 3

    // Live GitHub Pages URLs (served from /docs on main branch)
    static let appStoreID = "6839481075"
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id6839481075?action=write-review")!
    static let privacyPolicyURL = URL(string: "https://irvingwangjr.github.io/SubPulse/privacy.html")!
    static let termsOfServiceURL = URL(string: "https://irvingwangjr.github.io/SubPulse/terms.html")!
    static let supportURL = URL(string: "https://irvingwangjr.github.io/SubPulse/")!
    static let supportEmail = "kiinkrft@gmail.com"

    enum ProductID {
        static let proMonthly = "com.irvingwangjr.subpulseapp.pro.monthly"
        static let proYearly = "com.irvingwangjr.subpulseapp.pro.yearly"
        static let proLifetime = "com.irvingwangjr.subpulseapp.pro.lifetime"
        static let all: [String] = [proMonthly, proYearly, proLifetime]
    }
}
