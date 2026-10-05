# BuildScout source federation

BuildScout intentionally uses more than one acquisition method. Automotive inventory is fragmented across official APIs, marketplace websites, auction platforms, enthusiast forums, aggregators, and community-maintained collectors.

The normalizer turns all of those inputs into the same internal vehicle / part / auction records.

## Zero-config public data

| Provider | Purpose | Method |
| --- | --- | --- |
| NHTSA vPIC | VIN identity and vehicle specification data | Public API |
| NHTSA Recalls | Recall campaigns | Public API |
| NHTSA Complaints | Owner complaint signal | Public API |
| NHTSA Safety Ratings | Crash-test variant discovery | Public API |
| FuelEconomy.gov | Engine / drivetrain / transmission / economy configurations | Public API |

## Bring-your-own-key integrations

| Provider | Purpose | Method |
| --- | --- | --- |
| MarketCheck | Dealer and private-party inventory, comparables | Official commercial API |
| eBay Browse | Parts and donor-component search | Official OAuth API |
| CarsXE | Optional vehicle history / value / VIN intelligence | Commercial API |
| SerpApi | Broad indexed discovery, Shopping, eBay, YouTube and Maps | Commercial search API |
| Apify | Optional third-party marketplace and auction actors | Actor API |

Secrets are stored in macOS Keychain and are never committed to the repository.

## Optional Apify actor sources

These adapters are disabled by default because actor runs can consume credits and because users must evaluate the current terms of both the actor and the underlying source.

Current actor adapters:

- Facebook Marketplace
- Kijiji
- Craigslist
- Copart
- IAA

BuildScout limits the result count per source from the Connections screen.

## Federated indexed sources

When SerpApi is configured, BuildScout can run domain-scoped discovery against large automotive indexes instead of implementing another bespoke crawler:

- CarScout
- AutoTempest
- CLASSIC.COM
- The Parking
- Bring a Trailer
- Cars & Bids

These are treated as discovery sources. BuildScout does not pretend an undocumented first-party inventory API exists.

## Enthusiast forums

BuildScout currently performs domain-scoped indexed searches for vehicle classifieds, used parts and build knowledge across communities including:

- Bimmerforums
- E46Fanatics
- Bimmerpost
- Zilvia
- MY350Z
- G35Driver
- NASIOC
- Mustang6G
- Corral
- Turbobricks
- ClubLexus
- RX8Club
- Grassroots Motorsports
- Expedition Portal
- IH8MUD

A future adapter can replace indexed discovery with an official Discourse API, XenForo API, RSS/Atom feed, or forum-provided read-only key whenever a community offers one.

## Community collectors / open-source bridges

BuildScout does not need to copy every scraper into the application. It can ingest arbitrary JSON and CSV exports through the flexible external-dataset normalizer.

Reference projects include:

- jamir0quai/car-aggregator
- Frojoe6969/usa-car-search
- automationbyexperts/kijiji-scraper
- logiover/craigslist-scraper
- AdsTable/car-aggregator

The importer recognizes common aliases for listing title, year, make, model, price, URL, location, VIN, odometer, drivetrain, transmission, running state, damage and title status.

Always respect the license and source-site terms applicable to a community collector. BuildScout's compatibility with an export format is not a claim that every collection method is permitted everywhere.

## Cross-source deduplication and history

A live hunt now deduplicates across providers in this order:

1. VIN, when present.
2. Canonical listing URL.
3. A conservative fingerprint assembled from normalized vehicle identity, price bucket, odometer bucket and location.

When duplicates collide, BuildScout keeps the richer record and merges provider attribution.

BuildScout also records observations locally. Repeated hunts can show:

- how many times a listing has been seen
- the previous observed price
- price drops

History stays on the user's Mac under BuildScout Application Support.

## Design rule

No single source is allowed to become BuildScout's architecture.

A source can disappear, change terms, change HTML, raise prices, break an API, or restrict geography. The application should degrade gracefully and keep the vehicle/build reasoning layer independent of acquisition.
