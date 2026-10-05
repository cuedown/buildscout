# BuildScout

**Don't search for a car. Tell it what you want to build.**

BuildScout is a free, open-source macOS project-planning and vehicle-hunting app. Choose a mission such as drift, overland, camper, rally, track, or winter. BuildScout scores candidate vehicles against your actual all-in budget, then exposes the parts, work, risk, and hidden costs between a cheap listing and a finished build.

## Why this exists

A $1,000 shell can be more expensive than a $3,000 running car once you price the drivetrain, fabrication, wiring, cooling, consumables and transport. Existing marketplaces show listings. BuildScout is intended to show **build paths**.

## Current MVP

- Native SwiftUI macOS interface
- Mission profiles
- Vehicle budget + all-in build budget
- Running/non-running and towable-project tolerances
- Mission-aware candidate scoring
- Estimated build-path BOM
- Risk and compatibility warnings
- Source-adapter architecture
- Demo candidate dataset
- Unit test for drift-path scoring

## Roadmap

1. JSON/CSV importer and local persistence
2. Real provider adapters for public/approved APIs and feeds
3. Parts and donor listing normalization
4. Build graph / dependency engine
5. Garage inventory and labour-cost model
6. Watchlists and price-change alerts
7. Community compatibility database
8. Overland/camper/rally mission packs
9. Optional local LLM reasoning layer
10. Signed distributable macOS app

## Source policy

BuildScout should not depend on bypassing access controls or violating marketplace terms. Integrations should use provider-approved APIs, public feeds, user-provided exports, permitted browser workflows, or community-maintained datasets.

## Development

Requirements:

- macOS 14+
- Swift 6+

Run:

```bash
swift run BuildScout
```

Test:

```bash
swift test
```

## Contributing

Issues and pull requests are welcome. Good first contributions include:
- a new vehicle platform profile
- a compliant listing-source adapter
- real build-cost data
- compatibility corrections
- mission-specific scoring rules

## Support

BuildScout is intended to remain free. A Ko-fi link and optional donation addresses can be added later by the maintainer. Contributions are never required to use the app.

## License

MIT.
