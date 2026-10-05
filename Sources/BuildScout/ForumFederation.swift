import Foundation

struct ForumDiscoverySource: Identifiable, Hashable {
    let id: String
    let name: String
    let domain: String
    let specialties: [String]
}

enum ForumFederation {
    static let sources: [ForumDiscoverySource] = [
        .init(id: "bimmerforums", name: "Bimmerforums", domain: "bimmerforums.com", specialties: ["BMW", "drift", "parts"]),
        .init(id: "e46fanatics", name: "E46Fanatics", domain: "e46fanatics.com", specialties: ["BMW E46", "parts"]),
        .init(id: "bimmerpost", name: "Bimmerpost", domain: "bimmerpost.com", specialties: ["BMW", "parts"]),
        .init(id: "zilvia", name: "Zilvia", domain: "zilvia.net", specialties: ["Nissan", "drift", "parts"]),
        .init(id: "my350z", name: "MY350Z", domain: "my350z.com", specialties: ["350Z", "drift", "parts"]),
        .init(id: "g35driver", name: "G35Driver", domain: "g35driver.com", specialties: ["G35", "VQ", "parts"]),
        .init(id: "nasioc", name: "NASIOC", domain: "forums.nasioc.com", specialties: ["Subaru", "rally", "parts"]),
        .init(id: "mustang6g", name: "Mustang6G", domain: "mustang6g.com", specialties: ["Mustang", "parts"]),
        .init(id: "corral", name: "Corral Mustang", domain: "corral.net", specialties: ["Mustang", "Fox/SN95", "parts"]),
        .init(id: "turbobricks", name: "Turbobricks", domain: "turbobricks.com", specialties: ["Volvo", "RWD", "parts"]),
        .init(id: "clublexus", name: "ClubLexus", domain: "clublexus.com", specialties: ["Lexus", "IS300", "parts"]),
        .init(id: "rx8club", name: "RX8Club", domain: "rx8club.com", specialties: ["RX-8", "rotary", "parts"]),
        .init(id: "grassroots", name: "Grassroots Motorsports", domain: "grassrootsmotorsports.com", specialties: ["track", "project cars", "classifieds"]),
        .init(id: "expeditionportal", name: "Expedition Portal", domain: "expeditionportal.com", specialties: ["overland", "4x4", "classifieds"]),
        .init(id: "ih8mud", name: "IH8MUD", domain: "forum.ih8mud.com", specialties: ["Toyota 4x4", "overland", "parts"])
    ]

    @MainActor
    static func searchVehicles(
        request: HuntRequest,
        connections: ConnectionStore
    ) async -> [HuntResult] {
        guard connections.hasSerpAPI else { return [] }

        let selected = relevantSources(for: request.mission)
        let key = connections.serpAPIKey
        let region = request.location
        let baseQuery = request.keywords.first ?? "\(request.mission.rawValue) project car"

        var output: [HuntResult] = []

        await withTaskGroup(of: [HuntResult].self) { group in
            for source in selected.prefix(8) {
                group.addTask {
                    let query = "site:\(source.domain) (classifieds OR for sale OR cars for sale) \(baseQuery)"
                    let rows = (try? await SerpAPIClient.googleSearch(
                        query: query,
                        location: region,
                        apiKey: key,
                        kind: .vehicle
                    )) ?? []

                    return rows.map {
                        var item = $0
                        item.provider = "Forum • \(source.name)"
                        item.sourceDomain = source.domain
                        return item
                    }
                }
            }

            for await batch in group {
                output.append(contentsOf: batch)
            }
        }

        return dedupe(output)
    }

    @MainActor
    static func searchParts(
        listing: VehicleListing,
        task: PartSearchTask,
        connections: ConnectionStore
    ) async -> [HuntResult] {
        guard connections.hasSerpAPI else { return [] }

        let key = connections.serpAPIKey
        let region = connections.preferredRegion
        let relevant = sources.filter { source in
            let haystack = (source.specialties.joined(separator: " ") + " " + source.name).lowercased()
            let vehicle = "\(listing.make) \(listing.model)".lowercased()
            return vehicle
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .contains(where: { token in
                    token.count > 2 && haystack.contains(token)
                })
        }

        let selected = relevant.isEmpty ? Array(sources.prefix(6)) : Array(relevant.prefix(6))
        var output: [HuntResult] = []

        await withTaskGroup(of: [HuntResult].self) { group in
            for source in selected {
                group.addTask {
                    let query = "site:\(source.domain) (classifieds OR for sale OR parts for sale) \(task.query)"
                    let rows = (try? await SerpAPIClient.googleSearch(
                        query: query,
                        location: region,
                        apiKey: key,
                        kind: .part
                    )) ?? []

                    return rows.map {
                        var item = $0
                        item.provider = "Forum • \(source.name)"
                        item.sourceDomain = source.domain
                        return item
                    }
                }
            }

            for await batch in group {
                output.append(contentsOf: batch)
            }
        }

        return dedupe(output)
    }

    private static func relevantSources(for mission: MissionType) -> [ForumDiscoverySource] {
        switch mission {
        case .drift:
            return sources.filter {
                $0.specialties.contains("drift") ||
                $0.specialties.contains("BMW") ||
                $0.specialties.contains("RWD")
            } + sources.filter {
                $0.specialties.contains("Mustang") ||
                $0.specialties.contains("350Z")
            }
        case .overland, .camper:
            return sources.filter {
                $0.specialties.contains("overland") ||
                $0.specialties.contains("4x4")
            }
        case .rally:
            return sources.filter {
                $0.specialties.contains("rally") ||
                $0.specialties.contains("Subaru")
            }
        case .track:
            return sources.filter {
                $0.specialties.contains("track") ||
                $0.specialties.contains("project cars")
            }
        case .winter, .custom:
            return sources
        }
    }

    private static func dedupe(_ results: [HuntResult]) -> [HuntResult] {
        var seen = Set<String>()
        return results.filter {
            let key = $0.url.isEmpty ? "\($0.provider)|\($0.title)" : $0.url
            return seen.insert(key).inserted
        }
    }
}
