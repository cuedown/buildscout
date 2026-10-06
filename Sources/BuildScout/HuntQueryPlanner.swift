import Foundation

enum HuntQueryPlanner {
    static func queries(
        for profile: MissionProfile,
        location: String
    ) -> [String] {
        let budget = Int(profile.vehicleBudget)
        let region = normalizedRegion(location)

        var queries: [String] = []

        switch profile.type {
        case .drift:
            queries = [
                "RWD project car under $\(budget) \(region)",
                "rear wheel drive mechanic special under $\(budget) \(region)",
                "manual RWD car under $\(budget) \(region)",
                "RWD roller shell project \(region)",
                "RWD needs engine project \(region)",
                "RWD blown engine project car \(region)",
                "unfinished drift project car \(region)",
                "cheap RWD coupe sedan project \(region)",
                "estate project car RWD \(region)",
                "salvage RWD car project \(region)"
            ]

            if profile.allowTransmissionSwap {
                queries.insert(
                    "automatic RWD project car under $\(budget) \(region)",
                    at: 3
                )
                queries.append("RWD chassis manual swap project \(region)")
            }

            if profile.allowNonRunner {
                queries.append("non running RWD car under $\(budget) \(region)")
                queries.append("no engine RWD roller \(region)")
            }

        case .overland:
            queries = [
                "4x4 project SUV under $\(budget) \(region)",
                "AWD SUV mechanic special \(region)",
                "4WD truck mechanic special \(region)",
                "AWD wagon project \(region)",
                "high mileage 4x4 under $\(budget) \(region)",
                "fleet 4x4 vehicle auction \(region)",
                "unfinished overland project \(region)",
                "salvage 4x4 SUV \(region)"
            ]

        case .camper:
            queries = [
                "cargo van project under $\(budget) \(region)",
                "minivan mechanic special \(region)",
                "wagon camper project \(region)",
                "SUV camper project under $\(budget) \(region)",
                "fleet van auction \(region)",
                "high mileage cargo van \(region)",
                "unfinished camper conversion vehicle \(region)"
            ]

        case .rally:
            queries = [
                "AWD manual project car under $\(budget) \(region)",
                "4WD manual project car \(region)",
                "rally car shell project \(region)",
                "AWD mechanic special \(region)",
                "winter beater manual project \(region)",
                "unfinished rally project car \(region)",
                "salvage AWD manual car \(region)"
            ]

        case .track:
            queries = [
                "manual project car under $\(budget) \(region)",
                "track car project \(region)",
                "roller chassis sports car \(region)",
                "sports car needs engine \(region)",
                "unfinished race car project \(region)",
                "salvage sports car project \(region)",
                "mechanic special coupe manual \(region)"
            ]

        case .winter:
            queries = [
                "AWD winter beater under $\(budget) \(region)",
                "4x4 mechanic special under $\(budget) \(region)",
                "AWD wagon cheap \(region)",
                "4WD SUV cheap project \(region)",
                "fleet AWD auction \(region)",
                "high mileage AWD car \(region)"
            ]

        case .custom:
            queries = [
                "project car under $\(budget) \(region)",
                "mechanic special vehicle \(region)",
                "unfinished project car \(region)",
                "does not run vehicle \(region)",
                "needs engine vehicle \(region)",
                "roller shell vehicle \(region)",
                "estate vehicle auction \(region)",
                "salvage vehicle project \(region)",
                "lost interest project car \(region)"
            ]
        }

        return dedupe(queries)
    }

    static func legacyQueries(
        for mission: MissionType,
        budget: Double,
        location: String
    ) -> [String] {
        var profile = MissionProfile()
        profile.type = mission
        profile.vehicleBudget = budget
        return queries(for: profile, location: location)
    }

    private static func normalizedRegion(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Canada" : trimmed
    }

    private static func dedupe(_ queries: [String]) -> [String] {
        var seen = Set<String>()
        return queries.filter {
            seen.insert($0.lowercased()).inserted
        }
    }
}
