import Foundation

/// Source targets for indexed *discovery*, not claims of API integration.
/// Each site remains subject to its own access rules; these queries use
/// connected search providers and never silently scrape authenticated pages.
struct MarketSourceTarget: Identifiable {
    let id: String
    let label: String
    let domain: String
    let category: String
    let country: String
}

enum ExpandedMarketSources {
    static let targets: [MarketSourceTarget] = [
        .init(id:"copart-us",label:"Copart US",domain:"copart.com",category:"Salvage auction",country:"US"),
        .init(id:"iaai-us",label:"IAA US",domain:"iaai.com",category:"Salvage auction",country:"US"),
        .init(id:"bidfax",label:"BidFax",domain:"bidfax.info",category:"Salvage history",country:"US"),
        .init(id:"autobidmaster",label:"AutoBidMaster",domain:"autobidmaster.com",category:"Salvage broker",country:"US"),
        .init(id:"abetterbid",label:"A Better Bid",domain:"abetter.bid",category:"Salvage broker",country:"US"),
        .init(id:"govdeals",label:"GovDeals",domain:"govdeals.com",category:"Government auction",country:"US"),
        .init(id:"publicsurplus",label:"Public Surplus",domain:"publicsurplus.com",category:"Government auction",country:"US"),
        .init(id:"gsa",label:"GSA Auctions",domain:"gsaauctions.gov",category:"Government auction",country:"US"),
        .init(id:"purplewave",label:"Purple Wave",domain:"purplewave.com",category:"Fleet auction",country:"US"),
        .init(id:"proxibid",label:"Proxibid",domain:"proxibid.com",category:"Auction marketplace",country:"US"),
        .init(id:"hibid-us",label:"HiBid US",domain:"hibid.com",category:"Auction marketplace",country:"US"),
        .init(id:"craigslist",label:"Craigslist",domain:"craigslist.org",category:"Classifieds",country:"US"),
        .init(id:"ebay-motors",label:"eBay Motors",domain:"ebay.com",category:"Classifieds and auctions",country:"US"),
        .init(id:"carscom",label:"Cars.com",domain:"cars.com",category:"Classifieds",country:"US"),
        .init(id:"cargurus",label:"CarGurus",domain:"cargurus.com",category:"Classifieds",country:"US"),
        .init(id:"autotrader-us",label:"Autotrader US",domain:"autotrader.com",category:"Classifieds",country:"US"),
        .init(id:"autotempest",label:"AutoTempest",domain:"autotempest.com",category:"Aggregator",country:"Both"),
        .init(id:"theparking",label:"The Parking",domain:"theparking.com",category:"Aggregator",country:"Both"),
        .init(id:"classiccom",label:"CLASSIC.COM",domain:"classic.com",category:"Classic index",country:"Both"),
        .init(id:"hemmings",label:"Hemmings",domain:"hemmings.com",category:"Classic marketplace",country:"US"),
        .init(id:"bringatrailer",label:"Bring a Trailer",domain:"bringatrailer.com",category:"Enthusiast auction",country:"US"),
        .init(id:"carsbids",label:"Cars & Bids",domain:"carsandbids.com",category:"Enthusiast auction",country:"US"),
        .init(id:"barnfinds",label:"Barn Finds",domain:"barnfinds.com",category:"Barn finds",country:"US"),
        .init(id:"racingjunk",label:"RacingJunk",domain:"racingjunk.com",category:"Race cars and parts",country:"US"),
        .init(id:"racecarsdirect",label:"Racecarsdirect",domain:"racecarsdirect.com",category:"Race cars",country:"Both"),
        .init(id:"grassroots",label:"Grassroots Motorsports",domain:"grassrootsmotorsports.com",category:"Project community",country:"US"),
        .init(id:"ls1tech",label:"LS1Tech",domain:"ls1tech.com",category:"Swap forum",country:"US"),
        .init(id:"zilvia",label:"Zilvia",domain:"zilvia.net",category:"Drift forum",country:"US"),
        .init(id:"driftworks",label:"Driftworks",domain:"driftworks.com",category:"Drift forum",country:"Both"),
        .init(id:"bimmerforums",label:"Bimmerforums",domain:"bimmerforums.com",category:"BMW forum",country:"US"),
        .init(id:"corvetteforum",label:"CorvetteForum",domain:"corvetteforum.com",category:"Performance forum",country:"US"),
        .init(id:"pirate4x4",label:"Pirate4x4",domain:"pirate4x4.com",category:"Fabrication forum",country:"US"),
        .init(id:"kijiji",label:"Kijiji",domain:"kijiji.ca",category:"Classifieds",country:"CA"),
        .init(id:"autotrader-ca",label:"AutoTrader Canada",domain:"autotrader.ca",category:"Classifieds",country:"CA"),
        .init(id:"copart-ca",label:"Copart Canada",domain:"copart.ca",category:"Salvage auction",country:"CA"),
        .init(id:"impact",label:"Impact Auto Auctions",domain:"impactauto.ca",category:"Salvage auction",country:"CA"),
        .init(id:"hibid-ca",label:"HiBid Canada",domain:"hibid.com",category:"Auction marketplace",country:"CA"),
        .init(id:"rba",label:"Ritchie Bros",domain:"rbauction.com",category:"Fleet auction",country:"Both"),
        .init(id:"govdeals-ca",label:"GovDeals Canada",domain:"govdeals.ca",category:"Government auction",country:"CA"),
        .init(id:"team",label:"Team Auctions",domain:"teamauctions.com",category:"Regional auction",country:"CA"),
        .init(id:"graham",label:"Graham Auctions",domain:"grahamauctions.com",category:"Regional auction",country:"CA"),
        .init(id:"michener",label:"Michener Allen",domain:"maauctions.com",category:"Regional auction",country:"CA")
    ]

    static func targetQueries(mission: MissionType, budget: Double) -> [(String,String)] {
        let phrase = mission == .drift
            ? "RWD drift project roller shell blown engine salvage"
            : "project car roller salvage parts car mechanic special"
        // Indexed result discovery is intentionally rotated rather than implying
        // that every source supplies an API or a complete live listing feed.
        return targets.map { ($0.label, "site:\($0.domain) \(phrase) under $\(Int(budget))") }
    }
}
