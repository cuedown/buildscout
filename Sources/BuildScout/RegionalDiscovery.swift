import Foundation

/// Expands an individual Calgary hunt into independent, freshly fetched market lanes.
/// This is deliberately bounded: a "nationwide" label must not imply exhaustive inventory.
enum RegionalDiscovery {
    static let canadianHubs: [String] = [
        "Vancouver, British Columbia", "Kelowna, British Columbia",
        "Calgary, Alberta", "Edmonton, Alberta",
        "Regina, Saskatchewan", "Saskatoon, Saskatchewan",
        "Winnipeg, Manitoba", "Toronto, Ontario", "Ottawa, Ontario",
        "Montreal, Quebec", "Quebec City, Quebec",
        "Fredericton, New Brunswick", "Halifax, Nova Scotia",
        "Charlottetown, Prince Edward Island",
        "St. John's, Newfoundland and Labrador",
        "Whitehorse, Yukon", "Yellowknife, Northwest Territories",
        "Iqaluit, Nunavut"
    ]

    static func canadaWide(request: HuntRequest) async -> [HuntResult] {
        await withTaskGroup(of: [HuntResult].self) { group in
            for hub in canadianHubs {
                var regional = request
                regional.location = hub
                regional.radiusKM = 1000
                group.addTask {
                    await AutoTraderPublicClient.search(request: regional, maxPages: 3)
                }
            }
            var rows: [HuntResult] = []
            for await batch in group { rows.append(contentsOf: batch) }
            return rows
        }
    }

    /// These are discovery-only leads. Price/title/import eligibility must be verified
    /// before converting to a purchasable/buildable finalist.
    @MainActor
    static func usDiscovery(request: HuntRequest, connections: ConnectionStore) async -> [HuntResult] {
        guard connections.hasAnyWebSearch else { return [] }
        let base = request.mission == .drift
            ? "RWD coupe sedan roller project drift salvage"
            : "project vehicle roller salvage non running"

        let lanes: [(String, String)] = [
            ("US aged vehicles", "\(base) older than 15 years site:copart.com OR site:iaai.com OR site:craigslist.org"),
            ("US newer admissibility-check", "\(base) salvage project site:copart.com OR site:iaai.com OR site:autotempest.com"),
            ("Canadian return / cross-border loss", "\"Canadian title\" OR \"Canadian registered\" OR \"Canada import\" salvage car site:copart.com OR site:iaai.com"),
            ("Canadian return / insurance loss", "\"Canadian vehicle\" OR \"Canadian plates\" insurance total loss auction USA")
        ]

        var gathered: [HuntResult] = []
        for (label, query) in lanes {
            var scoped = request
            scoped.location = "United States"
            scoped.keywords = [query]
            let batch = await FreeWebDiscovery.search(request: scoped, connections: connections)
            gathered.append(contentsOf: batch.map { item in
                var lead = item
                lead.provider = "\(label) • \(item.provider)"
                // Search snippets provide no trustworthy FX/currency or title evidence.
                // Do not falsely present a US$ price as CA$ or promote it to a finalist.
                lead.price = nil
                lead.currency = nil
                lead.snippet += " • US lead: verify VIN, manufacture month, FMVSS/CMVSS, title, import pathway, price currency and landed cost"
                return lead
            })
        }
        return gathered
    }
}
