import SwiftUI
import AppKit

struct HunterView: View {
    @EnvironmentObject private var store: ListingStore
    @State private var sourceFilter = ""
    @State private var copiedQuery: String?

    private var sources: [HunterSource] {
        guard !sourceFilter.isEmpty else { return HunterDirectory.sources }
        return HunterDirectory.sources.filter {
            $0.name.localizedCaseInsensitiveContains(sourceFilter) ||
            $0.region.localizedCaseInsensitiveContains(sourceFilter) ||
            $0.kind.rawValue.localizedCaseInsensitiveContains(sourceFilter)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hunter").font(.largeTitle.bold())
                    Text("Search situations, not dream cars. Use ugly/problem keywords to reach candidates before enthusiast tax arrives.")
                        .foregroundStyle(.secondary)
                }

                GroupBox("Mission search kit") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(store.mission.type.rawValue, systemImage: store.mission.type.symbol)
                                .font(.headline)
                            Spacer()
                            Text("Vehicle budget \(store.mission.vehicleBudget.formatted(.currency(code: "CAD").precision(.fractionLength(0))))")
                                .foregroundStyle(.secondary)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                            ForEach(HunterDirectory.queries(for: store.mission.type), id: \.self) { query in
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(query, forType: .string)
                                    copiedQuery = query
                                } label: {
                                    HStack {
                                        Text(query)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: copiedQuery == query ? "checkmark" : "doc.on.doc")
                                    }
                                    .padding(10)
                                }
                                .buttonStyle(.plain)
                                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(8)
                }

                HStack {
                    Text("Sources").font(.title2.bold())
                    Spacer()
                    TextField("Filter sources", text: $sourceFilter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 260)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 14)], spacing: 14) {
                    ForEach(sources) { source in
                        SourceCard(source: source)
                    }
                }

                GroupBox("Current ingestion loop") {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("1. Open a source.  2. Copy a promising listing.  3. Paste it into Import.  4. BuildScout normalizes and scores it.")
                        Text("Future adapters will automate sources that provide an approved API/feed. Private-session credentials are intentionally not embedded in the project.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                }
            }
            .padding(28)
        }
    }
}

private struct SourceCard: View {
    let source: HunterSource

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(source.name).font(.headline)
                    Text(source.region).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(source.kind.rawValue.capitalized)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            Text(source.notes)
                .font(.subheadline)

            Text(source.strengths.joined(separator: " • "))
                .font(.caption)
                .foregroundStyle(.secondary)

            Link(destination: source.url) {
                Label("Open source", systemImage: "arrow.up.right.square")
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }
}
