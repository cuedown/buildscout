import Foundation

enum SeedData {
    static let listings: [VehicleListing] = [
        .init(source: "Demo", title: "2007 BMW 328i E90 6MT", year: 2007, make: "BMW", model: "328i E90", price: 2500, location: "Edmonton, AB", drivetrain: .rwd, transmission: .manual, runs: true, towRequired: false, horsepower: 230, notes: "Healthy N52, suspension work needed.", url: nil, riskTags: ["Leaking struts", "Power steering fault"], strengths: ["Welded diff", "6-speed manual"]),
        .init(source: "Demo", title: "2007 Mazda RX-8 roller", year: 2007, make: "Mazda", model: "RX-8", price: 1000, location: "Calgary, AB", drivetrain: .rwd, transmission: .none, runs: false, towRequired: true, horsepower: nil, notes: "Engine missing. Great chassis, expensive path to completion.", url: nil, riskTags: ["No engine", "Swap fabrication"], strengths: ["Good chassis geometry"]),
        .init(source: "Demo", title: "1994 Ford Mustang 5.0", year: 1994, make: "Ford", model: "Mustang", price: 3000, location: "Edmonton, AB", drivetrain: .rwd, transmission: .manual, runs: true, towRequired: false, horsepower: 215, notes: "Runs and drives. 3rd/4th gear crunch.", url: nil, riskTags: ["Transmission wear"], strengths: ["Welded diff", "V8 torque", "Manual"]),
        .init(source: "Demo", title: "2004 Nissan 350Z drift build", year: 2004, make: "Nissan", model: "350Z", price: 7500, location: "Southern Alberta", drivetrain: .rwd, transmission: .manual, runs: true, towRequired: false, horsepower: 287, notes: "Angle kit, coilovers, hydro, cage, welded diff.", url: nil, riskTags: [], strengths: ["Welded diff", "Angle kit", "Cage", "Hydraulic handbrake"]),
        .init(source: "Demo", title: "2003 Subaru Forester XT", year: 2003, make: "Subaru", model: "Forester XT", price: 4200, location: "Red Deer, AB", drivetrain: .awd, transmission: .manual, runs: true, towRequired: false, horsepower: 210, notes: "A strong overland/winter candidate.", url: nil, riskTags: ["Rust inspection required"], strengths: ["AWD", "Cargo room"])
    ]

    static let sources: [SourceDescriptor] = [
        .init(name: "Manual URL import", category: "Universal", status: "Ready", method: "Paste / JSON", notes: "Works with any listing without bypassing site restrictions."),
        .init(name: "CSV / JSON import", category: "Universal", status: "Ready", method: "File import", notes: "Bulk ingest exported or community-curated listing data."),
        .init(name: "Auction adapter protocol", category: "Auctions", status: "Scaffolded", method: "Provider API/feed", notes: "Add compliant provider adapters without changing the core app."),
        .init(name: "Parts adapter protocol", category: "Parts", status: "Scaffolded", method: "Provider API/feed", notes: "Normalize parts, donor drivetrains, and used components."),
        .init(name: "Marketplace adapter protocol", category: "Classifieds", status: "Scaffolded", method: "Provider-approved", notes: "Designed for approved APIs, feeds, user imports, and permitted browser workflows.")
    ]
}
