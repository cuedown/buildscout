import SwiftUI

struct MissionView: View {
    @EnvironmentObject private var store: ListingStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What are we building?").font(.largeTitle.bold())
                    Text("Choose the mission. BuildScout re-scores the same market around what you actually want to do.")
                        .foregroundStyle(.secondary)
                }

                MissionPicker(mission: $store.mission.type)

                GroupBox("Budget & tolerance") {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            MoneyField(title: "Vehicle", value: $store.mission.vehicleBudget)
                            MoneyField(title: "All-in build", value: $store.mission.totalBudget)
                            VStack(alignment: .leading) {
                                Text("Search radius")
                                Slider(value: $store.mission.radiusKM, in: 25...1000, step: 25)
                                Text("\(Int(store.mission.radiusKM)) km").foregroundStyle(.secondary)
                            }
                        }
                        HStack(spacing: 22) {
                            Toggle("Non-runners", isOn: $store.mission.allowNonRunner)
                            Toggle("Towable projects", isOn: $store.mission.allowTow)
                            Toggle("Transmission swaps", isOn: $store.mission.allowTransmissionSwap)
                        }
                    }.padding(8)
                }

                Text("Best paths right now").font(.title2.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                    ForEach(store.evaluations.prefix(6)) { evaluation in
                        BuildCard(evaluation: evaluation)
                    }
                }
            }
            .padding(28)
        }
    }
}

private struct MissionPicker: View {
    @Binding var mission: MissionType
    var body: some View {
        HStack(spacing: 10) {
            ForEach(MissionType.allCases) { item in
                Button {
                    mission = item
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: item.symbol).font(.title2)
                        Text(item.rawValue).font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(mission == item ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(mission == item ? Color.accentColor : .clear, lineWidth: 1))
            }
        }
    }
}

private struct MoneyField: View {
    let title: String
    @Binding var value: Double
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            TextField(title, value: $value, format: .currency(code: "CAD"))
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
        }
    }
}

struct BuildCard: View {
    let evaluation: BuildEvaluation
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(evaluation.listing.title).font(.headline)
                Spacer()
                ScoreBadge(score: evaluation.score)
            }
            Text(evaluation.listing.location).font(.caption).foregroundStyle(.secondary)
            HStack {
                Stat(label: "BUY", value: evaluation.listing.price.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                Stat(label: "PROJECTED", value: evaluation.projectedTotal.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                Stat(label: "DRIVE", value: evaluation.listing.drivetrain.rawValue)
            }
            Text(evaluation.reasons.first ?? "Candidate scored from mission fit, cost and risk.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ScoreBadge: View {
    let score: Int
    var body: some View {
        Text("\(score)")
            .font(.system(.headline, design: .rounded).bold())
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(score >= 80 ? Color.green.opacity(0.2) : Color.orange.opacity(0.18), in: Capsule())
    }
}

private struct Stat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2.bold()).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
