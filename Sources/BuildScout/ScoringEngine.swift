import Foundation

enum ScoringEngine {
    static func evaluate(_ listing: VehicleListing, mission: MissionProfile) -> BuildEvaluation {
        var score = 50
        var reasons: [String] = []
        var warnings: [String] = []
        var parts: [BuildPart] = []
        var projected = listing.price

        if listing.price <= mission.vehicleBudget {
            score += 20
            reasons.append("Purchase price fits the vehicle budget.")
        } else {
            let over = listing.price - mission.vehicleBudget
            score -= min(25, Int(over / 200))
            warnings.append("Purchase price is over vehicle budget by $\(Int(over)).")
        }

        if !listing.runs {
            if mission.allowNonRunner {
                score -= 6
                reasons.append("Non-runner accepted by this mission.")
                parts.append(.init(name: "Diagnostic / resurrection reserve", estimate: 650, required: true, category: "Reliability"))
                projected += 650
            } else {
                score -= 40
                warnings.append("Mission excludes non-running cars.")
            }
        }

        if listing.towRequired {
            if mission.allowTow {
                parts.append(.init(name: "Tow allowance", estimate: 250, required: true, category: "Logistics"))
                projected += 250
            } else {
                score -= 20
                warnings.append("Requires towing.")
            }
        }

        switch mission.type {
        case .drift:
            if listing.drivetrain == .rwd {
                score += 22
                reasons.append("RWD is ideal for a simple drift build.")
            } else {
                score -= 30
                warnings.append("Not RWD; conversion is rarely budget-friendly.")
            }
            if listing.transmission == .manual {
                score += 15
                reasons.append("Manual transmission already present.")
            } else if mission.allowTransmissionSwap {
                score -= 5
                parts.append(.init(name: "Manual swap reserve", estimate: 1500, required: false, category: "Drivetrain"))
                projected += 1500
            } else {
                score -= 25
            }
            if listing.strengths.contains(where: { $0.localizedCaseInsensitiveContains("welded diff") || $0.localizedCaseInsensitiveContains("LSD") }) {
                score += 10
                reasons.append("Differential is already drift-friendly.")
            } else {
                parts.append(.init(name: "Differential solution", estimate: 450, required: true, category: "Drivetrain"))
                projected += 450
            }
            parts += [
                .init(name: "Fluids + baseline service", estimate: 300, required: true, category: "Reliability"),
                .init(name: "Alignment / inspection", estimate: 220, required: true, category: "Chassis"),
                .init(name: "Rear tire reserve", estimate: 400, required: true, category: "Consumables")
            ]
            projected += 920

        case .overland, .winter:
            if listing.drivetrain == .awd || listing.drivetrain == .fourWD {
                score += 22
                reasons.append("AWD/4WD fits the mission.")
            } else {
                score -= 12
            }
            parts += [
                .init(name: "All-terrain / winter tire reserve", estimate: 900, required: true, category: "Traction"),
                .init(name: "Recovery kit", estimate: 250, required: true, category: "Recovery")
            ]
            projected += 1150

        case .camper:
            parts += [
                .init(name: "Sleeping platform", estimate: 350, required: true, category: "Interior"),
                .init(name: "12V power + lighting", estimate: 300, required: true, category: "Electrical")
            ]
            projected += 650
            if listing.model.localizedCaseInsensitiveContains("wagon") || listing.model.localizedCaseInsensitiveContains("van") {
                score += 15
            }

        case .rally:
            if listing.drivetrain == .awd || listing.drivetrain == .fourWD || listing.drivetrain == .rwd { score += 10 }
            parts += [
                .init(name: "Skid plate / protection reserve", estimate: 500, required: true, category: "Protection"),
                .init(name: "Suspension refresh", estimate: 1100, required: true, category: "Chassis")
            ]
            projected += 1600

        case .track:
            parts += [
                .init(name: "Brake fluid + pads", estimate: 550, required: true, category: "Brakes"),
                .init(name: "Cooling reserve", estimate: 500, required: true, category: "Reliability")
            ]
            projected += 1050

        case .custom:
            reasons.append("Custom mode uses budget, condition and compatibility scoring only.")
        }

        score -= listing.riskTags.count * 4
        if !listing.riskTags.isEmpty {
            warnings.append(contentsOf: listing.riskTags)
        }

        if projected <= mission.totalBudget {
            score += 12
            reasons.append("Projected build fits the total budget.")
        } else {
            let over = projected - mission.totalBudget
            score -= min(25, Int(over / 250))
            warnings.append("Projected build exceeds total budget by about $\(Int(over)).")
        }

        return BuildEvaluation(
            listing: listing,
            mission: mission.type,
            score: max(0, min(100, score)),
            projectedTotal: projected,
            parts: parts,
            reasons: reasons,
            warnings: warnings
        )
    }
}
