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
}

enum HuntEngine {
    @MainActor
    static func run(
        request: HuntRequest,
        connections: ConnectionStore
    ) async -> [HuntResult] {
        var results: [HuntResult] = []

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

        if connections.hasSerpAPI {
            await withTaskGroup(of: [HuntResult].self) { group in
                let queries = Array(request.keywords.prefix(5))

                for query in queries {
                    group.addTask {
                        (try? await SerpAPIClient.googleSearch(
                            query: query,
                            location: request.location,
                            apiKey: connections.serpAPIKey,
                            kind: .vehicle
                        )) ?? []
                    }
                }

                group.addTask {
                    let auctionQuery = Self.auctionDomainQuery(for: request)
                    return (try? await SerpAPIClient.googleSearch(
                        query: auctionQuery,
                        location: request.location,
                        apiKey: connections.serpAPIKey,
                        kind: .auction
                    )) ?? []
                }

                if let vehicle = request.preferredVehicle {
                    let partsQuery = "\(vehicle.year) \(vehicle.make) \(vehicle.model) drift suspension differential coilovers angle kit"
                    group.addTask {
                        (try? await SerpAPIClient.shoppingSearch(
                            query: partsQuery,
                            location: request.location,
                            apiKey: connections.serpAPIKey
                        )) ?? []
                    }

                    group.addTask {
                        (try? await SerpAPIClient.ebaySearch(
                            query: partsQuery,
                            apiKey: connections.serpAPIKey
                        )) ?? []
                    }
                }

                for await batch in group {
                    results.append(contentsOf: batch)
                }
            }

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
        let budgetText = Int(budget)
        let region = location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Canada" : location

        switch mission {
        case .drift:
            return [
                "RWD manual project car under $\(budgetText) \(region)",
                "non running BMW RWD project \(region)",
                "engine failure manual RWD project \(region)",
                "350Z G35 project \(region)",
                "Mustang manual project \(region)"
            ]
        case .overland:
            return [
                "4x4 project SUV under $\(budgetText) \(region)",
                "AWD wagon project \(region)",
                "fleet 4WD auction \(region)",
                "high mileage 4x4 mechanic special \(region)"
            ]
        case .camper:
            return [
                "cargo van project under $\(budgetText) \(region)",
                "fleet van auction \(region)",
                "wagon camper project \(region)",
                "minivan mechanic special \(region)"
            ]
        case .rally:
            return [
                "AWD manual project car \(region)",
                "Subaru project \(region)",
                "rally car shell \(region)",
                "winter beater manual auction \(region)"
            ]
        case .track:
            return [
                "manual coupe project \(region)",
                "track car project \(region)",
                "roller chassis \(region)",
                "sports car needs engine \(region)"
            ]
        case .winter:
            return [
                "AWD winter beater \(region)",
                "4x4 mechanic special \(region)",
                "old Subaru manual \(region)",
                "fleet AWD auction \(region)"
            ]
        case .custom:
            return [
                "project car mechanic special \(region)",
                "does not run car \(region)",
                "needs engine car \(region)",
                "estate vehicle auction \(region)",
                "lost interest project car \(region)"
            ]
        }
    }

    private static func auctionDomainQuery(for request: HuntRequest) -> String {
        let base = HuntEngine.queries(
            for: request.mission,
            budget: request.maxVehiclePrice,
            location: request.location
        ).first ?? "project car \(request.location)"
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
