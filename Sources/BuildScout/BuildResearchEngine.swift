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
        let region = connections.preferredRegion
        let vehicle = "\(listing.year) \(listing.make) \(listing.model)"
        let guide = guideQuery(vehicle: vehicle, mission: mission.type)
        let forum = forumQuery(vehicle: vehicle, mission: mission.type)

        var guides: [HuntResult] = []
        var forums: [HuntResult] = []
        var services: [HuntResult] = []

        if connections.hasYouTube {
            let direct = try? await YouTubeDataClient.search(
                query: guide,
                apiKey: connections.youtubeAPIKey,
                maxResults: 20
            )
            guides.append(contentsOf: direct ?? [])
        }

        if connections.hasSerpAPI {
            let serpKey = connections.serpAPIKey

            if !connections.hasYouTube {
                let serpGuides = try? await SerpAPIClient.youtubeSearch(
                    query: guide,
                    apiKey: serpKey
                )
                guides.append(contentsOf: serpGuides ?? [])
            }

            let serpForums = try? await SerpAPIClient.googleSearch(
                query: forum,
                location: region,
                apiKey: serpKey,
                kind: .guide
            )
            forums.append(contentsOf: serpForums ?? [])

            let hasAlternateWeb = connections.hasTavily || connections.hasExa || connections.hasBrave
            let serviceLimit = hasAlternateWeb ? 1 : 3

            await withTaskGroup(of: [HuntResult].self) { group in
                for query in serviceQueries(mission: mission.type).prefix(serviceLimit) {
                    group.addTask {
                        (try? await SerpAPIClient.mapsSearch(
                            query: query,
                            location: region,
                            apiKey: serpKey
                        )) ?? []
                    }
                }

                for await batch in group {
                    services.append(contentsOf: batch)
                }
            }
        }

        let github = try? await GitHubSearchClient.repositories(
            query: "\(vehicle) \(mission.type.rawValue.lowercased()) build OR swap",
            token: connections.hasGitHub ? connections.githubToken : nil
        )
        forums.append(contentsOf: github ?? [])

        if connections.hasTavily || connections.hasExa || connections.hasBrave {
            let forumRequest = HuntRequest(
                mission: mission.type,
                keywords: [forum],
                location: region,
                maxVehiclePrice: mission.vehicleBudget,
                preferredVehicle: listing,
                radiusKM: mission.radiusKM,
                allowNonRunner: mission.allowNonRunner,
                allowTow: mission.allowTow,
                allowTransmissionSwap: mission.allowTransmissionSwap,
                preferredDrivetrain: mission.preferredDrivetrain
            )
            let freeForums = await FreeWebDiscovery.search(
                request: forumRequest,
                connections: connections,
                kind: .guide
            )
            forums.append(contentsOf: freeForums)

            if !connections.hasYouTube && !connections.hasSerpAPI {
                var guideRequest = forumRequest
                guideRequest.keywords = ["site:youtube.com \(guide)"]
                let freeGuides = await FreeWebDiscovery.search(
                    request: guideRequest,
                    connections: connections,
                    kind: .guide
                )
                guides.append(contentsOf: freeGuides)
            }

            var serviceRequest = forumRequest
            let serviceText = serviceQueries(mission: mission.type)
                .prefix(3)
                .map { "\($0) \(region)" }
                .joined(separator: " OR ")
            serviceRequest.keywords = [serviceText]
            let freeServices = await FreeWebDiscovery.search(
                request: serviceRequest,
                connections: connections,
                kind: .service
            )
            services.append(contentsOf: freeServices)
        }

        return BuildResearchPack(
            listing: listing,
            guides: dedupe(guides),
            forumThreads: dedupe(forums),
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
