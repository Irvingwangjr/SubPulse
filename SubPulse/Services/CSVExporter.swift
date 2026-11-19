import Foundation

enum CSVExporter {
    static func exportURL(for items: [SubscriptionItem], baseCurrency: Currency) -> URL? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        var rows: [String] = [
            "Name,Category,Amount,Currency,BillingCycle,MonthlyEquivalent(\(baseCurrency.rawValue)),NextBillingDate,IsTrial,ReminderDaysBefore,Notes"
        ]

        for item in items {
            let monthly = String(format: "%.2f", item.monthlyAmount(in: baseCurrency))
            let row = [
                escape(item.name),
                escape(item.category.rawValue),
                String(format: "%.2f", item.amount),
                item.currencyCode,
                item.billingCycleRaw,
                monthly,
                formatter.string(from: item.nextBillingDate),
                item.isTrial ? "Yes" : "No",
                String(item.reminderDaysBefore),
                escape(item.notes)
            ].joined(separator: ",")
            rows.append(row)
        }

        let csvText = rows.joined(separator: "\n")
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SubPulse-Export-\(formatter.string(from: Date())).csv")

        do {
            try csvText.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    private static func escape(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: "\"", with: "\"\"")
        if cleaned.contains(",") || cleaned.contains("\"") || cleaned.contains("\n") {
            return "\"\(cleaned)\""
        }
        return cleaned
    }
}
