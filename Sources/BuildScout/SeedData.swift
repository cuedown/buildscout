import Foundation

enum SeedData {
    static let listings: [VehicleListing] = []

    static let sources: [SourceDescriptor] = [
        .init(name: "Manual URL import", category: "Universal", status: "Ready", method: "Paste / JSON", notes: "Works with any listing without bypassing site restrictions."),
        .init(name: "CSV / JSON import", category: "Universal", status: "Ready", method: "File import", notes: "Bulk ingest exported or community-curated listing data."),
        .init(name: "Auction adapter protocol", category: "Auctions", status: "Scaffolded", method: "Provider API/feed", notes: "Add compliant provider adapters without changing the core app."),
        .init(name: "Parts adapter protocol", category: "Parts", status: "Scaffolded", method: "Provider API/feed", notes: "Normalize parts, donor drivetrains, and used components."),
        .init(name: "Marketplace adapter protocol", category: "Classifieds", status: "Scaffolded", method: "Provider-approved", notes: "Designed for approved APIs, feeds, user imports, and permitted browser workflows.")
    ]
}
