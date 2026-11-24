import Foundation
import UIKit
import Vision

struct ParsedSubscriptionCandidate: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var amount: Double
    var currency: Currency
    var billingCycle: BillingCycle
    var category: SubscriptionCategory
    var nextBillingDate: Date
    var isTrial: Bool
    var iconSymbol: String
    var colorHex: String
    var isSelected: Bool = true
}

enum ScreenshotOCRParser {
    private static let ignoredLines: Set<String> = [
        "subscriptions", "active", "inactive", "expired", "see all plans",
        "cancel subscription", "cancel free trial", "renewal receipts",
        "share with family", "manage", "settings", "edit", "done", "back",
        "apple account", "订阅", "有效", "已过期", "取消订阅", "查看所有方案",
        "续订收据", "与家人共享", "设置", "返回", "完成"
    ]

    static func recognizeAndParse(image: UIImage) async -> [ParsedSubscriptionCandidate] {
        guard let cgImage = image.cgImage else { return [] }
        let lines: [String] = await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "zh-Hans"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let observations = request.results ?? []
                // Sort top-to-bottom (Vision coordinates have origin at bottom-left)
                let sorted = observations.sorted { lhs, rhs in
                    if abs(lhs.boundingBox.midY - rhs.boundingBox.midY) > 0.015 {
                        return lhs.boundingBox.midY > rhs.boundingBox.midY
                    }
                    return lhs.boundingBox.minX < rhs.boundingBox.minX
                }
                return sorted.compactMap { $0.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            } catch {
                return []
            }
        }.value

