import Foundation

struct SourcedPartLine: Identifiable {
    let id = UUID()
    let task: PartSearchTask
    var options: [HuntResult]

    var cheapest: HuntResult? {
        options
            .filter { $0.price != nil }
            .min { ($0.price ?? .greatestFiniteMagnitude) < ($1.price ?? .greatestFiniteMagnitude) }
    }

    var planningCost: Double {
        cheapest?.price ?? task.fallbackEstimate
    }
}

struct SourcedBuildPlan: Identifiable {
    let id = UUID()
    let listing: VehicleListing
    let evaluation: BuildEvaluation
    var lines: [SourcedPartLine]
    var generatedAt = Date()

    var purchaseCost: Double { listing.price }
    var requiredPartsCost: Double {
        lines.filter { $0.task.required }.reduce(0) { $0 + $1.planningCost }
    }
    var optionalPartsCost: Double {
        lines.filter { !$0.task.required }.reduce(0) { $0 + $1.planningCost }
    }
    var sourcedPartsCost: Double { requiredPartsCost }
    var minimumTotal: Double { purchaseCost + requiredPartsCost }
    var fullBuildTotal: Double { minimumTotal + optionalPartsCost }
    var sourcedTotal: Double { minimumTotal }
    var livePriceCount: Int { lines.filter { $0.cheapest != nil }.count }
    var requiredLivePriceCount: Int {
        lines.filter { $0.task.required && $0.cheapest != nil }.count
    }
    var requiredLineCount: Int { lines.filter { $0.task.required }.count }
}

enum PartSourcingEngine {
    @MainActor
    static func source(
        listing: VehicleListing,
        mission: MissionProfile,
        garage: GarageProfile,
        connections: ConnectionStore
    ) async -> SourcedBuildPlan {
        let evaluation = ScoringEngine.evaluate(listing, mission: mission, garage: garage)
        let tasks = PartSearchPlanner.tasks(for: listing, mission: mission, evaluation: evaluation)

        var lines: [SourcedPartLine] = []

        for task in tasks {
            var options: [HuntResult] = []

            await withTaskGroup(of: [HuntResult].self) { group in
                if connections.hasSerpAPI {
                    let serpKey = connections.serpAPIKey
                    let region = connections.preferredRegion

                    group.addTask {
                        (try? await SerpAPIClient.shoppingSearch(
                            query: task.query,
                            location: region,
                            apiKey: serpKey
                        )) ?? []
                    }

                    group.addTask {
                        (try? await SerpAPIClient.ebaySearch(
                            query: task.query,
                            apiKey: serpKey
                        )) ?? []
                    }

                    group.addTask {
                        await ForumFederation.searchParts(
                            listing: listing,
                            task: task,
                            connections: connections
                        )
                    }
                }

                if connections.hasEBay {
                    let clientID = connections.eBayClientID
                    let secret = connections.eBayClientSecret

                    group.addTask {
                        (try? await EBayClient.search(
                            query: task.query,
                            clientID: clientID,
                            clientSecret: secret
                        )) ?? []
                    }
                }

                for await batch in group {
                    options.append(contentsOf: batch)
                }
            }

            lines.append(
                SourcedPartLine(
                    task: task,
                    options: rank(options, for: task).prefix(8).map { $0 }
                )
            )
        }

        return SourcedBuildPlan(
            listing: listing,
            evaluation: evaluation,
            lines: lines
        )
    }

    private static func rank(_ results: [HuntResult], for task: PartSearchTask) -> [HuntResult] {
        let queryTokens = Set(
            task.query
                .lowercased()
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
                .filter { $0.count > 2 }
        )

        return results
            .reduce(into: [String: HuntResult]()) { partial, result in
                let key = result.url.isEmpty ? result.title.lowercased() : result.url
                if partial[key] == nil { partial[key] = result }
            }
            .map(\.value)
            .sorted { lhs, rhs in
                let leftScore = relevance(lhs, tokens: queryTokens)
                let rightScore = relevance(rhs, tokens: queryTokens)
                if leftScore != rightScore { return leftScore > rightScore }

                switch (lhs.price, rhs.price) {
                case let (l?, r?): return l < r
                case (_?, nil): return true
                case (nil, _?): return false
                default: return lhs.title < rhs.title
                }
            }
    }

    private static func relevance(_ result: HuntResult, tokens: Set<String>) -> Int {
        let haystack = (result.title + " " + result.snippet).lowercased()
        var score = tokens.reduce(0) { $0 + (haystack.contains($1) ? 1 : 0) }
        if result.price != nil { score += 2 }
        if result.provider.contains("eBay Browse") { score += 1 }
        return score
    }
}
