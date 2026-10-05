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

        return dedupe(results)
    }

    static func queries(for mission: MissionType, budget: Double) -> [String] {
        let budgetText = Int(budget)
        switch mission {
        case .drift:
            return [
                "RWD manual project car under $\(budgetText) Alberta",
                "non running BMW RWD project Alberta",
                "blown engine manual RWD project Alberta",
                "350Z G35 project Alberta",
                "Mustang manual project Alberta"
            ]
        case .overland:
            return [
                "4x4 project SUV under $\(budgetText) Alberta",
                "AWD wagon project Alberta",
                "fleet 4WD auction Alberta",
                "high mileage 4x4 mechanic special Alberta"
            ]
        case .camper:
            return [
                "cargo van project under $\(budgetText) Alberta",
                "fleet van auction Alberta",
                "wagon camper project Alberta",
                "minivan mechanic special Alberta"
            ]
        case .rally:
            return [
                "AWD manual project car Alberta",
                "Subaru project Alberta",
                "rally car shell Alberta",
                "winter beater manual auction Alberta"
            ]
        case .track:
            return [
                "manual coupe project Alberta",
                "track car project Alberta",
                "roller chassis Alberta",
                "sports car needs engine Alberta"
            ]
        case .winter:
            return [
                "AWD winter beater Alberta",
                "4x4 mechanic special Alberta",
                "old Subaru manual Alberta",
                "fleet AWD auction Alberta"
            ]
        case .custom:
            return [
                "project car mechanic special Alberta",
                "does not run car Alberta",
                "needs engine car Alberta",
                "estate vehicle auction Alberta",
                "lost interest project car Alberta"
            ]
        }
    }

    private static func auctionDomainQuery(for request: HuntRequest) -> String {
        let base = HuntEngine.queries(for: request.mission, budget: request.maxVehiclePrice).first ?? "project car Alberta"
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
