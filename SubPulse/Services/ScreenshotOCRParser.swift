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
        // English
        "subscriptions", "active", "inactive", "expired", "see all plans",
        "cancel subscription", "cancel free trial", "renewal receipts",
        "share with family", "manage", "settings", "edit", "done", "back",
        "apple account",
        // Simplified Chinese
        "订阅", "有效", "已过期", "取消订阅", "查看所有方案",
        "续订收据", "与家人共享", "设置", "返回", "完成",
        // Japanese
        "サブスクリプション", "有効", "期限切れ", "無効", "すべてのプランを表示",
        "サブスクリプションをキャンセル", "無料トライアルをキャンセル",
        "更新の領収書", "ファミリーと共有", "管理", "設定", "編集", "完了", "戻る",
        // German & Spanish
        "abonnements", "aktiv", "abgelaufen", "abo kündigen", "alle abos anzeigen",
        "suscripciones", "activas", "vencidas", "cancelar suscripción", "ver todos los planes"
    ]

    static func recognizeAndParse(image: UIImage) async -> [ParsedSubscriptionCandidate] {
        guard let cgImage = image.cgImage else { return [] }
        let lines: [String] = await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ja-JP", "en-US", "zh-Hans", "de-DE", "es-ES"]

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
            let matchedPreset = ServicePreset.allKnownForMatching.first { preset in
                let primaryToken = preset.name.components(separatedBy: " ").first ?? preset.name
                return name.localizedCaseInsensitiveContains(primaryToken)
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

    private static func containsJapaneseKana(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x3040...0x309F).contains(scalar.value) || (0x30A0...0x30FF).contains(scalar.value)
        }
    }

    /// Parses localized amounts like "1,590", "12,99", "15.49", "2,400.50".
    private static func parseLocalizedAmount(_ raw: String) -> Double? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.contains(",") && cleaned.contains(".") {
            // Standard US/JP format: 1,234.56
            return Double(cleaned.replacingOccurrences(of: ",", with: ""))
        }
        if cleaned.contains(",") {
            let parts = cleaned.split(separator: ",")
            if parts.count == 2, parts[1].count == 2 || parts[1].count == 1 {
                // European decimal comma: 10,99 -> 10.99
                return Double(cleaned.replacingOccurrences(of: ",", with: "."))
            }
            // Thousands separator: 1,590 or 12,000 -> 1590 / 12000
            return Double(cleaned.replacingOccurrences(of: ",", with: ""))
        }
        return Double(cleaned)
    }

    private static func extractPrice(from text: String) -> (amount: Double, currency: Currency)? {
        // 1. Prefix currency formats: ¥1,590, $15.49, €10,99, JPY 980, CN¥18
        let prefixPattern = #"(CA\$|US\$|HK\$|A\$|S\$|CN¥|USD|EUR|GBP|JPY|CAD|AUD|CNY|HKD|SGD|\$|€|£|¥|￥)\s*([0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]{1,2})?|[0-9]{1,6}(?:[.,][0-9]{1,2})?)"#
        if let regex = try? NSRegularExpression(pattern: prefixPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let symbolRange = Range(match.range(at: 1), in: text),
           let numberRange = Range(match.range(at: 2), in: text),
           let amount = parseLocalizedAmount(String(text[numberRange])),
           amount > 0 {
            let token = String(text[symbolRange]).uppercased()
            let currency: Currency = {
                switch token {
                case "€", "EUR": return .eur
                case "£", "GBP": return .gbp
                case "JPY": return .jpy
                case "CN¥", "CNY": return .cny
                case "¥", "￥":
                    if text.contains("円") || containsJapaneseKana(text) {
                        return .jpy
                    }
                    if text.contains("元") || text.contains("人民币") || text.contains("每月") || text.contains("每年") {
                        return .cny
                    }
                    return Locale.current.currency?.identifier.uppercased() == "CNY" ? .cny : .jpy
                case "CA$", "CAD": return .cad
                case "A$", "AUD": return .aud
                case "HK$", "HKD": return .hkd
                case "S$", "SGD": return .sgd
                default: return .usd
                }
            }()
            return (amount, currency)
        }

        // 2. Suffix Japanese Yen / Euro formats: "1,590円", "980 円", "12,99 €"
        let suffixPattern = #"([0-9]{1,3}(?:,[0-9]{3})+|[0-9]{1,6}(?:[.,][0-9]{1,2})?)\s*(円|€|EUR|元)"#
        if let regex = try? NSRegularExpression(pattern: suffixPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let numberRange = Range(match.range(at: 1), in: text),
           let unitRange = Range(match.range(at: 2), in: text),
           let amount = parseLocalizedAmount(String(text[numberRange])),
           amount > 0 {
            let unit = String(text[unitRange]).uppercased()
            let currency: Currency = {
                switch unit {
                case "円": return .jpy
                case "元": return .cny
                default: return .eur
                }
            }()
            return (amount, currency)
        }

        return nil
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
        let statusPrefixes = [
            "renews", "expires", "billed", "next billing",
            "将于", "续订",
            "更新日", "次回請求", "終了日", "無料トライアル終了",
            "verlängert", "läuft ab", "se renueva", "vence"
        ]
        if statusPrefixes.contains(where: { lower.hasPrefix($0) }) {
            return false
        }
        if extractPrice(from: line) != nil { return false }
        return true
    }

    private static func detectCycle(in text: String) -> BillingCycle {
        let lower = text.lowercased()
        if lower.contains("year") || lower.contains("/yr") || lower.contains("annual")
            || lower.contains("每年") || lower.contains("/年") || lower.contains("年額") || lower.contains("年間")
            || lower.contains("jährlich") || lower.contains("/jahr")
            || lower.contains("anual") || lower.contains("/año") {
            return .yearly
        }
        if lower.contains("week") || lower.contains("/wk")
            || lower.contains("每周") || lower.contains("/周") || lower.contains("毎週") || lower.contains("/週")
            || lower.contains("wöchentlich") || lower.contains("semanal") {
            return .weekly
        }
        if lower.contains("quarter") || lower.contains("3 month")
            || lower.contains("每季") || lower.contains("3ヶ月") || lower.contains("四半期")
            || lower.contains("vierteljährlich") || lower.contains("trimestral") {
            return .quarterly
        }
        return .monthly
    }

    private static func detectTrial(in text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("trial") || lower.contains("free")
            || lower.contains("试用")
            || lower.contains("無料") || lower.contains("トライアル") || lower.contains("お試し")
            || lower.contains("probe") || lower.contains("kostenlos")
            || lower.contains("prueba") || lower.contains("gratis")
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
        if lower.contains("spotify") || lower.contains("music") || lower.contains("tidal") || lower.contains("awa") {
            return .music
        }
        if lower.contains("netflix") || lower.contains("youtube") || lower.contains("disney") || lower.contains("hbo")
            || lower.contains("hulu") || lower.contains("u-next") || lower.contains("abema") || lower.contains("dアニメ") || lower.contains("dazn") {
            return .streaming
        }
        if lower.contains("icloud") || lower.contains("dropbox") || lower.contains("drive") || lower.contains("one") {
            return .cloud
        }
        if lower.contains("notion") || lower.contains("github") || lower.contains("figma") || lower.contains("adobe") {
            return .productivity
        }
        if lower.contains("gym") || lower.contains("fitness") || lower.contains("strava") || lower.contains("ジム") {
            return .fitness
        }
        if lower.contains("xbox") || lower.contains("playstation") || lower.contains("nintendo") || lower.contains("steam") {
            return .gaming
        }
        if lower.contains("amazon") || lower.contains("プライム") || lower.contains("楽天") {
            return .utilities
        }
        return .other
    }
}
