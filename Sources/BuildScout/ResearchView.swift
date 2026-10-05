import SwiftUI

struct ResearchView: View {
    @EnvironmentObject private var store: ListingStore
    @EnvironmentObject private var connections: ConnectionStore

    @State private var selectedCandidateID: UUID?
    @State private var pack: BuildResearchPack?
    @State private var isLoading = false

    private var listing: VehicleListing? {
        guard let selectedCandidateID else { return store.listings.first }
        return store.listings.first(where: { $0.id == selectedCandidateID })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                controls

                if let pack {
                    resultSummary(pack)
                    guideSection(pack.guides)
                    forumSection(pack.forumThreads)
                    serviceSection(pack.services)
                } else {
                    empty
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
        }
        .background(BuildScoutTheme.background)
        .task {
            if selectedCandidateID == nil {
                selectedCandidateID = store.selectedEvaluation?.listing.id ?? store.listings.first?.id
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            ScoutEyebrow(text: "Build research")
            Text("KNOWLEDGE + PEOPLE + SHOPS.")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(-0.7)
            Text("Pull build videos, forum threads, fabrication help, alignment shops, salvage yards, machine shops, and towing around the candidate.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BuildScoutTheme.muted)
        }
    }

    private var controls: some View {
        ScoutPanel {
            HStack(spacing: 12) {
                Picker("Candidate", selection: Binding(
                    get: { selectedCandidateID ?? store.listings.first?.id },
                    set: {
                        selectedCandidateID = $0
                        pack = nil
                    }
                )) {
                    ForEach(store.listings) { listing in
                        Text(listing.title).tag(Optional(listing.id))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)

                Text(connections.preferredRegion)
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.faint)

                Button {
                    run()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "books.vertical.fill")
                        }
                        Text(isLoading ? "RESEARCHING…" : "RUN RESEARCH")
                    }
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.5)
                }
                .buttonStyle(.borderedProminent)
                .disabled(listing == nil || !connections.hasSerpAPI || isLoading)
            }
        }
    }

    private func resultSummary(_ pack: BuildResearchPack) -> some View {
        HStack(spacing: 14) {
            ScoutPanel {
                ScoutMetric(label: "Guides", value: "\(pack.guides.count)", detail: "YouTube build / repair")
            }
            ScoutPanel {
                ScoutMetric(label: "Threads", value: "\(pack.forumThreads.count)", detail: "forum + web research")
            }
            ScoutPanel {
                ScoutMetric(label: "Services", value: "\(pack.services.count)", detail: "local specialists")
            }
        }
    }

    private func guideSection(_ guides: [HuntResult]) -> some View {
        resultSection(
            eyebrow: "Learn it",
            title: "VIDEO GUIDES",
            icon: "play.rectangle.fill",
            items: Array(guides.prefix(12))
        )
    }

    private func forumSection(_ threads: [HuntResult]) -> some View {
        resultSection(
            eyebrow: "Read it",
            title: "BUILD THREADS / FORUMS",
            icon: "text.bubble.fill",
            items: Array(threads.prefix(12))
        )
    }

    private func serviceSection(_ services: [HuntResult]) -> some View {
        resultSection(
            eyebrow: "Get help",
            title: "LOCAL SERVICES",
            icon: "mappin.and.ellipse",
            items: Array(services.prefix(20))
        )
    }

    private func resultSection(
        eyebrow: String,
        title: String,
        icon: String,
        items: [HuntResult]
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    ScoutEyebrow(text: eyebrow)
                    Text(title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                }
                Spacer()
                Image(systemName: icon)
                    .foregroundStyle(BuildScoutTheme.accent)
            }

            if items.isEmpty {
                ScoutPanel {
                    Text("No results returned.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12)], spacing: 12) {
                    ForEach(items) { item in
                        researchCard(item)
                    }
                }
            }
        }
    }

    private func researchCard(_ item: HuntResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(item.provider.uppercased())
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(BuildScoutTheme.accent)
                Spacer()
                Text(item.kind.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(BuildScoutTheme.faint)
            }

            Text(item.title)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(2)

            if let location = item.location, !location.isEmpty {
                Label(location, systemImage: "mappin.circle")
                    .font(.caption2)
                    .foregroundStyle(BuildScoutTheme.faint)
            }

            if !item.snippet.isEmpty {
                Text(item.snippet)
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.muted)
                    .lineLimit(3)
            }

            Spacer()

            if let url = URL(string: item.url), !item.url.isEmpty {
                Link(destination: url) {
                    Label("OPEN", systemImage: "arrow.up.right")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                }
            }
        }
        .padding(14)
        .frame(minHeight: 150, alignment: .topLeading)
        .background(BuildScoutTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BuildScoutTheme.border))
    }

    private var empty: some View {
        ScoutPanel {
            HStack(spacing: 16) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(BuildScoutTheme.accent)
                VStack(alignment: .leading, spacing: 5) {
                    Text("No research pack yet.")
                        .font(.headline)
                    Text(connections.hasSerpAPI
                         ? "Choose a candidate and run research."
                         : "Connect SerpApi first. It powers broad web, YouTube, and local-service discovery.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }
                Spacer()
            }
        }
    }

    private func run() {
        guard let listing else { return }
        isLoading = true
        Task {
            let result = await BuildResearchEngine.run(
                listing: listing,
                mission: store.mission,
                connections: connections
            )
            await MainActor.run {
                pack = result
                isLoading = false
            }
        }
    }
}
