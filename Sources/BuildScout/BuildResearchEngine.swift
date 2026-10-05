import Foundation

struct BuildResearchPack: Identifiable {
    let id = UUID()
    let listing: VehicleListing
    var guides: [HuntResult]
    var forumThreads: [HuntResult]
    var services: [HuntResult]
    var generatedAt = Date()
}

enum BuildResearchEngine {
    @MainActor
    static func run(
        listing: VehicleListing,
        mission: MissionProfile,
        connections: ConnectionStore
    ) async -> BuildResearchPack {
        guard connections.hasSerpAPI else {
            return BuildResearchPack(listing: listing, guides: [], forumThreads: [], services: [])
        }

        let key = connections.serpAPIKey
        let region = connections.preferredRegion
        let vehicle = "\(listing.year) \(listing.make) \(listing.model)"

        async let guides = SerpAPIClient.youtubeSearch(
            query: guideQuery(vehicle: vehicle, mission: mission.type),
            apiKey: key
        )

        async let forums = SerpAPIClient.googleSearch(
            query: forumQuery(vehicle: vehicle, mission: mission.type),
            location: region,
            apiKey: key,
            kind: .guide
        )

        var services: [HuntResult] = []
        await withTaskGroup(of: [HuntResult].self) { group in
            for query in serviceQueries(mission: mission.type) {
                group.addTask {
                    (try? await SerpAPIClient.mapsSearch(
                        query: query,
                        location: region,
                        apiKey: key
                    )) ?? []
                }
            }

            for await batch in group {
                services.append(contentsOf: batch)
            }
        }

        return BuildResearchPack(
            listing: listing,
            guides: (try? await guides) ?? [],
            forumThreads: (try? await forums) ?? [],
            services: dedupe(services)
        )
    }

    private static func guideQuery(vehicle: String, mission: MissionType) -> String {
        switch mission {
        case .drift:
            return "\(vehicle) drift build suspension diff angle kit beginner"
        case .overland:
            return "\(vehicle) overland build suspension tires recovery"
        case .camper:
            return "\(vehicle) camper conversion sleeping platform electrical"
        case .rally:
            return "\(vehicle) rally build suspension skid plate"
        case .track:
            return "\(vehicle) track build brakes cooling suspension"
        case .winter:
            return "\(vehicle) winter build tires maintenance"
        case .custom:
            return "\(vehicle) build project repair"
        }
    }

    private static func forumQuery(vehicle: String, mission: MissionType) -> String {
        let missionWord = mission.rawValue.lowercased()
        return "\(vehicle) \(missionWord) build forum OR build thread OR DIY OR swap guide"
    }

    private static func serviceQueries(mission: MissionType) -> [String] {
        switch mission {
        case .drift:
            return [
                "performance alignment shop",
                "automotive fabrication welding shop",
                "engine machine shop",
                "auto salvage yard",
                "towing service"
            ]
        case .overland:
            return [
                "4x4 fabrication shop",
                "off road alignment shop",
                "automotive welding shop",
                "roof rack fabrication",
                "towing service"
            ]
        case .camper:
            return [
                "van conversion shop",
                "automotive electrical shop",
                "metal fabrication shop",
                "upholstery shop"
            ]
        case .rally:
            return [
                "motorsport fabrication shop",
                "performance alignment shop",
                "roll cage fabrication",
                "engine machine shop"
            ]
        case .track:
            return [
                "motorsport alignment shop",
                "performance brake shop",
                "roll cage fabrication",
                "engine machine shop"
            ]
        case .winter:
            return [
                "alignment shop",
                "tire shop",
                "automotive repair shop"
            ]
        case .custom:
            return [
                "automotive fabrication shop",
                "machine shop",
                "auto salvage yard",
                "towing service"
            ]
        }
    }

    private static func dedupe(_ results: [HuntResult]) -> [HuntResult] {
        var seen = Set<String>()
        return results.filter {
            let key = $0.title.lowercased() + "|" + ($0.location ?? "")
            guard seen.insert(key).inserted else { return false }
            return true
        }
    }
}
