import Foundation

enum ProviderTier: String, CaseIterable {
    case live = "LIVE"
    case optional = "OPTIONAL KEY"
    case directory = "DIRECTORY"
    case planned = "PLANNED"
    case degraded = "DEGRADED"
}

struct ProviderCatalogEntry: Identifiable {
    let id: String
    let name: String
    let tier: ProviderTier
    let category: String
    let capabilities: [String]
    let auth: String
    let endpoint: String?
    let notes: String
    let documentationURL: URL?
}

enum ProviderCatalog {
    static let entries: [ProviderCatalogEntry] = [
        .init(
            id: "nhtsa-vpic",
            name: "NHTSA vPIC",
            tier: .live,
            category: "Vehicle identity",
            capabilities: ["VIN decode", "Canadian dimensions/specs", "make/model identity"],
            auth: "None",
            endpoint: "vpic.nhtsa.dot.gov/api/vehicles",
            notes: "Core identity provider used before vehicle/build reasoning.",
            documentationURL: URL(string: "https://vpic.nhtsa.dot.gov/api/")
        ),
        .init(
            id: "nhtsa-recalls",
            name: "NHTSA Recalls API",
            tier: .live,
            category: "Safety",
            capabilities: ["recalls by year/make/model", "campaign lookup"],
            auth: "None",
            endpoint: "api.nhtsa.gov/recalls",
            notes: "Queried in Vehicle Intel.",
            documentationURL: URL(string: "https://www.nhtsa.gov/nhtsa-datasets-and-apis")
        ),
        .init(
            id: "nhtsa-complaints",
            name: "NHTSA Complaints API",
            tier: .live,
            category: "Reliability signal",
            capabilities: ["owner complaints", "crash/fire flags", "component aggregation"],
            auth: "None",
            endpoint: "api.nhtsa.gov/complaints",
            notes: "Useful as a signal, not proof of failure probability.",
            documentationURL: URL(string: "https://www.nhtsa.gov/nhtsa-datasets-and-apis")
        ),
        .init(
            id: "nhtsa-ratings",
            name: "NHTSA Safety Ratings API",
            tier: .live,
            category: "Safety",
            capabilities: ["tested variant discovery", "VehicleId lookup path"],
            auth: "None",
            endpoint: "api.nhtsa.gov/SafetyRatings",
            notes: "Variant discovery is live; detailed rating drill-down is next.",
            documentationURL: URL(string: "https://www.nhtsa.gov/nhtsa-datasets-and-apis")
        ),
        .init(
            id: "fueleconomy",
            name: "FuelEconomy.gov",
            tier: .live,
            category: "Vehicle specs",
            capabilities: ["configuration matching", "drivetrain", "transmission", "engine", "EPA MPG"],
            auth: "None",
            endpoint: "fueleconomy.gov/ws/rest",
            notes: "Keyless EPA/DOE service used to disambiguate model configurations.",
            documentationURL: URL(string: "https://www.fueleconomy.gov/feg/ws/index.shtml")
        ),
        .init(
            id: "serp-google",
            name: "SerpApi • Google",
            tier: .optional,
            category: "Market discovery",
            capabilities: ["web hunt", "auction-domain discovery", "forums", "price snippets"],
            auth: "User API key",
            endpoint: "serpapi.com/search.json?engine=google",
            notes: "Broad discovery layer for sources without a public inventory API.",
            documentationURL: URL(string: "https://serpapi.com/")
        ),
        .init(
            id: "serp-shopping",
            name: "SerpApi • Google Shopping",
            tier: .optional,
            category: "Parts",
            capabilities: ["live product search", "merchant price discovery"],
            auth: "User API key",
            endpoint: "serpapi.com/search.json?engine=google_shopping_light",
            notes: "Feeds Build Lab sourced BOM options.",
            documentationURL: URL(string: "https://serpapi.com/google-shopping-light-api")
        ),
        .init(
            id: "serp-ebay",
            name: "SerpApi • eBay",
            tier: .optional,
            category: "Parts",
            capabilities: ["eBay.ca search", "used parts", "donor components"],
            auth: "User API key",
            endpoint: "serpapi.com/search.json?engine=ebay",
            notes: "Independent fallback/second opinion beside native eBay Browse.",
            documentationURL: URL(string: "https://serpapi.com/ebay-search-api")
        ),
        .init(
            id: "serp-youtube",
            name: "SerpApi • YouTube",
            tier: .optional,
            category: "Research",
            capabilities: ["build guides", "swap walkthroughs", "repair videos"],
            auth: "User API key",
            endpoint: "serpapi.com/search.json?engine=youtube",
            notes: "Feeds the Research workspace.",
            documentationURL: URL(string: "https://serpapi.com/youtube-search-api")
        ),
        .init(
            id: "serp-maps",
            name: "SerpApi • Google Maps",
            tier: .optional,
            category: "Local services",
            capabilities: ["fabricators", "alignment shops", "machine shops", "salvage yards", "towing"],
            auth: "User API key",
            endpoint: "serpapi.com/search.json?engine=google_maps",
            notes: "Feeds local help around the build location.",
            documentationURL: URL(string: "https://serpapi.com/google-maps-api")
        ),
        .init(
            id: "ebay-browse",
            name: "eBay Browse API",
            tier: .optional,
            category: "Parts",
            capabilities: ["native item search", "prices", "parts ecosystem", "future compatibility calls"],
            auth: "eBay Client ID + Secret",
            endpoint: "api.ebay.com/buy/browse/v1",
            notes: "Uses client-credentials OAuth and EBAY_CA marketplace context.",
            documentationURL: URL(string: "https://developer.ebay.com/api-docs/buy/api-browse.html")
        ),
        .init(
            id: "transport-canada-recall",
            name: "Transport Canada Vehicle Recalls API",
            tier: .degraded,
            category: "Canadian safety",
            capabilities: ["Canadian recall records"],
            auth: "None",
            endpoint: "data.tc.gc.ca/v1.3/api/eng/vehicle-recall-database",
            notes: "Documented public API, but current live probes returned HTTP 500. Keep adapter isolated and fall back to public datasets/search until healthy.",
            documentationURL: URL(string: "https://open.canada.ca/data/en/dataset/1ec92326-47ef-4110-b7ca-959fab03f96d")
        ),
        .init(
            id: "transport-canada-bulk",
            name: "Transport Canada Full Recall CSV",
            tier: .planned,
            category: "Canadian safety",
            capabilities: ["complete monthly recall archive", "offline indexing"],
            auth: "None",
            endpoint: "opendatatc.tc.canada.ca/vrdb_full_monthly.csv",
            notes: "Large dataset (~200 MB currently). Planned as optional background download + local index, not a launch-time fetch.",
            documentationURL: URL(string: "https://open.canada.ca/data/en/dataset/1ec92326-47ef-4110-b7ca-959fab03f96d")
        ),
        .init(
            id: "canada-recalls-open",
            name: "Canada Recalls & Safety Alerts Open Data",
            tier: .planned,
            category: "Canadian safety",
            capabilities: ["Transport Canada alert discovery", "recall page URLs"],
            auth: "None",
            endpoint: "recalls-rappels.canada.ca/.../HCRSAMOpenData.json",
            notes: "Smaller open JSON feed; useful as a Canadian recall-alert index.",
            documentationURL: URL(string: "https://open.canada.ca/data/en/dataset/d38de914-c94c-429b-8ab1-8776c31643e3")
        ),
        .init(
            id: "copart",
            name: "Copart Canada",
            tier: .directory,
            category: "Auctions",
            capabilities: ["salvage", "repairable vehicles", "non-runners"],
            auth: "No public BuildScout adapter",
            endpoint: nil,
            notes: "Available through Hunter directory and optional web-search discovery.",
            documentationURL: URL(string: "https://www.copart.ca/")
        ),
        .init(
            id: "iaa",
            name: "IAA",
            tier: .directory,
            category: "Auctions",
            capabilities: ["salvage auctions", "damaged vehicles"],
            auth: "No public BuildScout adapter",
            endpoint: nil,
            notes: "Directory / web discovery until a provider-approved inventory integration exists.",
            documentationURL: URL(string: "https://www.iaai.com/")
        ),
        .init(
            id: "team-auctions",
            name: "Team Auctions",
            tier: .directory,
            category: "Auctions",
            capabilities: ["farm", "estate", "equipment", "vehicles"],
            auth: "Website",
            endpoint: nil,
            notes: "High-value source for weird Alberta project candidates.",
            documentationURL: URL(string: "https://www.teamauctions.com/")
        ),
        .init(
            id: "graham",
            name: "Graham Auctions",
            tier: .directory,
            category: "Auctions",
            capabilities: ["Calgary vehicles", "repos", "trade-ins", "no-reserve"],
            auth: "Website",
            endpoint: nil,
            notes: "Local source indexed through Hunter.",
            documentationURL: URL(string: "https://grahamauctions.com/calgary-car-auction/")
        ),
        .init(
            id: "michener-allen",
            name: "Michener Allen",
            tier: .directory,
            category: "Auctions",
            capabilities: ["public vehicle auction", "equipment"],
            auth: "Website",
            endpoint: nil,
            notes: "Alberta source indexed through Hunter.",
            documentationURL: URL(string: "https://www.maauctions.com/")
        ),
        .init(
            id: "facebook-marketplace",
            name: "Facebook Marketplace",
            tier: .directory,
            category: "Classifieds",
            capabilities: ["private sellers", "project cars", "parts"],
            auth: "User browser session",
            endpoint: nil,
            notes: "No private session/cookie scraping is embedded. Use manual import or optional compliant discovery provider.",
            documentationURL: URL(string: "https://www.facebook.com/marketplace/")
        ),
        .init(
            id: "kijiji",
            name: "Kijiji / Kijiji Autos",
            tier: .directory,
            category: "Classifieds",
            capabilities: ["private vehicles", "parts", "regional projects"],
            auth: "Website",
            endpoint: nil,
            notes: "Manual import / discovery until a supported inventory feed is available.",
            documentationURL: URL(string: "https://www.kijijiautos.ca/")
        ),
        .init(
            id: "autotrader",
            name: "AutoTrader Canada",
            tier: .directory,
            category: "Classifieds",
            capabilities: ["market comps", "dealer/private inventory"],
            auth: "Website / partner feeds",
            endpoint: nil,
            notes: "Useful market-comp source; BuildScout does not assume a public inventory API.",
            documentationURL: URL(string: "https://www.autotrader.ca/")
        ),
        .init(
            id: "apify-facebook",
            name: "Apify • Facebook Marketplace",
            tier: .optional,
            category: "Classifieds",
            capabilities: ["public listing search", "vehicle details", "price", "location", "images"],
            auth: "Apify API token",
            endpoint: "automly/facebook-marketplace-scraper",
            notes: "Third-party actor integration. Disabled by default; users are responsible for source and actor terms.",
            documentationURL: URL(string: "https://apify.com/automly/facebook-marketplace-scraper")
        ),
        .init(
            id: "apify-kijiji",
            name: "Apify • Kijiji",
            tier: .optional,
            category: "Classifieds",
            capabilities: ["vehicle search", "price", "year/make/model", "kilometres", "drivetrain", "photos"],
            auth: "Apify API token",
            endpoint: "fayoussef/kijiji-scraper",
            notes: "Third-party actor integration. Disabled by default; users are responsible for source and actor terms.",
            documentationURL: URL(string: "https://apify.com/fayoussef/kijiji-scraper")
        ),
        .init(
            id: "apify-craigslist",
            name: "Apify • Craigslist",
            tier: .optional,
            category: "Classifieds",
            capabilities: ["cars/trucks search", "price", "location", "images", "description"],
            auth: "Apify API token",
            endpoint: "logiover/craigslist-scraper",
            notes: "Third-party actor integration. Disabled by default; users are responsible for source and actor terms.",
            documentationURL: URL(string: "https://apify.com/logiover/craigslist-scraper")
        ),
        .init(
            id: "apify-copart",
            name: "Apify • Copart",
            tier: .optional,
            category: "Auctions",
            capabilities: ["salvage lots", "VIN", "damage", "odometer", "bids", "auction dates"],
            auth: "Apify API token",
            endpoint: "crawlerbros/copart-public-search-scraper",
            notes: "Third-party auction actor. Disabled by default and rate/cost bounded in Connections.",
            documentationURL: URL(string: "https://apify.com/crawlerbros/copart-public-search-scraper")
        ),
        .init(
            id: "apify-iaa",
            name: "Apify • IAA",
            tier: .optional,
            category: "Auctions",
            capabilities: ["salvage lots", "damage", "odometer", "title", "run-and-drive", "ACV"],
            auth: "Apify API token",
            endpoint: "scrapers_lat/iaai-salvage-cars-scraper",
            notes: "Third-party auction actor. IAA inventory is primarily U.S.; keep geography explicit.",
            documentationURL: URL(string: "https://apify.com/scrapers_lat/iaai-salvage-cars-scraper")
        ),
        .init(
            id: "carscout",
            name: "CarScout",
            tier: .directory,
            category: "Aggregators",
            capabilities: ["Canadian multi-market discovery", "deal scoring", "Facebook/Kijiji/AutoTrader/Craigslist coverage"],
            auth: "Website / indexed discovery",
            endpoint: nil,
            notes: "No BuildScout API assumed. Used as a federated indexed source when web discovery is connected.",
            documentationURL: URL(string: "https://getcarscout.ca/")
        ),
        .init(
            id: "autotempest",
            name: "AutoTempest",
            tier: .directory,
            category: "Aggregators",
            capabilities: ["cross-market search", "comparison links", "vehicle discovery"],
            auth: "Website / indexed discovery",
            endpoint: nil,
            notes: "Used as a federated indexed source; no undocumented first-party API is assumed.",
            documentationURL: URL(string: "https://www.autotempest.com/")
        ),
        .init(
            id: "classic-com",
            name: "CLASSIC.COM",
            tier: .directory,
            category: "Aggregators",
            capabilities: ["auction/dealer/private index", "historical comps", "specialty inventory"],
            auth: "Website / indexed discovery",
            endpoint: nil,
            notes: "Useful for unusual chassis and valuation comps; accessed through indexed discovery until licensed API access exists.",
            documentationURL: URL(string: "https://www.classic.com/")
        ),
        .init(
            id: "the-parking",
            name: "The Parking",
            tier: .directory,
            category: "Aggregators",
            capabilities: ["international listing index", "used-car discovery"],
            auth: "Website / indexed discovery",
            endpoint: nil,
            notes: "Federated indexed source, especially useful when the search radius expands beyond one marketplace.",
            documentationURL: URL(string: "https://www.theparking.ca/")
        ),
        .init(
            id: "oss-car-aggregator",
            name: "jamir0quai/car-aggregator",
            tier: .directory,
            category: "Community bridges",
            capabilities: ["normalized SQLite", "price history", "AutoTrader/eBay/Facebook adapter architecture"],
            auth: "Local/community project",
            endpoint: nil,
            notes: "Architecture/reference bridge only. BuildScout can ingest exported normalized data without embedding its scraping behavior.",
            documentationURL: URL(string: "https://github.com/jamir0quai/car-aggregator")
        ),
        .init(
            id: "oss-usa-car-search",
            name: "Frojoe6969/usa-car-search",
            tier: .directory,
            category: "Community bridges",
            capabilities: ["seven-source aggregation", "VIN/fingerprint dedupe", "removed-listing tracking", "deal scoring"],
            auth: "Local/community project",
            endpoint: nil,
            notes: "MIT-licensed reference project; useful for dedupe, seen-state and provider isolation patterns.",
            documentationURL: URL(string: "https://github.com/Frojoe6969/usa-car-search")
        ),
        .init(
            id: "oss-auction-aggregator",
            name: "AdsTable/car-aggregator",
            tier: .directory,
            category: "Community bridges",
            capabilities: ["Copart/IAA aggregation", "scheduled crawling", "normalized auction backend"],
            auth: "Local/community project",
            endpoint: nil,
            notes: "Reference implementation for auction normalization and background-job architecture.",
            documentationURL: URL(string: "https://github.com/AdsTable/car-aggregator")
        ),
        .init(
            id: "forum-federation",
            name: "Enthusiast forum federation",
            tier: .optional,
            category: "Forums / classifieds",
            capabilities: ["vehicle classifieds", "used parts", "build threads", "swap knowledge"],
            auth: "SerpApi indexed discovery; direct forum APIs/feeds can be added later",
            endpoint: nil,
            notes: "Domain-scoped discovery currently covers BMW, Nissan/VQ, Subaru, Mustang, Volvo, Lexus, RX-8, grassroots motorsport and overland communities.",
            documentationURL: nil
        )
    ]
}
