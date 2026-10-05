# BuildScout

**Don't search for a car. Tell it what you want to build.**

BuildScout is a free, open-source macOS app for finding and planning project vehicles around a mission instead of a badge.

Choose **Drift, Overland, Camper, Rally, Track, Winter, or Custom**. BuildScout scores candidate vehicles against the thing that actually matters: the complete path from purchase to usable build.

A cheap shell is not automatically a cheap build. BuildScout tries to expose that before your driveway fills with immobile optimism.

## What works now

- Native SwiftUI macOS app
- Mission-aware candidate scoring
- Separate vehicle budget and all-in build budget
- Running / non-running / tow / transmission-swap tolerances
- Projected completion cost
- Required vs optional build items
- Dependency-aware build path
- Platform intelligence for common project-car families
- Risk and known-failure warnings
- Favorite candidates
- Persistent project builds with editable line items, task status, and actual-vs-estimated spend
- Markdown / JSON build export for forum sharing and backups
- Garage skill/tool profile that changes build estimates
- Hunter workspace with live multi-provider discovery
- Autopilot: mission → live hunt → normalize → rank → deep-dive → project
- Live NHTSA vPIC VIN decoding with one-click candidate creation
- NHTSA recall / complaint / safety intelligence
- FuelEconomy.gov configuration lookup
- Official MarketCheck dealer/private inventory integration
- Official eBay Browse parts integration
- Optional SerpApi discovery across web, Shopping, eBay, YouTube, Maps, aggregators and forums
- Optional Apify adapters for Facebook Marketplace, Kijiji, Craigslist, Copart and IAA
- Cross-source VIN / URL / fingerprint deduplication
- Local listing observation history and price-drop detection
- Live parts sourcing plus enthusiast-forum parts discovery
- Local persistence between launches
- Paste-a-listing parser
- BuildScout JSON/CSV plus flexible external scraper/export import
- Original-listing links
- Source-adapter protocol
- Public roadmap and contribution templates

### Seed platform knowledge

The first knowledge pack includes:

- BMW E30
- BMW E36
- BMW E46
- BMW E90
- Nissan 350Z / Z33
- Infiniti G35
- Ford Mustang SN95 / New Edge
- Mazda RX-8
- Hyundai Genesis Coupe
- Volvo 740 / 940
- Lexus IS300 / Altezza

This is intentionally community-expandable rather than pretending one maintainer can know every viable chassis on earth.

## Example

A $1,000 engine-less RX-8 can look cheaper than a $2,500 running manual BMW.

BuildScout can account for the missing drivetrain, transport, differential, baseline service, consumables, and mission fit, then rank the *finished paths* rather than just sorting asking prices.

## Importing listings

You can paste an ad directly into BuildScout. The parser attempts to detect:

- year
- make
- price
- transmission
- drivetrain
- running / non-running status
- tow requirement
- URL
- useful build keywords
- common risk keywords

Everything remains editable before you add the candidate.

Bulk JSON and CSV imports are also supported. The flexible importer can normalize common exports from external automotive collectors rather than requiring an exact BuildScout schema. See [docs/DATA_FORMAT.md](docs/DATA_FORMAT.md).

For the current provider matrix and federation strategy, see [docs/SOURCES.md](docs/SOURCES.md).

## Data-source philosophy

BuildScout is source-agnostic.

Real providers should be integrated through:

- public APIs
- approved partner APIs
- public feeds
- user exports
- permitted browser workflows
- community-maintained datasets

The core app should not depend on bypassing access controls or violating marketplace terms.

A source adapter normalizes provider-specific data into common BuildScout records so the scoring engine does not care where a candidate came from.

## Development

Requirements:

- macOS 14+
- Swift 6+

Run:

```bash
swift run BuildScout
```

Build:

```bash
swift build
```

Package a clickable macOS app bundle:

```bash
chmod +x scripts/package_app.sh
scripts/package_app.sh 0.1.0
```

The packaged app and zip are written to `dist/`. Tagged releases can be packaged automatically by GitHub Actions.

## Roadmap

The next major systems are:

1. deeper vehicle / drivetrain / donor compatibility graphs
2. fitment-aware parts selection instead of keyword relevance alone
3. direct forum feeds / Discourse / XenForo adapters where communities permit them
4. richer auction fee, transport, import and title-cost models
5. saved searches, background refresh and notifications
6. community compatibility facts with provenance
7. regional labour-rate and specialist data
8. shareable build plans
9. optional local-LLM reasoning over structured facts
10. signed and notarized macOS releases

See [docs/ROADMAP.md](docs/ROADMAP.md).

## Contributing

PRs and data corrections are welcome.

Useful contributions include:

- a vehicle platform profile
- a compliant source adapter
- a real build-cost dataset
- a documented swap dependency
- a regional auction source
- fitment corrections

Please keep factual compatibility claims sourceable.

## Support

BuildScout is intended to remain free.

Optional Ko-fi / donation links can be configured by the maintainer later, but core planning features should not be paywalled.

## License

MIT
