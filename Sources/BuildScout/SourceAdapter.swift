import Foundation

protocol ListingSourceAdapter {
    var id: String { get }
    var displayName: String { get }
    var kind: SourceKind { get }
    var capabilities: Set<SourceCapability> { get }

    func fetch(query: SourceQuery) async throws -> [VehicleListing]
}

enum SourceKind: String, Codable {
    case classifieds
    case auction
    case salvage
    case parts
    case community
    case importFile
}

enum SourceCapability: String, Hashable, Codable {
    case keywordSearch
    case radius
    case priceRange
    case liveInventory
    case priceHistory
    case parts
}

struct SourceQuery: Codable {
    var keywords: [String]
    var location: String?
    var radiusKM: Double?
    var maximumPrice: Double?
    var mission: MissionType
}

struct ImportedFileAdapter: ListingSourceAdapter {
    let id = "file-import"
    let displayName = "JSON / CSV import"
    let kind: SourceKind = .importFile
    let capabilities: Set<SourceCapability> = []

    func fetch(query: SourceQuery) async throws -> [VehicleListing] {
        []
    }
}
