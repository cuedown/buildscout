import SwiftUI

struct CandidateBrowser: View {
    @EnvironmentObject private var store: ListingStore

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                HStack {
                    TextField("Search candidates", text: $store.query)
                        .textFieldStyle(.roundedBorder)
                    Text("\(store.evaluations.count)")
                        .foregroundStyle(.secondary)
                }.padding()

                List(selection: $store.selectedListingID) {
                    ForEach(store.evaluations) { item in
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
                            }.font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 5)
                        .tag(item.listing.id)
                    }
                }
            }
            .frame(minWidth: 360)

            if let item = store.selectedEvaluation {
                BuildDetail(evaluation: item)
                    .frame(minWidth: 540)
            } else {
                ContentUnavailableView("Pick a candidate", systemImage: "car")
            }
        }
        .navigationTitle("Candidates")
    }
}

private struct BuildDetail: View {
    let evaluation: BuildEvaluation
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(evaluation.listing.title).font(.largeTitle.bold())
                        Text(evaluation.listing.location).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(evaluation.score)/100")
                        .font(.title2.bold())
                }

                HStack {
                    DetailMetric(title: "Purchase", value: evaluation.listing.price.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                    DetailMetric(title: "Projected", value: evaluation.projectedTotal.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                    DetailMetric(title: "Transmission", value: evaluation.listing.transmission.rawValue)
                    DetailMetric(title: "Drivetrain", value: evaluation.listing.drivetrain.rawValue)
                }

                Text(evaluation.listing.notes)

                SectionBlock(title: "Why it works", items: evaluation.reasons, symbol: "checkmark.circle")
                SectionBlock(title: "Watch-outs", items: evaluation.warnings, symbol: "exclamationmark.triangle")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Build path").font(.title2.bold())
                    ForEach(evaluation.parts) { part in
                        HStack {
                            Label(part.name, systemImage: part.required ? "wrench.fill" : "wrench")
                            Spacer()
                            Text(part.estimate.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                            Text(part.required ? "Required" : "Optional")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        Divider()
                    }
                }
            }.padding(28)
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
        }.frame(maxWidth: .infinity, alignment: .leading)
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
