# BuildScout $0 API Stack

BuildScout's provider strategy is **maximum legitimate coverage at $0 out-of-pocket**, not "avoid API keys."

## Always-on, no account / no key

| Provider | Cost | Practical use |
|---|---:|---|
| AutoTrader Canada public search adapter | $0 | Baseline Canadian live inventory |
| NHTSA vPIC | $0 | VIN decode, identity, configuration/spec data |
| NHTSA recalls / complaints / ratings | $0 | U.S. safety and reliability signals |
| FuelEconomy.gov | $0 | Engine, transmission, drivetrain, EPA configuration matching |
| Transport Canada open recall data | $0 | Canadian recall coverage; use API when healthy and CSV/JSON feeds as fallback |
| Bank of Canada Valet API | $0 | Official CAD FX normalization |
| GitHub REST API, unauthenticated | $0 | Public project repositories and technical datasets, low-rate fallback |

## Free account / free credential stack

| Provider | Current $0 allowance | Payment method | BuildScout use |
|---|---:|---|---|
| SerpApi | 250 searches / month | Free plan | Google-index discovery, Shopping, Maps, forum fallback |
| Tavily | 1,000 API credits / month | No card required | Web discovery, forums, listing and parts fallback |
| Exa | $10 credits / month + onboarding bonus | No payment method required | Semantic discovery and technical research |
| Brave Search API | $5 credits / month, about 1,000 Search requests at current rate | Card verification; prepay can be $0 | Independent web index |
| MarketCheck | 500 calls / month, 100-mile radius | $0 tier; explicit subscription | Direct active inventory and comps |
| eBay Developers / Browse API | 5,000 calls / day default | Free developer membership | Native used/new parts search and compatibility |
| Apify | $5 platform / Store credit per month | No card required | Optional Facebook, Kijiji, Craigslist, Copart and IAA actors |
| CarsXE Sandbox | Up to 100 API calls lifetime across sandbox | $0 sandbox | Supplemental VIN/spec/history/market-value checks |
| YouTube Data API | Default search quota currently 100 search.list calls / day | Google Cloud project | Direct build-guide and repair-video research |
| GitHub REST API, authenticated | 5,000 normal REST requests / hour | Free account/token | Higher-rate public repo/data search |

## Quota policy

BuildScout should never spend all free quotas on duplicate queries.

1. Direct inventory APIs and built-in inventory adapters first.
2. Split broad web queries across Tavily, Exa, Brave and SerpApi instead of sending every query to every provider.
3. Preserve SerpApi for unique Google surfaces such as Shopping and Maps.
4. Prefer direct eBay Browse over SerpApi eBay.
5. Prefer direct YouTube Data over SerpApi YouTube.
6. Use generic web search for parts only when native parts sources return too few options.
7. Cache Bank of Canada FX because the published daily rate does not need repeated calls.
8. Dedupe by VIN, then canonical URL, then fingerprint before ranking.

## Providers without a clean free first-party inventory API

Facebook Marketplace, Kijiji, Copart and IAA should not be treated as if public browsing equals API authorization.

BuildScout reaches these through:
- explicit user Browser Capture,
- optional third-party Apify actors within the user's own free credit,
- indexed discovery,
- future approved partner feeds.

No account-cookie export, hidden-session scraping, or access-control bypass belongs in the core app.
