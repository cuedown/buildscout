import Foundation

struct GarageProfile: Codable, Equatable {
    var basicMechanics: Int = 2
    var fabrication: Int = 0
    var welding: Int = 0
    var electrical: Int = 1
    var drivetrainSwaps: Int = 0

    var canTow: Bool = false
    var hasMechanicFriends: Bool = false
    var hasGarageSpace: Bool = true

    var tools: Set<GarageTool> = [
        .socketSet,
        .breakerBar,
        .drill,
        .impact
    ]

    static let starter = GarageProfile()
}

enum GarageTool: String, CaseIterable, Codable, Hashable, Identifiable {
    case socketSet = "Socket set"
    case breakerBar = "Breaker bar"
    case torqueWrench = "Torque wrench"
    case impact = "Impact wrench"
    case drill = "Drill"
    case jackStands = "Floor jack + stands"
    case multimeter = "Multimeter"
    case grinder = "Angle grinder"
    case welder = "Welder"
    case engineHoist = "Engine hoist"
    case transmissionJack = "Transmission jack"
    case compressionTester = "Compression tester"
    case scanTool = "Scan tool"
    case springCompressor = "Spring compressor"

    var id: String { rawValue }

    var category: String {
        switch self {
        case .socketSet, .breakerBar, .torqueWrench, .impact, .drill:
            return "Core"
        case .jackStands, .springCompressor:
            return "Chassis"
        case .multimeter, .scanTool:
            return "Diagnostics"
        case .grinder, .welder:
            return "Fabrication"
        case .engineHoist, .transmissionJack, .compressionTester:
            return "Drivetrain"
        }
    }
}

enum GarageFit {
    static func assess(
        listing: VehicleListing,
        mission: MissionProfile,
        garage: GarageProfile,
        parts: [BuildPart]
    ) -> (score: Int, addedCost: Double, reasons: [String], warnings: [String]) {
        var score = 0
        var addedCost: Double = 0
        var reasons: [String] = []
        var warnings: [String] = []

        if garage.hasMechanicFriends {
            score += 3
            reasons.append("Mechanic help is available for diagnosis or jobs beyond the owner's current skill level.")
        }

        if listing.towRequired && !garage.canTow {
            addedCost += 150
            warnings.append("No towing capability recorded; transport contingency increased.")
        }

        if !listing.runs && garage.basicMechanics < 2 {
            score -= 6
            addedCost += 500
            warnings.append("Non-running diagnosis exceeds the current basic-mechanics profile.")
        }

        if parts.contains(where: { $0.name.localizedCaseInsensitiveContains("Manual swap") }) &&
            garage.drivetrainSwaps < 2 {
            score -= 8
            addedCost += garage.hasMechanicFriends ? 600 : 1200
            warnings.append("Transmission swap likely needs outside help or a learning-time reserve.")
        }

        if mission.type == .drift {
            let critical: Set<GarageTool> = [.socketSet, .breakerBar, .jackStands, .torqueWrench]
            let missing = critical.subtracting(garage.tools)
            if missing.isEmpty {
                score += 4
                reasons.append("Garage has the core tools for baseline drift prep.")
            } else {
                addedCost += Double(missing.count) * 120
                warnings.append("Core tool gaps: \(missing.map(\.rawValue).sorted().joined(separator: ", ")).")
            }
        }

        return (score, addedCost, reasons, warnings)
    }
}
