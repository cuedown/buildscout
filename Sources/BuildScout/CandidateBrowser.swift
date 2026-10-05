import SwiftUI

struct CandidateBrowser: View {
    @EnvironmentObject private var store: ListingStore

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                HStack {
                    TextField("Search candidates", text: $store.query)
                        .textFieldStyle(.roundedBorder)

                    Toggle(isOn: $store.favoritesOnly) {
                        Image(systemName: "star.fill")
                    }
                    .toggleStyle(.button)
                    .help("Show favorites only")

                    Text("\(store.evaluations.count)")
                        .foregroundStyle(.secondary)
                }
                .padding()

                List(selection: $store.selectedListingID) {
                    ForEach(store.evaluations) { item in
                        HStack(spacing: 10) {
                            Button {
                                store.toggleFavorite(item.listing)
                            } label: {
                                Image(systemName: store.favoriteIDs.contains(item.listing.id) ? "star.fill" : "star")
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(item.listing.title).font(.headline)
                                    Spacer()
                                    Text("\(item.score)").bold()
                                }
                                HStack {
                                    Text(item.listing.price.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                                    Text("•")
                                    Text(item.listing.drivetrain.rawValue)
                                    Text("•")
                                    Text(item.listing.transmission.rawValue)
                                    if item.listing.source != "Demo" {
                                        Text("•")
                                        Text(item.listing.source)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 5)
                        .tag(item.listing.id)
                    }
                }
            }
            .frame(minWidth: 390)

            if let item = store.selectedEvaluation {
                BuildDetail(evaluation: item)
                    .frame(minWidth: 560)
            } else {
                ContentUnavailableView("Pick a candidate", systemImage: "car")
            }
        }
        .navigationTitle("Candidates")
    }
}

private struct BuildDetail: View {
    @EnvironmentObject private var store: ListingStore
    let evaluation: BuildEvaluation

    private var graph: BuildGraph {
        BuildGraphBuilder.make(for: evaluation)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(evaluation.listing.title).font(.largeTitle.bold())
                        Text(evaluation.listing.location.isEmpty ? evaluation.listing.source : evaluation.listing.location)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(evaluation.score)/100")
                            .font(.title2.bold())
                        Button {
                            store.toggleFavorite(evaluation.listing)
                        } label: {
                            Label(
                                store.favoriteIDs.contains(evaluation.listing.id) ? "Saved" : "Save",
                                systemImage: store.favoriteIDs.contains(evaluation.listing.id) ? "star.fill" : "star"
                            )
                        }
                    }
                }

                HStack {
                    DetailMetric(title: "Purchase", value: evaluation.listing.price.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                    DetailMetric(title: "Projected", value: evaluation.projectedTotal.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                    DetailMetric(title: "Transmission", value: evaluation.listing.transmission.rawValue)
                    DetailMetric(title: "Drivetrain", value: evaluation.listing.drivetrain.rawValue)
                }

                if let profile = PlatformKnowledge.match(evaluation.listing) {
                    GroupBox("Platform intelligence") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(profile.id).font(.headline)
                            Text("Parts availability: \(profile.partsAvailability)/10 • Fabrication friendliness: \(profile.fabricationFriendliness)/10")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(profile.driftNotes, id: \.self) { note in
                                Label(note, systemImage: "sparkles")
                            }
                        }
                        .padding(8)
                    }
                }

                if !evaluation.listing.notes.isEmpty {
                    Text(evaluation.listing.notes)
                }

                SectionBlock(title: "Why it works", items: evaluation.reasons, symbol: "checkmark.circle")
                SectionBlock(title: "Watch-outs", items: evaluation.warnings, symbol: "exclamationmark.triangle")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Build path").font(.title2.bold())

                    ForEach(Array(graph.nodes.enumerated()), id: \.element.id) { index, node in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .frame(width: 24, height: 24)
                                .background(.quaternary, in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(node.title).font(.headline)
                                if !node.dependsOnTitles.isEmpty {
                                    Text("After: \(node.dependsOnTitles.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text(node.estimate.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                            Text(node.required ? "Required" : "Optional")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        Divider()
                    }
                }

                HStack {
                    if let urlText = evaluation.listing.url, let url = URL(string: urlText) {
                        Link("Open original listing", destination: url)
                    }
                    Spacer()
                    Button("Delete candidate", role: .destructive) {
                        store.remove(evaluation.listing)
                    }
                }
            }
            .padding(28)
        }
    }
}

private struct DetailMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SectionBlock: View {
    let title: String
    let items: [String]
    let symbol: String

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.title2.bold())
                ForEach(items, id: \.self) { item in
                    Label(item, systemImage: symbol)
                }
            }
        }
    }
}
