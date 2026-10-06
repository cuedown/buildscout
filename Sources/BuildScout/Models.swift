import Foundation

enum MissionType: String, CaseIterable, Codable, Identifiable {
    case drift = "Drift"
    case overland = "Overland"
    case camper = "Camper"
    case rally = "Rally"
    case track = "Track"
    case winter = "Winter"
    case custom = "Custom"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .drift: return "steeringwheel"
        case .overland: return "mountain.2"
        case .camper: return "bed.double"
        case .rally: return "flag.checkered"
        case .track: return "gauge.with.dots.needle.67percent"
        case .winter: return "snowflake"
        case .custom: return "wrench.and.screwdriver"
        }
    }
}

enum Drivetrain: String, CaseIterable, Codable, Identifiable {
    case rwd = "RWD"
    case awd = "AWD"
    case fwd = "FWD"
    case fourWD = "4WD"
    case unknown = "Unknown"
    var id: String { rawValue }
}

enum TransmissionType: String, CaseIterable, Codable, Identifiable {
    case manual = "Manual"
    case automatic = "Automatic"
    case none = "Missing"
    case unknown = "Unknown"
    var id: String { rawValue }
}

struct VehicleListing: Identifiable, Codable, Hashable {
    var id = UUID()
    var source: String
    var title: String
    var year: Int
    var make: String
    var model: String
    var price: Double
    var location: String
    var drivetrain: Drivetrain
    var transmission: TransmissionType
    var runs: Bool
    var towRequired: Bool
    var horsepower: Int?
    var notes: String
    var url: String?
    var riskTags: [String] = []
    var strengths: [String] = []
    var vin: String? = nil
    var odometerKM: Double? = nil
}

struct MissionProfile: Codable, Equatable {
    var type: MissionType = .custom
    var vehicleBudget: Double = 5000
    var totalBudget: Double = 10000
    var radiusKM: Double = 250
    var allowNonRunner = true
    var allowTow = true
    var allowTransmissionSwap = true
    var fabricationTolerance = 2
    var preferredDrivetrain: Drivetrain = .unknown
}

struct BuildPart: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var estimate: Double
    var required: Bool
    var category: String
}

struct BuildEvaluation: Identifiable {
    let id = UUID()
    let listing: VehicleListing
    let mission: MissionType
    let score: Int
    let projectedTotal: Double
    let parts: [BuildPart]
    let reasons: [String]
    let warnings: [String]

    var deltaToBudget: Double { projectedTotal - listing.price }
}

struct SourceDescriptor: Identifiable {
    let id = UUID()
    var name: String
    var category: String
    var status: String
    var method: String
    var notes: String
}
