import Foundation

private struct HuntObservation: Codable {
    var fingerprint: String
    var title: String
    var url: String
    var firstSeen: Date
    var lastSeen: Date
    var lastPrice: Double?
    var minimumPrice: Double?
    var maximumPrice: Double?
    var seenCount: Int
    var providers: [String]
}

actor HuntHistoryStore {
    static let shared = HuntHistoryStore()

    private var observations: [String: HuntObservation] = [:]
    private var loaded = false

    func enrichAndRecord(_ results: [HuntResult]) -> [HuntResult] {
        loadIfNeeded()

        let now = Date()
        var enriched: [HuntResult] = []
        enriched.reserveCapacity(results.count)

        for original in results {
            var result = original
            let fingerprint = CrossSourceDeduper.identity(for: result)
            let previous = observations[fingerprint]

            result.previousPrice = previous?.lastPrice
            result.seenCount = (previous?.seenCount ?? 0) + 1

            let providers = Set(
                (previous?.providers ?? []) +
                result.provider.components(separatedBy: " + ")
            )

            let price = result.price
            let minimum: Double?
            let maximum: Double?

            if let price {
                minimum = min(previous?.minimumPrice ?? price, price)
                maximum = max(previous?.maximumPrice ?? price, price)
            } else {
                minimum = previous?.minimumPrice
                maximum = previous?.maximumPrice
            }

            observations[fingerprint] = HuntObservation(
                fingerprint: fingerprint,
                title: result.title,
                url: result.url,
                firstSeen: previous?.firstSeen ?? now,
                lastSeen: now,
                lastPrice: price ?? previous?.lastPrice,
                minimumPrice: minimum,
                maximumPrice: maximum,
                seenCount: result.seenCount ?? 1,
                providers: providers.sorted()
            )

            enriched.append(result)
        }

        save()
        return enriched
    }

    func knownCount() -> Int {
        loadIfNeeded()
        return observations.count
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true

        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([String: HuntObservation].self, from: data) else {
            return
        }

        observations = decoded
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(observations)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            // History is an enhancement, never a reason to fail a hunt.
        }
    }

    private var storageURL: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        let directory = base.appendingPathComponent("BuildScout", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory.appendingPathComponent("hunt-history-v2.json")
    }
}
