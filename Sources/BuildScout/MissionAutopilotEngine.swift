import Foundation

struct MissionAutopilotReport: Identifiable {
    let id = UUID()
    let huntResults: [HuntResult]
    let discoveredCandidates: [VehicleListing]
    let rankedCandidates: [BuildEvaluation]
    let finalists: [AutopilotReport]
    let champion: AutopilotReport?
    let generatedAt = Date()

    var candidateCount: Int { discoveredCandidates.count }
    var rawLeadCount: Int { huntResults.count }
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
                for: mission,
                location: connections.preferredRegion
            ),
            location: connections.preferredRegion,
            maxVehiclePrice: mission.vehicleBudget,
            preferredVehicle: nil,
            radiusKM: mission.radiusKM,
            allowNonRunner: mission.allowNonRunner,
            allowTow: mission.allowTow,
            allowTransmissionSwap: mission.allowTransmissionSwap,
            preferredDrivetrain: mission.preferredDrivetrain
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
            missionAllows(listing, mission: mission)
        }

        let ranked = candidates
            .map { ScoringEngine.evaluate($0, mission: mission, garage: garage) }
            .sorted {
                if $0.score == $1.score {
                    return $0.projectedTotal < $1.projectedTotal
                }
                return $0.score > $1.score
            }

        var finalistReports: [AutopilotReport] = []
        for evaluation in ranked.prefix(3) {
            let report = await AutopilotEngine.run(
                listing: evaluation.listing,
                mission: mission,
                garage: garage,
                connections: connections
            )
            finalistReports.append(report)
        }

        finalistReports.sort {
            betterBuildPath($0, than: $1, mission: mission)
        }

        return MissionAutopilotReport(
            huntResults: hunted,
            discoveredCandidates: candidates,
            rankedCandidates: ranked,
            finalists: finalistReports,
            champion: finalistReports.first
        )
    }

    private static func missionAllows(
        _ listing: VehicleListing,
        mission: MissionProfile
    ) -> Bool {
        if listing.price > 0, listing.price > mission.vehicleBudget * 1.15 {
            return false
        }

        if !mission.allowNonRunner, !listing.runs {
            return false
        }

        if !mission.allowTow, listing.towRequired {
            return false
        }

        if mission.preferredDrivetrain != .unknown,
           listing.drivetrain != .unknown,
           listing.drivetrain != mission.preferredDrivetrain {
            return false
        }

        if mission.type == .drift,
           !mission.allowTransmissionSwap,
           listing.transmission != .unknown,
           listing.transmission != .manual {
            return false
        }

        return true
    }

    private static func betterBuildPath(
        _ lhs: AutopilotReport,
        than rhs: AutopilotReport,
        mission: MissionProfile
    ) -> Bool {
        let lhsFits = lhs.sourcedPlan.minimumTotal <= mission.totalBudget
        let rhsFits = rhs.sourcedPlan.minimumTotal <= mission.totalBudget

        if lhsFits != rhsFits {
            return lhsFits
        }

        let lhsCoverage = liveCoverage(lhs.sourcedPlan)
        let rhsCoverage = liveCoverage(rhs.sourcedPlan)
        if lhsCoverage != rhsCoverage {
            return lhsCoverage > rhsCoverage
        }

        if lhs.evaluation.score != rhs.evaluation.score {
            return lhs.evaluation.score > rhs.evaluation.score
        }

        return lhs.sourcedPlan.minimumTotal < rhs.sourcedPlan.minimumTotal
    }

    private static func liveCoverage(_ plan: SourcedBuildPlan) -> Int {
        guard plan.requiredLineCount > 0 else { return 100 }
        return Int(
            (Double(plan.requiredLivePriceCount) / Double(plan.requiredLineCount)) * 100
        )
    }
}
