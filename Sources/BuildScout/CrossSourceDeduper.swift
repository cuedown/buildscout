import Foundation

enum CrossSourceDeduper {
    static func dedupe(_ results: [HuntResult]) -> [HuntResult] {
        var byIdentity: [String: HuntResult] = [:]
        var order: [String] = []

        for result in results {
            let key = identity(for: result)

            if let existing = byIdentity[key] {
                byIdentity[key] = merge(existing, result)
            } else {
                byIdentity[key] = result
                order.append(key)
            }
        }

        return order.compactMap { byIdentity[$0] }
    }

    static func identity(for result: HuntResult) -> String {
        if let vin = result.vin?.uppercased(), vin.count == 17 {
            return "vin:\(vin)"
        }

        if !result.url.isEmpty {
            let normalizedURL = result.url
                .lowercased()
                .replacingOccurrences(of: "http://", with: "https://")
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return "url:\(normalizedURL)"
        }

        let inferred = HuntNormalization.vehicleListing(
            from: result,
            defaultLocation: result.location ?? ""
        )

        let titleTokens = normalizedTokens(result.title)
        let vehicleTokens = normalizedTokens(
            "\(inferred.year) \(inferred.make) \(inferred.model)"
        )

        let tokens = vehicleTokens.isEmpty ? titleTokens : vehicleTokens
        let priceBucket = result.price.map { Int(($0 / 100).rounded()) } ?? -1
        let odoBucket = result.odometerKM.map { Int(($0 / 5_000).rounded()) } ?? -1
        let location = normalizedTokens(result.location ?? "").prefix(2).joined(separator: "-")

        return "fp:\(tokens.prefix(5).joined(separator: "-"))|p\(priceBucket)|o\(odoBucket)|l\(location)"
    }

    private static func merge(_ lhs: HuntResult, _ rhs: HuntResult) -> HuntResult {
        let richer: HuntResult
        let other: HuntResult

        if richness(rhs) > richness(lhs) {
            richer = rhs
            other = lhs
        } else {
            richer = lhs
            other = rhs
        }

        var merged = richer
        let providers = Set(
            (lhs.provider + " + " + rhs.provider)
                .components(separatedBy: " + ")
                .filter { !$0.isEmpty }
        )
        merged.provider = providers.sorted().joined(separator: " + ")

        if merged.url.isEmpty { merged.url = other.url }
        if merged.snippet.isEmpty { merged.snippet = other.snippet }
        if merged.price == nil { merged.price = other.price }
        if merged.currency == nil { merged.currency = other.currency }
        if merged.location == nil { merged.location = other.location }
        if merged.thumbnailURL == nil { merged.thumbnailURL = other.thumbnailURL }
        if merged.sourceDomain == nil { merged.sourceDomain = other.sourceDomain }
        if merged.vin == nil { merged.vin = other.vin }
        if merged.odometerKM == nil { merged.odometerKM = other.odometerKM }
        if merged.drivetrain == nil { merged.drivetrain = other.drivetrain }
        if merged.transmission == nil { merged.transmission = other.transmission }

        return merged
    }

    private static func richness(_ result: HuntResult) -> Int {
        var score = 0
        if !result.url.isEmpty { score += 3 }
        if !result.snippet.isEmpty { score += 1 }
        if result.price != nil { score += 2 }
        if result.location != nil { score += 1 }
        if result.thumbnailURL != nil { score += 1 }
        if result.vin != nil { score += 4 }
        if result.odometerKM != nil { score += 1 }
        if result.drivetrain != nil { score += 1 }
        if result.transmission != nil { score += 1 }
        return score
    }

    private static func normalizedTokens(_ raw: String) -> [String] {
        let stop = Set([
            "for", "sale", "car", "vehicle", "used", "project", "the",
            "and", "with", "cad", "obo"
        ])

        return raw
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count > 1 && !stop.contains($0) }
    }
}
