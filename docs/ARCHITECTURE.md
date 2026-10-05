# Architecture

BuildScout separates sources, normalized data, and build reasoning.

## Sources

A source adapter acquires data through a provider-approved API, public feed, user export, permitted workflow, or community dataset. Source-specific credentials and rate limits stay isolated.

## Normalization

Vehicle sources map into a common VehicleListing model. Future part sources map into PartListing, with auctions normalized into shared auction metadata.

## Vehicle knowledge

Compatibility facts should be structured and sourceable: drivetrain, engine family, transmission families, differential options, known weak points, dimensional constraints, and mission-specific characteristics.

## Build graph

A build is a dependency graph, not a shopping list. A transmission swap can imply clutch, pedals, hydraulics, driveshaft, ECU/coding, crossmember, shifter, and differential-ratio consequences.

## Scoring

Mission profiles assign weights to price, drivetrain, condition, fabrication, risk, tool requirements, and projected completion cost. The user should always be able to see why a candidate scored the way it did.

## Local-first

The macOS client is local-first. Remote services should be optional and narrowly scoped. Donation/support features must never gate core planning functionality.
