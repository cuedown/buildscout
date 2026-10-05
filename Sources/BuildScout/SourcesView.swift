import SwiftUI

struct SourcesView: View {
    @EnvironmentObject private var connections: ConnectionStore
    @State private var query = ""
    @State private var tier: ProviderTier?

    private var entries: [ProviderCatalogEntry] {
        ProviderCatalog.entries.filter { entry in
            let matchesText = query.isEmpty ||
                entry.name.localizedCaseInsensitiveContains(query) ||
                entry.category.localizedCaseInsensitiveContains(query) ||
                entry.capabilities.joined(separator: " ").localizedCaseInsensitiveContains(query)

            let matchesTier = tier == nil || entry.tier == tier
            return matchesText && matchesTier
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                summary
                controls
                catalog
                architecture
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
        }
        .background(BuildScoutTheme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            ScoutEyebrow(text: "Provider graph")
            Text("EVERY SOURCE HAS A JOB.")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(-0.7)
            Text("Public APIs, bring-your-own-key providers, auction directories, community data, and user imports all normalize into the same BuildScout pipeline.")
                .foregroundStyle(BuildScoutTheme.muted)
        }
    }

    private var summary: some View {
        HStack(spacing: 14) {
            ScoutPanel {
                ScoutMetric(
                    label: "Live / keyless",
                    value: "\(ProviderCatalog.entries.filter { $0.tier == .live }.count)",
                    detail: "works immediately"
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Optional APIs",
                    value: "\(ProviderCatalog.entries.filter { $0.tier == .optional }.count)",
                    detail: "BYO credentials"
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Directories",
                    value: "\(ProviderCatalog.entries.filter { $0.tier == .directory }.count)",
                    detail: "manual / web discovery"
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Total mapped",
                    value: "\(ProviderCatalog.entries.count)",
                    detail: "provider surfaces"
                )
            }
        }
    }

    private var controls: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(BuildScoutTheme.faint)
                TextField("Filter provider or capability", text: $query)
                    .textFieldStyle(.plain)
                    .frame(width: 260)
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(BuildScoutTheme.surface, in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

            Spacer()

            ForEach([ProviderTier.live, .optional, .directory, .planned, .degraded], id: \.self) { item in
                Button {
                    tier = tier == item ? nil : item
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(tier == item ? .black : BuildScoutTheme.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(tier == item ? BuildScoutTheme.accent : BuildScoutTheme.surface, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var catalog: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 360), spacing: 12)], spacing: 12) {
            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Text(entry.category.uppercased())
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .tracking(0.7)
                                .foregroundStyle(BuildScoutTheme.faint)
                        }

                        Spacer()

                        Text(entry.tier.rawValue)
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(0.6)
                            .foregroundStyle(tierColor(entry.tier))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tierColor(entry.tier).opacity(0.10), in: Capsule())
                    }

                    Text(entry.capabilities.joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)

                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.faint)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Text(entry.auth)
                            .font(.caption2)
                            .foregroundStyle(BuildScoutTheme.faint)

                        Spacer()

                        if let url = entry.documentationURL {
                            Link(destination: url) {
                                Label("DOCS", systemImage: "arrow.up.right")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                            }
                        }
                    }
                }
                .padding(15)
                .background(BuildScoutTheme.surface, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(BuildScoutTheme.border))
            }
        }
    }

    private var architecture: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 8) {
                ScoutEyebrow(text: "Adapter contract")
                Text("Provider → normalized record → intelligence → scoring → build graph")
                    .font(.headline)
                Text("A source-specific client owns authentication, rate limits, pagination, and terms. The rest of BuildScout only sees normalized vehicles, parts, services, guides, safety records, and prices. This is what lets the app grow without turning into one enormous scraper.")
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.muted)
            }
        }
    }

    private func tierColor(_ tier: ProviderTier) -> Color {
        switch tier {
        case .live: return BuildScoutTheme.success
        case .optional: return BuildScoutTheme.accent
        case .directory: return .blue
        case .planned: return BuildScoutTheme.muted
        case .degraded: return BuildScoutTheme.warning
        }
    }
}
