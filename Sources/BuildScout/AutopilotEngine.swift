import Foundation

struct AutopilotReport: Identifiable {
    let id = UUID()
    let listing: VehicleListing
    let evaluation: BuildEvaluation
    let safety: SafetyIntel
    let canadianSpecs: [CanadianSpecResult]
    let fuelEconomy: [FuelEconomyVehicle]
    let sourcedPlan: SourcedBuildPlan
    let research: BuildResearchPack
    let unresolved: [String]
    let generatedAt = Date()

    var dataCoverage: Int {
        var points = 0
        if !canadianSpecs.isEmpty { points += 15 }
        if !fuelEconomy.isEmpty { points += 15 }
        if !safety.recalls.isEmpty || !safety.complaints.isEmpty || !safety.ratings.isEmpty { points += 20 }
        if sourcedPlan.livePriceCount > 0 { points += 30 }
        if !research.guides.isEmpty { points += 10 }
        if !research.services.isEmpty { points += 10 }
        return min(100, points)
    }

    var sourcedTotal: Double { sourcedPlan.sourcedTotal }

    var overUnderBudget: Double {
        sourcedTotal - evaluation.projectedTotal
    }
}

enum AutopilotEngine {
    @MainActor
    static func run(
        listing: VehicleListing,
        mission: MissionProfile,
        garage: GarageProfile,
        connections: ConnectionStore
    ) async -> AutopilotReport {
        let evaluation = ScoringEngine.evaluate(listing, mission: mission, garage: garage)

        async let safetyTask = SafetyIntelClient.fetch(
            year: listing.year,
            make: listing.make,
            model: listing.model
        )

        async let specsTask = try? VPICClient.canadianSpecs(
            year: listing.year,
            make: listing.make
        )

        async let fuelTask = try? FuelEconomyClient.lookup(
            year: listing.year,
            make: listing.make,
            model: listing.model
        )

        async let partsTask = PartSourcingEngine.source(
            listing: listing,
            mission: mission,
            garage: garage,
            connections: connections
        )

        async let researchTask = BuildResearchEngine.run(
            listing: listing,
            mission: mission,
            connections: connections
        )

        let safety = await safetyTask
        let allSpecs = await specsTask ?? []
        let fuel = await fuelTask ?? []
        let sourced = await partsTask
        let research = await researchTask

        let modelNeedle = listing.model
            .split(separator: " ")
            .first
            .map(String.init)?
            .lowercased() ?? listing.model.lowercased()

        let specs = allSpecs.filter {
            $0.model.lowercased().contains(modelNeedle)
        }

        var unresolved: [String] = []

        if listing.drivetrain == .unknown {
            unresolved.append("Drivetrain is still unverified.")
        }
        if listing.transmission == .unknown {
            unresolved.append("Transmission type is still unverified.")
        }
        if listing.price <= 0 {
            unresolved.append("Purchase price is missing or unverified.")
        }
        if !listing.runs {
            unresolved.append("Non-runner needs hands-on diagnosis before committing to engine replacement.")
        }
        let unsourced = sourced.lines.filter { $0.cheapest == nil }
        if !unsourced.isEmpty {
            unresolved.append("\(unsourced.count) build lines are still using fallback estimates instead of live prices.")
        }
        if safety.complaints.count > 25 {
            unresolved.append("High complaint volume: inspect the recurring component groups before purchase.")
        }
        if safety.recalls.count > 0 {
            unresolved.append("Verify recall completion against the actual VIN, not only year/make/model.")
        }
        if research.services.isEmpty && connections.hasSerpAPI {
            unresolved.append("No local specialist results were returned; widen or correct the configured region.")
        }

        return AutopilotReport(
            listing: listing,
            evaluation: evaluation,
            safety: safety,
            canadianSpecs: specs,
            fuelEconomy: fuel,
            sourcedPlan: sourced,
            research: research,
            unresolved: unresolved
        )
    }
}
