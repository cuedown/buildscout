import SwiftUI
import AppKit

struct HunterView: View {
    @EnvironmentObject private var store: ListingStore
    @EnvironmentObject private var connections: ConnectionStore

    @State private var sourceFilter = ""
    @State private var copiedQuery: String?
    @State private var liveResults: [HuntResult] = []
    @State private var isHunting = false
    @State private var huntError: String?
    @State private var resultFilter: HuntResultKind?

    private var sources: [HunterSource] {
        guard !sourceFilter.isEmpty else { return HunterDirectory.allSources }
        return HunterDirectory.allSources.filter {
            $0.name.localizedCaseInsensitiveContains(sourceFilter) ||
            $0.region.localizedCaseInsensitiveContains(sourceFilter) ||
            $0.kind.rawValue.localizedCaseInsensitiveContains(sourceFilter)
        }
    }

    private var visibleResults: [HuntResult] {
        guard let resultFilter else { return liveResults }
        return liveResults.filter { $0.kind == resultFilter }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                liveHuntPanel

                if !liveResults.isEmpty {
                    liveResultsPanel
                }

                searchKit
                sourceHeader
                sourceGrid
                workflowPanel
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
        }
        .background(BuildScoutTheme.background)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                ScoutEyebrow(text: "Market hunter")
                Text("FIND THE UGLY DEALS.")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(-0.7)
                Text("One hunt can fan out across web results, auction domains, shopping results, eBay, and the source directory.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BuildScoutTheme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(store.mission.type.rawValue.uppercased())
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(BuildScoutTheme.accent)
                Text("≤ \(money(store.mission.vehicleBudget)) vehicle")
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.muted)
            }
        }
    }

    private var liveHuntPanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        ScoutEyebrow(text: "Live multi-source hunt")
                        Text("Search the market as a build problem, not a model-name lookup.")
                            .font(.system(size: 14, weight: .bold))
                        Text(liveProviderSummary)
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)
                    }

                    Spacer()

                    Button {
                        runHunt()
                    } label: {
                        HStack(spacing: 8) {
                            if isHunting {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "dot.radiowaves.left.and.right")
                            }
                            Text(isHunting ? "HUNTING…" : "RUN LIVE HUNT")
                        }
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isHunting || (!connections.hasSerpAPI && !connections.hasEBay))
                }

                HStack(spacing: 10) {
                    providerPill("SERPAPI", on: connections.hasSerpAPI)
                    providerPill("EBAY API", on: connections.hasEBay)
                    providerPill("AUCTION DOMAINS", on: connections.hasSerpAPI)
                    providerPill("SHOPPING", on: connections.hasSerpAPI)

                    Spacer()

                    Text(connections.preferredRegion)
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                if !connections.hasSerpAPI && !connections.hasEBay {
                    Label(
                        "Add SerpApi or eBay credentials under Connections to enable live hunting. Keyless vehicle/safety APIs still work in Vehicle Intel.",
                        systemImage: "key.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.warning)
                }

                if let huntError {
                    Label(huntError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.warning)
                }
            }
        }
    }

    private var liveResultsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    ScoutEyebrow(text: "Live results")
                    Text("\(liveResults.count) LEADS")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                }

                Spacer()

                HStack(spacing: 6) {
                    resultFilterButton("ALL", kind: nil)
                    resultFilterButton("VEHICLES", kind: .vehicle)
                    resultFilterButton("AUCTIONS", kind: .auction)
                    resultFilterButton("PARTS", kind: .part)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 360), spacing: 12)], spacing: 12) {
                ForEach(visibleResults) { result in
                    liveResultCard(result)
                }
            }
        }
    }

    private var searchKit: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScoutEyebrow(text: "Search phrases")
                    Spacer()
                    Text("Click to copy")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 215), spacing: 10)], spacing: 10) {
                    ForEach(HunterDirectory.queries(for: store.mission.type), id: \.self) { query in
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(query, forType: .string)
                            copiedQuery = query
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: copiedQuery == query ? "checkmark.circle.fill" : "magnifyingglass")
                                    .foregroundStyle(copiedQuery == query ? BuildScoutTheme.success : BuildScoutTheme.accent)
                                Text(query)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(BuildScoutTheme.faint)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 42)
                            .background(BuildScoutTheme.raised, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(BuildScoutTheme.border))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var sourceHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                ScoutEyebrow(text: "Source directory")
                Text("PROVIDERS WITHOUT A DIRECT FEED")
                    .font(.system(size: 20, weight: .black, design: .rounded))
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(BuildScoutTheme.faint)
                TextField("Filter sources", text: $sourceFilter)
                    .textFieldStyle(.plain)
                    .frame(width: 220)
            }
            .padding(.horizontal, 11)
            .frame(height: 36)
            .background(BuildScoutTheme.surface, in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))
        }
    }

    private var sourceGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 14)], spacing: 14) {
            ForEach(sources) { source in
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text(source.region)
                                .font(.caption)
                                .foregroundStyle(BuildScoutTheme.muted)
                        }
                        Spacer()
                        Text(source.kind.rawValue.uppercased())
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(0.7)
                            .foregroundStyle(BuildScoutTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(BuildScoutTheme.accent.opacity(0.10), in: Capsule())
                    }

                    Text(source.notes)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BuildScoutTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Text(source.strengths.joined(separator: " • "))
                            .font(.caption2)
                            .foregroundStyle(BuildScoutTheme.faint)
                            .lineLimit(1)
                        Spacer()
                        Link(destination: source.url) {
                            HStack(spacing: 5) {
                                Text("OPEN")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.6)
                        }
                    }
                }
                .padding(16)
                .background(BuildScoutTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(BuildScoutTheme.border))
            }
        }
    }

    private var workflowPanel: some View {
        ScoutPanel {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(BuildScoutTheme.accent.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: "arrow.triangle.branch")
                        .font(.title2)
                        .foregroundStyle(BuildScoutTheme.accent)
                }
                VStack(alignment: .leading, spacing: 5) {
                    ScoutEyebrow(text: "A → B loop")
                    Text("Hunt → inspect → candidate → parts → build path → project ledger")
                        .font(.system(size: 13, weight: .bold))
                    Text("Live leads can be promoted into Candidates immediately. Candidate selection then feeds parts searches and build planning.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }
                Spacer()
            }
        }
    }

    private var liveProviderSummary: String {
        var active: [String] = []
        if connections.hasMarketCheck { active.append("MarketCheck dealer + private inventory") }
        if connections.hasSerpAPI { active.append("web indexes + forums + Shopping via SerpApi") }
        if connections.hasApify { active.append("opt-in marketplace / salvage actors") }
        if connections.hasEBay { active.append("native eBay Browse") }
        return active.isEmpty ? "No keyed live-search provider connected yet." : active.joined(separator: " + ")
    }

    private func runHunt() {
        isHunting = true
        huntError = nil

        let request = HuntRequest(
            mission: store.mission.type,
            keywords: HuntEngine.queries(
                for: store.mission.type,
                budget: store.mission.vehicleBudget,
                location: connections.preferredRegion
            ),
            location: connections.preferredRegion,
            maxVehiclePrice: store.mission.vehicleBudget,
            preferredVehicle: store.selectedEvaluation?.listing ?? store.evaluations.first?.listing
        )

        Task {
            let results = await HuntEngine.run(request: request, connections: connections)
            await MainActor.run {
                liveResults = results
                isHunting = false
                if results.isEmpty {
                    huntError = "The connected providers returned no results for this hunt."
                }
            }
        }
    }

    private func providerPill(_ title: String, on: Bool) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(on ? BuildScoutTheme.success : BuildScoutTheme.faint)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.5)
        }
        .foregroundStyle(on ? .white : BuildScoutTheme.faint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.05), in: Capsule())
    }

    private func resultFilterButton(_ title: String, kind: HuntResultKind?) -> some View {
        let selected = resultFilter == kind
        return Button {
            resultFilter = kind
        } label: {
            Text(title)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(selected ? .black : BuildScoutTheme.muted)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(selected ? BuildScoutTheme.accent : BuildScoutTheme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func liveResultCard(_ result: HuntResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.provider.uppercased())
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(BuildScoutTheme.accent)

                    Text(result.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .lineLimit(2)
                }

                Spacer()

                Text(result.kind.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(BuildScoutTheme.faint)
            }

            if let price = result.price {
                HStack(spacing: 8) {
                    Text(price.formatted(.currency(code: result.currency ?? "CAD").precision(.fractionLength(0))))
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(BuildScoutTheme.success)

                    if let previous = result.previousPrice, previous > price {
                        Text("↓ \((previous - price).formatted(.currency(code: result.currency ?? "CAD").precision(.fractionLength(0))))")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(BuildScoutTheme.success)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(BuildScoutTheme.success.opacity(0.1), in: Capsule())
                    }

                    if let seen = result.seenCount, seen > 1 {
                        Text("SEEN \(seen)×")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(BuildScoutTheme.faint)
                    }
                }
            }

            if !result.snippet.isEmpty {
                Text(result.snippet)
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.muted)
                    .lineLimit(3)
            }

            HStack {
                if let location = result.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                Spacer()

                if result.kind == .vehicle || result.kind == .auction {
                    Button {
                        promote(result)
                    } label: {
                        Label("CANDIDATE", systemImage: "plus.circle")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                    }
                    .buttonStyle(.plain)
                }

                if let url = URL(string: result.url), !result.url.isEmpty {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square")
                    }
                }
            }
        }
        .padding(15)
        .background(BuildScoutTheme.surface, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(BuildScoutTheme.border))
    }

    private func promote(_ result: HuntResult) {
        store.addListing(
            HuntNormalization.vehicleListing(
                from: result,
                defaultLocation: connections.preferredRegion
            )
        )
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
    }
}
