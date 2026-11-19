import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleReminder(for item: SubscriptionItem) async {
        let center = UNUserNotificationCenter.current()
        let identifier = notificationID(for: item.id)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let calendar = Calendar.current
        guard let fireDay = calendar.date(byAdding: .day, value: -item.reminderDaysBefore, to: item.nextBillingDate) else {
            return
        }

        var components = calendar.dateComponents([.year, .month, .day], from: fireDay)
        components.hour = 9
        components.minute = 0

        guard let scheduledDate = calendar.date(from: components), scheduledDate > Date() else {
            return
        }

        let content = UNMutableNotificationContent()
        if item.isTrial {
            content.title = String(format: NSLocalizedString("notif.trial_title", comment: ""), item.name)
            content.body = String(
                format: NSLocalizedString("notif.trial_body", comment: ""),
                item.currency.formatted(item.amount),
                item.reminderDaysBefore
            )
        } else {
            content.title = String(format: NSLocalizedString("notif.renewal_title", comment: ""), item.name)
            content.body = String(
                format: NSLocalizedString("notif.renewal_body", comment: ""),
                item.currency.formatted(item.amount),
                item.reminderDaysBefore
            )
        }
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelReminder(for id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID(for: id)])
    }

    func rescheduleAll(_ items: [SubscriptionItem]) async {
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }
        for item in items {
            await scheduleReminder(for: item)
        }
    }

    private func notificationID(for id: UUID) -> String {
        "subpulse.renewal.\(id.uuidString)"
    }
}
