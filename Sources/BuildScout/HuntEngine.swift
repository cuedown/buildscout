import Foundation

enum HuntResultKind: String, Codable {
    case vehicle
    case part
    case auction
    case guide
    case service
    case unknown
}

struct HuntResult: Identifiable, Hashable {
    let id = UUID()
    var provider: String
    var kind: HuntResultKind
    var title: String
    var url: String
    var snippet: String
    var price: Double?
    var currency: String?
    var location: String?
    var thumbnailURL: String?
    var sourceDomain: String?
    var vin: String? = nil
    var odometerKM: Double? = nil
    var drivetrain: Drivetrain? = nil
    var transmission: TransmissionType? = nil
    var previousPrice: Double? = nil
    var seenCount: Int? = nil
}

struct HuntRequest {
    var mission: MissionType
    var keywords: [String]
    var location: String
    var maxVehiclePrice: Double
    var preferredVehicle: VehicleListing?
    var radiusKM: Double = 300
    var allowNonRunner: Bool = true
    var allowTow: Bool = true
    var allowTransmissionSwap: Bool = true
    var preferredDrivetrain: Drivetrain = .unknown
}

enum HuntEngine {
    @MainActor
    static func run(
        request: HuntRequest,
        connections: ConnectionStore
    ) async -> [HuntResult] {
        var results: [HuntResult] = []

        let nativeAutoTrader = await RegionalDiscovery.canadaWide(request: request)
        results.append(contentsOf: nativeAutoTrader)

        // Separate American discovery lanes remain unpriced until VIN/title/FX
        // and legal admissibility have been independently confirmed.
        let usLeads = await RegionalDiscovery.usDiscovery(
            request: request,
            connections: connections
        )
        results.append(contentsOf: usLeads)

        if connections.hasMarketCheck {
            if let market = try? await MarketCheckClient.searchInventory(
                apiKey: connections.marketCheckAPIKey,
                mission: request.mission,
                maximumPrice: request.maxVehiclePrice,
                region: request.location
            ) {
                results.append(contentsOf: market)
            }
        }

        if connections.hasApify {
            let actorResults = await ApifyAutomotiveSources.search(
                request: request,
                connections: connections
            )
            results.append(contentsOf: actorResults)
        }

        if connections.hasTavily || connections.hasExa || connections.hasBrave {
            let freeWeb = await FreeWebDiscovery.search(
                request: request,
                connections: connections,
                kind: .vehicle
            )
            results.append(contentsOf: freeWeb)

            var indexedMarketRequest = request
            indexedMarketRequest.keywords = [Self.indexedMarketplaceQuery(for: request)]
            let indexedMarket = await FreeWebDiscovery.search(
                request: indexedMarketRequest,
                connections: connections,
                kind: .vehicle
            )
            results.append(contentsOf: indexedMarket)

            var auctionRequest = request
            auctionRequest.keywords = [Self.auctionDomainQuery(for: request)]
            let freeAuctions = await FreeWebDiscovery.search(
                request: auctionRequest,
                connections: connections,
                kind: .auction
            )
            results.append(contentsOf: freeAuctions)
        }

        if connections.hasSerpAPI {
            let serpKey = connections.serpAPIKey
            let hasAlternateWeb = connections.hasTavily || connections.hasExa || connections.hasBrave
            let serpQueryLimit = hasAlternateWeb ? 2 : 4

            await withTaskGroup(of: [HuntResult].self) { group in
                let queries = Array(request.keywords.prefix(serpQueryLimit))

                for query in queries {
                    group.addTask {
                        (try? await SerpAPIClient.googleSearch(
                            query: query,
                            location: request.location,
                            apiKey: serpKey,
                            kind: .vehicle
                        )) ?? []
                    }
                }

                group.addTask {
                    let auctionQuery = Self.auctionDomainQuery(for: request)
                    return (try? await SerpAPIClient.googleSearch(
                        query: auctionQuery,
                        location: request.location,
                        apiKey: serpKey,
                        kind: .auction
                    )) ?? []
                }

                if let vehicle = request.preferredVehicle {
                    let partsQuery = "\(vehicle.year) \(vehicle.make) \(vehicle.model) drift suspension differential coilovers angle kit"
                    group.addTask {
                        (try? await SerpAPIClient.shoppingSearch(
                            query: partsQuery,
                            location: request.location,
                            apiKey: serpKey
                        )) ?? []
                    }

                    group.addTask {
                        (try? await SerpAPIClient.ebaySearch(
                            query: partsQuery,
                            apiKey: serpKey
                        )) ?? []
                    }
                }

                for await batch in group {
                    results.append(contentsOf: batch)
                }
            }

            if !(connections.hasTavily || connections.hasExa || connections.hasBrave) {
                let federated = await FederatedDiscovery.search(
                    request: request,
                    connections: connections
                )
                results.append(contentsOf: federated)

                let forumVehicles = await ForumFederation.searchVehicles(
                    request: request,
                    connections: connections
                )
                results.append(contentsOf: forumVehicles)
            }
        }

        if connections.hasEBay, let vehicle = request.preferredVehicle {
            let query = "\(vehicle.year) \(vehicle.make) \(vehicle.model) parts"
            if let native = try? await EBayClient.search(
                query: query,
                clientID: connections.eBayClientID,
                clientSecret: connections.eBayClientSecret
            ) {
                results.append(contentsOf: native)
            }
        }

        let deduped = CrossSourceDeduper.dedupe(results)
        return await HuntHistoryStore.shared.enrichAndRecord(deduped)
    }

    static func queries(
        for mission: MissionType,
        budget: Double,
        location: String = "Alberta"
    ) -> [String] {
        HuntQueryPlanner.legacyQueries(
            for: mission,
            budget: budget,
            location: location
        )
    }

    static func queries(
        for profile: MissionProfile,
        location: String
    ) -> [String] {
        HuntQueryPlanner.queries(
            for: profile,
            location: location
        )
    }

    private static func indexedMarketplaceQuery(for request: HuntRequest) -> String {
        let base = request.keywords.first ?? "project car \(request.location)"
        return "\(base) (site:kijiji.ca OR site:kijijiautos.ca OR site:facebook.com/marketplace OR site:autotrader.ca OR site:autotempest.com OR site:theparking.ca OR site:classic.com)"
    }

    private static func auctionDomainQuery(for request: HuntRequest) -> String {
        let base = request.keywords.first
            ?? HuntEngine.queries(
                for: request.mission,
                budget: request.maxVehiclePrice,
                location: request.location
            ).first
            ?? "project car \(request.location)"
        return "\(base) (site:copart.ca OR site:iaai.com OR site:teamauctions.com OR site:grahamauctions.com OR site:maauctions.com OR site:govdeals.ca)"
    }

    private static func dedupe(_ items: [HuntResult]) -> [HuntResult] {
        var seen = Set<String>()
        return items.filter { item in
            let key = item.url.isEmpty ? item.title.lowercased() : item.url
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}
