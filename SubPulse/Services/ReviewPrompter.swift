import Foundation

/// High-value-moment App Store review prompt guard.
/// Prompts at most once per app version and once every 90 days, only after the user has saved >= 2 items.
enum ReviewPrompter {
    private static let lastPromptedDateKey = "reviewPrompter.lastPromptedDate"
    private static let lastPromptedVersionKey = "reviewPrompter.lastPromptedVersion"

    static let minimumItemCount = 2
    static let cooldownDays = 90

    static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static func shouldRequestReview(
        itemCount: Int,
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> Bool {
        guard itemCount >= minimumItemCount else { return false }

        if let lastVersion = defaults.string(forKey: lastPromptedVersionKey),
           lastVersion == currentAppVersion {
            return false
        }

        if let lastDate = defaults.object(forKey: lastPromptedDateKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: lastDate, to: now).day ?? 0
            if days < cooldownDays {
                return false
            }
        }

        return true
    }

    static func consumeIfEligible(
        itemCount: Int,
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> Bool {
        guard shouldRequestReview(itemCount: itemCount, defaults: defaults, now: now) else {
            return false
        }
        defaults.set(now, forKey: lastPromptedDateKey)
        defaults.set(currentAppVersion, forKey: lastPromptedVersionKey)
        return true
    }
}
