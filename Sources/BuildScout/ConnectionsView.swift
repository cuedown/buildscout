import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject private var connections: ConnectionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 7) {
                    ScoutEyebrow(text: "Data plane")
                    Text("CONNECTIONS")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text("Keyless public datasets work out of the box. Optional provider credentials unlock broad live marketplace and parts search.")
                        .foregroundStyle(BuildScoutTheme.muted)
                }

                HStack(spacing: 14) {
                    connectionSummary(
                        title: "PUBLIC DATA",
                        value: "4",
                        detail: "vPIC + NHTSA + EPA",
                        live: true
                    )
                    connectionSummary(
                        title: "WEB HUNT",
                        value: connections.hasSerpAPI ? "ON" : "OFF",
                        detail: "SerpApi",
                        live: connections.hasSerpAPI
                    )
                    connectionSummary(
                        title: "PARTS",
                        value: connections.hasEBay ? "ON" : "OFF",
                        detail: "eBay Browse API",
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

                providerCard(
                    title: "SerpApi",
                    subtitle: "Broad web search, Google results, Google Shopping, eBay search, auction-domain discovery",
                    status: connections.hasSerpAPI ? "CONNECTED" : "OPTIONAL KEY",
                    statusColor: connections.hasSerpAPI ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("SerpApi API key", text: $connections.serpAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                        Text("Stored in macOS Keychain, never committed to Git.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)

                        Link("Create / manage SerpApi account", destination: URL(string: "https://serpapi.com/manage-api-key")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "eBay Browse API",
                    subtitle: "Native item search and vehicle-parts ecosystem using eBay's official OAuth API",
                    status: connections.hasEBay ? "CONNECTED" : "OPTIONAL CREDS",
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

                        Text("Credentials stay in macOS Keychain. BuildScout mints short-lived application OAuth tokens as needed.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)

                        Link("eBay Developers Program", destination: URL(string: "https://developer.ebay.com/")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "MarketCheck Cars API",
                    subtitle: "Direct Canadian active inventory, auctions, VIN listings, market comps and pricing history",
                    status: connections.hasMarketCheck ? "CONNECTED" : "OPTIONAL KEY",
                    statusColor: connections.hasMarketCheck ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("MarketCheck API key", text: $connections.marketCheckAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                        Text("Used directly by Hunter for Canadian active and auction inventory. Stored in macOS Keychain.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)

                        Link("MarketCheck developer documentation", destination: URL(string: "https://docs.marketcheck.com/docs")!)
                            .font(.caption.bold())
                    }
                }

                providerCard(
                    title: "CarsXE",
                    subtitle: "Optional VIN specifications, market value, vehicle history, recalls, lien and theft intelligence",
                    status: connections.hasCarsXE ? "CONNECTED" : "OPTIONAL KEY",
                    statusColor: connections.hasCarsXE ? BuildScoutTheme.success : BuildScoutTheme.warning
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("CarsXE API key", text: $connections.carsXEAPIKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .frame(height: 38)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                        Text("Only used when a candidate has a VIN. Stored in macOS Keychain.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)

                        Link("CarsXE developer documentation", destination: URL(string: "https://docs.carsxe.com/")!)
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
                        Text("BuildScout does not ship maintainer secrets.")
                            .font(.headline)
                        Text("Anything that requires a commercial provider key is bring-your-own-key. Public government data stays zero-config. Providers with no public API are reached through source directories or optional web-search providers rather than private-session scraping.")
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
