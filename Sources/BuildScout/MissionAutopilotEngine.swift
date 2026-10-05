import Foundation

struct MissionAutopilotReport: Identifiable {
    let id = UUID()
    let huntResults: [HuntResult]
    let discoveredCandidates: [VehicleListing]
    let rankedCandidates: [BuildEvaluation]
    let champion: AutopilotReport?
    let generatedAt = Date()

    var candidateCount: Int { discoveredCandidates.count }
}

enum MissionAutopilotEngine {
    @MainActor
    static func run(
        mission: MissionProfile,
        garage: GarageProfile,
        connections: ConnectionStore
    ) async -> MissionAutopilotReport {
        let request = HuntRequest(
            mission: mission.type,
            keywords: HuntEngine.queries(
                for: mission.type,
                budget: mission.vehicleBudget
            ),
            location: connections.preferredRegion,
            maxVehiclePrice: mission.vehicleBudget,
            preferredVehicle: nil
        )

        let hunted = await HuntEngine.run(
            request: request,
            connections: connections
        )

        let candidates = HuntNormalization.vehicles(
            from: hunted,
            defaultLocation: connections.preferredRegion
        )
        .filter { listing in
            listing.price <= 0 || listing.price <= mission.vehicleBudget * 1.15
        }

        let ranked = candidates
            .map { ScoringEngine.evaluate($0, mission: mission, garage: garage) }
            .sorted {
                if $0.score == $1.score {
                    return $0.projectedTotal < $1.projectedTotal
                }
                return $0.score > $1.score
            }

        let champion: AutopilotReport?
        if let best = ranked.first {
            champion = await AutopilotEngine.run(
                listing: best.listing,
                mission: mission,
                garage: garage,
                connections: connections
            )
        } else {
            champion = nil
        }

        return MissionAutopilotReport(
            huntResults: hunted,
            discoveredCandidates: candidates,
            rankedCandidates: ranked,
            champion: champion
        )
    }
}
