import Foundation

struct MissionAutopilotReport: Identifiable {
    let id = UUID()
    let huntResults: [HuntResult]
    let discoveredCandidates: [VehicleListing]
    let rankedCandidates: [BuildEvaluation]
    let finalists: [AutopilotReport]
    let champion: AutopilotReport?
    let rejectedCandidateCount: Int
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

        let normalized = HuntNormalization.vehicles(
            from: hunted.filter { !$0.provider.contains("Expanded index") &&
                !$0.provider.contains("US aged vehicles") &&
                !$0.provider.contains("US newer admissibility-check") &&
                !$0.provider.contains("Canadian return /") },
            defaultLocation: connections.preferredRegion
        )

        let candidates = normalized.filter {
            MissionCandidateValidator.allows($0, mission: mission)
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
            champion: finalistReports.first,
            rejectedCandidateCount: max(0, normalized.count - candidates.count)
        )
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
