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
                header
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
                Text("Search for situations, failures, estates, and half-finished projects before enthusiast tax arrives.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BuildScoutTheme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(store.mission.type.rawValue.uppercased())
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(BuildScoutTheme.accent)
                Text("≤ (money(store.mission.vehicleBudget)) vehicle")
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.muted)
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
                Text("WHERE TO LOOK")
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
                    ScoutEyebrow(text: "Current ingestion loop")
                    Text("Open source → copy listing → Import → score → start build")
                        .font(.system(size: 13, weight: .bold))
                    Text("Approved feeds and APIs can automate this later without baking private credentials or brittle scraping into the app.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }
                Spacer()
            }
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
    }
}
