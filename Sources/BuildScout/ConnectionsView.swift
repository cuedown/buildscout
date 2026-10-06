import SwiftUI
import AppKit

struct ConnectionsView: View {
    @EnvironmentObject private var connections: ConnectionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 7) {
                    ScoutEyebrow(text: "Data plane")
                    Text("CONNECTIONS")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text("Zero-dollar first, maximum-provider by design. Add every useful free API tier so BuildScout can rotate across independent inventory, search, parts, research, safety, valuation and marketplace sources instead of depending on one pipe.")
                        .foregroundStyle(BuildScoutTheme.muted)
                }

                HStack(spacing: 14) {
                    connectionSummary(
                        title: "PUBLIC DATA",
                        value: "6+",
                        detail: "vPIC + NHTSA + EPA + TC + FX",
                        live: true
                    )
                    connectionSummary(
                        title: "WEB INDEXES",
                        value: "\(connections.connectedFreeSearchProviderCount)/4",
                        detail: "Serp + Tavily + Exa + Brave",
                        live: connections.connectedFreeSearchProviderCount > 0
                    )
                    connectionSummary(
                        title: "PARTS",
                        value: connections.hasEBay ? "ON" : "ADD",
                        detail: "eBay • 5K calls/day free",
                        live: connections.hasEBay
                    )
                }

                providerCard(
                    title: "NHTSA / vPIC",
                    subtitle: "VIN identity, Canadian specifications, recalls, complaints, safety-rating variants",
                    status: "LIVE",
                    statusColor: BuildScoutTheme.success
                ) {
                    Text("No key required. BuildScout calls the public U.S. Department of Transportation APIs directly.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }

                ScoutPanel {
                    VStack(alignment: .leading, spacing: 7) {
                        ScoutEyebrow(text: "Free API arsenal")
                        Text("CONNECT EVERYTHING THAT COSTS $0")
                            .font(.headline)
                        Text("BuildScout now fans discovery across multiple free search indexes and saves the tiny quotas for the jobs each provider is best at. Keys stay in macOS Keychain and are never committed to Git.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)

                        Button {
                            openFreeSignupPages()
                        } label: {
                            Label("OPEN ALL FREE API SIGNUPS", systemImage: "safari.fill")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(0.5)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                providerCard(
                    title: "Tavily Search API",
                    subtitle: "Independent live web discovery for listings, forums, parts fallbacks and build research",
                    status: connections.hasTavily ? "CONNECTED" : "FREE 1K CREDITS/MO",
                    statusColor: connections.hasTavily ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("Tavily API key", text: $connections.tavilyAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))
                        Text("$0 Researcher tier: 1,000 API credits each month, no credit card required.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)
                        Link("Get free Tavily key", destination: URL(string: "https://app.tavily.com/")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "Exa Search API",
                    subtitle: "Semantic web search with extracted highlights for obscure builds, classifieds and technical research",
                    status: connections.hasExa ? "CONNECTED" : "FREE $10/MO",
                    statusColor: connections.hasExa ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("Exa API key", text: $connections.exaAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))
                        Text("$0 Starter tier includes $10 of credits every month plus an onboarding bonus; no payment method required.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)
                        Link("Get free Exa key", destination: URL(string: "https://dashboard.exa.ai/")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "Brave Search API",
                    subtitle: "Independent web index and fallback search layer for public listings and research",
                    status: connections.hasBrave ? "CONNECTED" : "$5 FREE/MO",
                    statusColor: connections.hasBrave ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("Brave Search API key", text: $connections.braveAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))
                        Text("Search costs $5/1,000 requests and Brave applies $5 in free credit monthly. A card is required for verification, but prepay can be set to $0.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)
                        Link("Create Brave Search API key", destination: URL(string: "https://api.search.brave.com/app/keys")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "YouTube Data API",
                    subtitle: "Direct build-guide, repair, swap and motorsport video search without spending SerpApi quota",
                    status: connections.hasYouTube ? "CONNECTED" : "FREE QUOTA",
                    statusColor: connections.hasYouTube ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("YouTube Data API key", text: $connections.youtubeAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))
                        Text("Google gives enabled projects a default free quota. BuildScout uses search.list only for targeted build research.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)
                        Link("Google Cloud API Console", destination: URL(string: "https://console.cloud.google.com/apis/library/youtube.googleapis.com")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "GitHub REST API",
                    subtitle: "Open-source build tools, swap documentation, datasets and project repositories",
                    status: connections.hasGitHub ? "CONNECTED 5K/HR" : "LIVE 60/HR",
                    statusColor: connections.hasGitHub ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("GitHub personal access token", text: $connections.githubToken)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))
                        Text("Public API works without a token at 60 requests/hour; a free token raises the normal authenticated limit to 5,000/hour. No repository permissions are needed for public search.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)
                        Link("Create GitHub token", destination: URL(string: "https://github.com/settings/personal-access-tokens/new")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "SerpApi",
                    subtitle: "Broad web search, Google results, Google Shopping, eBay search, auction-domain discovery",
                    status: connections.hasSerpAPI ? "CONNECTED" : "FREE 250/MO",
                    statusColor: connections.hasSerpAPI ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("SerpApi API key", text: $connections.serpAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                        Text("Free plan currently includes 250 searches/month. Stored in macOS Keychain, never committed to Git.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)

                        Link("Get free SerpApi key", destination: URL(string: "https://serpapi.com/manage-api-key")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "eBay Browse API",
                    subtitle: "Native item search and vehicle-parts ecosystem using eBay's official OAuth API",
                    status: connections.hasEBay ? "CONNECTED" : "FREE 5K/DAY",
                    statusColor: connections.hasEBay ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("eBay Client ID", text: $connections.eBayClientID)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                        SecureField("eBay Client Secret", text: $connections.eBayClientSecret)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                        Text("eBay Developer membership is free and the Browse API default tier allows 5,000 calls/day. Credentials stay in macOS Keychain; BuildScout mints short-lived application OAuth tokens as needed.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)

                        Link("Join eBay Developers free", destination: URL(string: "https://developer.ebay.com/join/")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "MarketCheck Cars API",
                    subtitle: "Direct Canadian active inventory, auctions, VIN listings, market comps and pricing history",
                    status: connections.hasMarketCheck ? "CONNECTED" : "FREE 500/MO",
                    statusColor: connections.hasMarketCheck ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("MarketCheck API key", text: $connections.marketCheckAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                        Text("MarketCheck currently offers a $0 tier with 500 calls/month and a 100-mile radius restriction. Used directly by Hunter for Canadian active inventory and comps. Stored in macOS Keychain.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)

                        Link("Subscribe to MarketCheck free tier", destination: URL(string: "https://www.marketcheck.com/apis/pricing/")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "CarsXE",
                    subtitle: "Optional VIN specifications, market value, vehicle history, recalls, lien and theft intelligence",
                    status: connections.hasCarsXE ? "CONNECTED" : "FREE SANDBOX",
                    statusColor: connections.hasCarsXE ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("CarsXE API key", text: $connections.carsXEAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                        Text("CarsXE Sandbox is $0 with up to 100 API calls lifetime across its sandbox endpoints. Only used when a candidate has a VIN. Stored in macOS Keychain.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)

                        Link("Create CarsXE Sandbox account", destination: URL(string: "https://carsxe.com/pricing")!)
                            .font(.caption.bold())
                    }
                }

                BrowserCaptureConnectionCard()

                ApifyConnectionCard()

                ScoutPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        ScoutEyebrow(text: "Search geography")
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("REGION").font(.caption2.bold()).foregroundStyle(BuildScoutTheme.faint)
                                TextField("Calgary, Alberta", text: $connections.preferredRegion)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .frame(height: 36)
                                    .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 8))
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text("COUNTRY").font(.caption2.bold()).foregroundStyle(BuildScoutTheme.faint)
                                TextField("Canada", text: $connections.preferredCountry)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .frame(height: 36)
                                    .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }

                ScoutPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        ScoutEyebrow(text: "Design rule")
                        Text("$0 is the budget ceiling, not the provider ceiling.")
                            .font(.headline)
                        Text("Use every legitimate free tier available, cache aggressively, rotate independent indexes, and fall back to keyless public data. BuildScout never needs a maintainer-owned secret and never bypasses marketplace access controls.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
        }
        .background(BuildScoutTheme.background)
    }

    @ViewBuilder
    private func providerCard<Content: View>(
        title: String,
        subtitle: String,
        status: String,
        statusColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)
                    }
                    Spacer()
                    Text(status)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1), in: Capsule())
                }
                content()
            }
        }
    }

    private func openFreeSignupPages() {
        let urls = [
            "https://serpapi.com/manage-api-key",
            "https://app.tavily.com/",
            "https://dashboard.exa.ai/",
            "https://api.search.brave.com/app/keys",
            "https://developer.ebay.com/join/",
            "https://www.marketcheck.com/apis/pricing/",
            "https://carsxe.com/pricing",
            "https://console.apify.com/account/integrations",
            "https://console.cloud.google.com/apis/library/youtube.googleapis.com",
            "https://github.com/settings/personal-access-tokens/new"
        ]

        for raw in urls {
            if let url = URL(string: raw) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func connectionSummary(title: String, value: String, detail: String, live: Bool) -> some View {
        ScoutPanel {
            HStack {
                ScoutMetric(label: title, value: value, detail: detail)
                Circle()
                    .fill(live ? BuildScoutTheme.success : BuildScoutTheme.warning)
                    .frame(width: 9, height: 9)
            }
        }
    }
}
