import Foundation

extension HunterDirectory {
    static let supplementalSources: [HunterSource] = [
        .init(
            id: "craigslist",
            name: "Craigslist",
            kind: .classifieds,
            region: "North America",
            url: URL(string: "https://www.craigslist.org/")!,
            notes: "Private-sale cars and parts. Optional third-party actor discovery can be enabled in Connections.",
            strengths: ["Private sellers", "Cheap projects", "Parts"]
        ),
        .init(
            id: "iaa",
            name: "IAA",
            kind: .salvage,
            region: "United States / cross-border",
            url: URL(string: "https://www.iaai.com/")!,
            notes: "Insurance/salvage auction inventory. Useful when cross-border sourcing makes sense.",
            strengths: ["Salvage", "Damage data", "Auctions"]
        ),
        .init(
            id: "carscout-ca",
            name: "CarScout",
            kind: .classifieds,
            region: "Canada",
            url: URL(string: "https://getcarscout.ca/")!,
            notes: "Canadian multi-market discovery and deal intelligence.",
            strengths: ["Aggregator", "Canada", "Deal scoring"]
        ),
        .init(
            id: "autotempest",
            name: "AutoTempest",
            kind: .classifieds,
            region: "Canada / United States",
            url: URL(string: "https://www.autotempest.com/")!,
            notes: "Cross-market vehicle search and comparison source.",
            strengths: ["Aggregator", "Comparison", "Broad inventory"]
        ),
        .init(
            id: "classic-com",
            name: "CLASSIC.COM",
            kind: .auction,
            region: "International",
            url: URL(string: "https://www.classic.com/")!,
            notes: "Specialty vehicle index with auction, dealer, private and historical-comparable data.",
            strengths: ["Specialty cars", "Comps", "Auctions"]
        ),
        .init(
            id: "the-parking",
            name: "The Parking",
            kind: .classifieds,
            region: "International",
            url: URL(string: "https://www.theparking.ca/")!,
            notes: "Large multi-market used-car index, useful for unusual chassis and wider-radius searches.",
            strengths: ["Aggregator", "International", "Long-tail inventory"]
        ),
        .init(
            id: "ebay-motors",
            name: "eBay Motors",
            kind: .parts,
            region: "Canada / International",
            url: URL(string: "https://www.ebay.ca/b/Auto-Parts-and-Vehicles/6000/bn_1865334")!,
            notes: "BuildScout also supports the official eBay Browse API for live parts searches.",
            strengths: ["Parts", "Donors", "Official API"]
        )
    ]

    static var allSources: [HunterSource] {
        sources + supplementalSources
    }
}