        return parseLines(lines)
    }

    static func parseText(_ text: String) -> [ParsedSubscriptionCandidate] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parseLines(lines)
    }

    static func parseLines(_ lines: [String]) -> [ParsedSubscriptionCandidate] {
        guard !lines.isEmpty else { return [] }

        var results: [ParsedSubscriptionCandidate] = []
        var consumedIndices: Set<Int> = []

        for (index, line) in lines.enumerated() {
            guard let priceMatch = extractPrice(from: line) else { continue }
            consumedIndices.insert(index)

            // Combine current line + neighbors for cycle, trial, and date clues
            let contextStart = max(0, index - 2)
            let contextEnd = min(lines.count - 1, index + 2)
            let contextLines = Array(lines[contextStart...contextEnd])
            let combinedContext = contextLines.joined(separator: " ")

            // Find the best service name (prefer an unconsumed non-price, non-date line above)
            let name = findBestName(around: index, in: lines, consumed: consumedIndices) ?? "Subscription"
            let cycle = detectCycle(in: combinedContext)
            let isTrial = detectTrial(in: combinedContext)
            let nextDate = detectDate(in: combinedContext)
                ?? Calendar.current.date(byAdding: .day, value: isTrial ? 7 : 30, to: Date())
                ?? Date()

            // Enrich icon/category/color if name matches a popular preset
            let matchedPreset = ServicePreset.popular.first { preset in
                name.localizedCaseInsensitiveContains(preset.name.components(separatedBy: " ").first ?? preset.name)
                    || preset.name.localizedCaseInsensitiveContains(name)
            }

            let category = matchedPreset?.category ?? inferCategory(from: name)
            results.append(
                ParsedSubscriptionCandidate(
                    name: name,
                    amount: priceMatch.amount,
                    currency: priceMatch.currency,
                    billingCycle: cycle,
                    category: category,
                    nextBillingDate: nextDate,
                    isTrial: isTrial,
                    iconSymbol: matchedPreset?.symbol ?? category.defaultSymbol,
                    colorHex: matchedPreset?.colorHex ?? category.defaultHex
                )
            )
        }

        // Deduplicate by lowercase name + amount
        var seen: Set<String> = []
        return results.filter { item in
            let key = "\(item.name.lowercased())|\(String(format: "%.2f", item.amount))"
            return seen.insert(key).inserted
        }
    }

    private static func extractPrice(from text: String) -> (amount: Double, currency: Currency)? {
        let pattern = #"(CA\$|US\$|HK\$|A\$|S\$|CN¥|USD|EUR|GBP|JPY|CAD|AUD|CNY|HKD|SGD|\$|€|£|¥|￥)\s*([0-9]{1,5}(?:[.,][0-9]{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let symbolRange = Range(match.range(at: 1), in: text),
              let numberRange = Range(match.range(at: 2), in: text) else {
            return nil
        }

        let token = String(text[symbolRange]).uppercased()
        let rawNumber = String(text[numberRange]).replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(rawNumber), amount > 0 else { return nil }

        let currency: Currency = {
            switch token {
            case "€", "EUR": return .eur
            case "£", "GBP": return .gbp
            case "¥", "￥", "JPY": return text.contains("元") || text.contains("月") || text.contains("年") ? .cny : .jpy
            case "CN¥", "CNY": return .cny
            case "CA$", "CAD": return .cad
            case "A$", "AUD": return .aud
            case "HK$", "HKD": return .hkd
            case "S$", "SGD": return .sgd
            default: return .usd
            }
        }()

        return (amount, currency)
    }

    private static func findBestName(around priceIndex: Int, in lines: [String], consumed: Set<Int>) -> String? {
        // Look up to 2 lines above first (typical Apple Subscriptions & receipt layout)
        for offset in 1...2 {
            let candidateIdx = priceIndex - offset
            guard candidateIdx >= 0, !consumed.contains(candidateIdx) else { continue }
            let candidate = lines[candidateIdx]
            if isLikelyServiceName(candidate) {
                return candidate
            }
        }

        // Check if the price line itself has a leading service name before the currency symbol
        let current = lines[priceIndex]
        if let stripped = current.components(separatedBy: CharacterSet(charactersIn: "$€£¥￥")).first?
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)),
           stripped.count >= 2,
           isLikelyServiceName(stripped) {
            return stripped
        }

        return nil
    }

    private static func isLikelyServiceName(_ line: String) -> Bool {
        let lower = line.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard lower.count >= 2, lower.count <= 42 else { return false }
        if ignoredLines.contains(lower) { return false }
        if lower.hasPrefix("renews") || lower.hasPrefix("expires") || lower.hasPrefix("billed")
            || lower.hasPrefix("next billing") || lower.hasPrefix("将于") || lower.hasPrefix("续订") {
            return false
        }
        if extractPrice(from: line) != nil { return false }
        return true
    }

    private static func detectCycle(in text: String) -> BillingCycle {
        let lower = text.lowercased()
        if lower.contains("year") || lower.contains("/yr") || lower.contains("annual") || lower.contains("每年") || lower.contains("/年") {
            return .yearly
        }
        if lower.contains("week") || lower.contains("/wk") || lower.contains("每周") || lower.contains("/周") {
            return .weekly
        }
        if lower.contains("quarter") || lower.contains("3 month") || lower.contains("每季") {
            return .quarterly
        }
        return .monthly
    }

    private static func detectTrial(in text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("trial") || lower.contains("free") || lower.contains("试用")
    }

    private static func detectDate(in text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        let now = Calendar.current.startOfDay(for: Date())
        return matches.compactMap(\.date).first { $0 >= now } ?? matches.compactMap(\.date).first
    }

    private static func inferCategory(from name: String) -> SubscriptionCategory {
        let lower = name.lowercased()
        if lower.contains("gpt") || lower.contains("claude") || lower.contains("ai") || lower.contains("midjourney") || lower.contains("perplexity") {
            return .aiTools
        }
        if lower.contains("spotify") || lower.contains("music") || lower.contains("tidal") {
            return .music
        }
        if lower.contains("netflix") || lower.contains("youtube") || lower.contains("disney") || lower.contains("hbo") || lower.contains("hulu") {
            return .streaming
        }
        if lower.contains("icloud") || lower.contains("dropbox") || lower.contains("drive") || lower.contains("one") {
            return .cloud
        }
        if lower.contains("notion") || lower.contains("github") || lower.contains("figma") || lower.contains("adobe") {
            return .productivity
        }
        if lower.contains("gym") || lower.contains("fitness") || lower.contains("strava") {
            return .fitness
        }
        if lower.contains("xbox") || lower.contains("playstation") || lower.contains("nintendo") || lower.contains("steam") {
            return .gaming
        }
        return .other
    }
}
