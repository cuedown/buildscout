import Foundation

struct HunterSource: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: SourceKind
    let region: String
    let url: URL
    let notes: String
    let strengths: [String]
}

enum HunterDirectory {
    static let sources: [HunterSource] = [
        .init(
            id: "copart-ca",
            name: "Copart Canada",
            kind: .salvage,
            region: "Canada",
            url: URL(string: "https://www.copart.ca/vehicleFinder")!,
            notes: "Salvage, repairable, used, run-and-drive, and auction inventory.",
            strengths: ["Salvage", "Non-runners", "Damage filters", "Auction"]
        ),
        .init(
            id: "graham-calgary",
            name: "Graham Auctions",
            kind: .auction,
            region: "Calgary, Alberta",
            url: URL(string: "https://grahamauctions.com/calgary-car-auction/")!,
            notes: "Calgary public vehicle auctions including trade-ins, repos, and no-reserve inventory.",
            strengths: ["Local", "Public auction", "Repos"]
        ),
        .init(
            id: "team-auctions",
            name: "Team Auctions",
            kind: .auction,
            region: "Alberta / Western Canada",
            url: URL(string: "https://www.teamauctions.com/")!,
            notes: "Equipment, estate, farm, and vehicle auctions. Useful for weird off-market project candidates.",
            strengths: ["Rural", "Estate", "Farm", "Equipment"]
        ),
        .init(
            id: "michener-allen",
            name: "Michener Allen",
            kind: .auction,
            region: "Alberta",
            url: URL(string: "https://www.maauctions.com/")!,
            notes: "Public auto and equipment auction source.",
            strengths: ["Alberta", "Auction", "Fleet / equipment"]
        ),
        .init(
            id: "autotrader-ca",
            name: "AutoTrader Canada",
            kind: .classifieds,
            region: "Canada",
            url: URL(string: "https://www.autotrader.ca/")!,
            notes: "Broad retail/private inventory. Better for market comps than ultra-cheap shells.",
            strengths: ["Market comps", "Broad inventory"]
        ),
        .init(
            id: "kijiji-autos",
            name: "Kijiji Autos",
            kind: .classifieds,
            region: "Canada",
            url: URL(string: "https://www.kijijiautos.ca/")!,
            notes: "Private and dealer vehicles with occasional project-car bargains.",
            strengths: ["Private sellers", "Regional search"]
        ),
        .init(
            id: "facebook-marketplace",
            name: "Facebook Marketplace",
            kind: .classifieds,
            region: "Local / regional",
            url: URL(string: "https://www.facebook.com/marketplace/")!,
            notes: "High-volume private marketplace. BuildScout does not embed credentials or bypass access controls.",
            strengths: ["Private sellers", "Projects", "Parts"]
        )
    ]

    static func queries(for mission: MissionType) -> [String] {
        switch mission {
        case .drift:
            return [
                "RWD manual project",
                "BMW project needs work",
                "blown engine RWD",
                "needs transmission RWD",
                "350Z G35 project",
                "Mustang manual project",
                "E36 E46 E90 project",
                "whole car not parting out",
                "tow away project car",
                "lost interest project"
            ]
        case .overland:
            return [
                "4x4 project SUV",
                "AWD wagon project",
                "high mileage 4x4",
                "fleet SUV auction",
                "needs work 4WD",
                "rural estate SUV"
            ]
        case .camper:
            return [
                "cargo van project",
                "minivan high mileage",
                "wagon project",
                "fleet van auction",
                "retired work van",
                "camper conversion project"
            ]
        case .rally:
            return [
                "AWD manual project",
                "Subaru project car",
                "old 4x4 hatchback",
                "rally project",
                "winter beater manual",
                "farm car project"
            ]
        case .track:
            return [
                "manual coupe project",
                "track car project",
                "needs engine sports car",
                "roller chassis",
                "unfinished race car"
            ]
        case .winter:
            return [
                "AWD winter beater",
                "4x4 high mileage",
                "needs work AWD",
                "old Subaru manual",
                "fleet AWD"
            ]
        case .custom:
            return [
                "project car",
                "mechanic special",
                "does not run",
                "needs engine",
                "needs transmission",
                "tow away",
                "estate vehicle",
                "lost interest"
            ]
        }
    }
}
