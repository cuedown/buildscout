# BuildScout data partnerships

BuildScout's goal is to become a complete project-vehicle discovery and build-planning layer while keeping the source relationship clean.

For closed marketplaces, the preferred long-term path is a read-only partnership rather than pretending an undocumented public API exists.

## What BuildScout asks for

- read-only search/listing access
- public vehicle and parts inventory only
- VIN/specification fields when the source already exposes them
- price, location, mileage, seller type and listing URL
- change/deletion signals where available
- reasonable rate limits and caching rules
- clear attribution and click-through requirements

BuildScout does not need:

- private messages
- seller account credentials
- private profile data
- payment data
- automated negotiation/messages
- cookie/session export
- write access to marketplace inventory

## What the source gets

- attribution on every result
- click-through to the original listing
- no resale of raw provider data
- deletion/expiry handling
- configurable caching/retention
- transparent open-source adapter code when the provider allows it
- a project-car audience that would otherwise search many fragmented sources manually

## Integration priorities

1. Kijiji / Kijiji Autos
2. Facebook Marketplace / Meta
3. AutoTrader Canada
4. Craigslist
5. Copart / IAA
6. Alberta and western-Canada auction houses
7. enthusiast forums with classified sections
8. salvage yards / dismantlers / recyclers

## Outreach template

Subject: Read-only automotive inventory integration for free open-source BuildScout

Hello,

I maintain BuildScout, a free open-source project-vehicle discovery and build-planning application.

BuildScout helps users answer a different question from a normal vehicle marketplace: instead of only searching for a particular model, a user can ask for a goal such as “build a drift car under $5,000” or “build an overland ski vehicle,” and BuildScout combines candidate vehicles, required parts, known platform issues, tools, labour and total project cost.

We would like to integrate your public automotive inventory using an approved read-only method.

We are requesting only public listing/search fields needed to identify and link a vehicle or part: title, price, location, mileage, vehicle specifications, listing URL, seller type and listing status where available. We do not need private messages, login credentials, payment information, automated messaging or write access.

We are happy to comply with rate limits, cache/retention rules, attribution requirements, click-through requirements and branding guidance. Every result can link directly back to the original listing.

The project is public and open source:
https://github.com/cuedown/buildscout

If you offer a partner API, inventory feed, affiliate/search endpoint or another approved integration path, we would appreciate being pointed to the right team.

Thank you,
BuildScout
