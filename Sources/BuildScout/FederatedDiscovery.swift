import Foundation

struct FederatedDiscoverySource: Identifiable, Hashable {
    let id: String
    let name: String
    let domain: String
    let kind: HuntResultKind
    let notes: String
}

enum FederatedDiscovery {
    static let sources: [FederatedDiscoverySource] = [
        .init(
            id: "carscout-ca",
            name: "CarScout",
            domain: "getcarscout.ca",
            kind: .vehicle,
            notes: "Canadian multi-marketplace discovery / deal intelligence."
        ),
        .init(
            id: "autotempest",
            name: "AutoTempest",
            domain: "autotempest.com",
            kind: .vehicle,
            notes: "Cross-market vehicle search and comparison pages."
        ),
        .init(
            id: "classic",
            name: "CLASSIC.COM",
            domain: "classic.com",
            kind: .vehicle,
            notes: "Large specialty/classic vehicle index across auctions, dealers and private sales."
        ),
        .init(
            id: "theparking",
            name: "The Parking",
            domain: "theparking.ca",
            kind: .vehicle,
            notes: "Large international used-car search index."
        ),
        .init(
            id: "bringatrailer",
            name: "Bring a Trailer",
            domain: "bringatrailer.com",
            kind: .auction,
            notes: "Auction/comparable source, more useful for valuation than ultra-cheap drift shells."
        ),
        .init(
            id: "carsandbids",
            name: "Cars & Bids",
            domain: "carsandbids.com",
            kind: .auction,
            notes: "Modern enthusiast auction/comparable source."
        )
    ]

    @MainActor
    static func search(
        request: HuntRequest,
        connections: ConnectionStore
    ) async -> [HuntResult] {
        guard connections.hasSerpAPI else { return [] }

        let key = connections.serpAPIKey
        let location = request.location
        let queries = Array(request.keywords.prefix(2))
        var output: [HuntResult] = []

        await withTaskGroup(of: [HuntResult].self) { group in
            for source in sources {
                for query in queries {
                    group.addTask {
                        let scoped = "site:\(source.domain) \(query)"
                        let raw = (try? await SerpAPIClient.googleSearch(
                            query: scoped,
                            location: location,
                            apiKey: key,
                            kind: source.kind
                        )) ?? []

                        return raw.map { item in
                            var copy = item
                            copy.provider = "Web index • \(source.name)"
                            copy.sourceDomain = source.domain
                            return copy
                        }
                    }
                }
            }

            for await batch in group {
                output.append(contentsOf: batch)
            }
        }

        return dedupe(output)
    }

    private static func dedupe(_ results: [HuntResult]) -> [HuntResult] {
        var seen = Set<String>()
        return results.filter {
            let key = $0.url.isEmpty
                ? "\($0.provider)|\($0.title.lowercased())"
                : $0.url
            return seen.insert(key).inserted
        }
    }
}
