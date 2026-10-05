import SwiftUI

struct MissionView: View {
    @EnvironmentObject private var store: ListingStore

    private var best: BuildEvaluation? { store.evaluations.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                HStack(spacing: 14) {
                    ScoutPanel {
                        ScoutMetric(
                            label: "Candidates",
                            value: "\(store.evaluations.count)",
                            detail: "ranked for \(store.mission.type.rawValue.lowercased())"
                        )
                    }
                    ScoutPanel {
                        ScoutMetric(
                            label: "Best score",
                            value: best.map { "\($0.score)/100" } ?? "—",
                            detail: best?.listing.title ?? "no candidates yet"
                        )
                    }
                    ScoutPanel {
                        ScoutMetric(
                            label: "Vehicle budget",
                            value: money(store.mission.vehicleBudget),
                            detail: "purchase ceiling"
                        )
                    }
                    ScoutPanel {
                        ScoutMetric(
                            label: "All-in budget",
                            value: money(store.mission.totalBudget),
                            detail: "target finished cost"
                        )
                    }
                }

                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 18) {
                        ScoutEyebrow(text: "01 • Choose mission")
                        missionGrid

                        ScoutEyebrow(text: "02 • Budget & tolerance")
                        controls
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    topCandidate
                        .frame(width: 360)
                }

                HStack {
                    ScoutEyebrow(text: "03 • Best paths right now")
                    Spacer()
                    Text("Sorted by finished-build value, not asking price")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 315), spacing: 14)],
                    spacing: 14
                ) {
                    ForEach(store.evaluations.prefix(6)) { evaluation in
                        BuildCard(evaluation: evaluation)
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
        }
        .background(BuildScoutTheme.background)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                ScoutEyebrow(text: "Build mission")
                Text("WHAT ARE WE BUILDING?")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(-0.8)
                Text("Pick the outcome. BuildScout re-prices the market around the finished thing you actually want.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BuildScoutTheme.muted)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: store.mission.type.symbol)
                Text(store.mission.type.rawValue.uppercased())
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.0)
            }
            .foregroundStyle(BuildScoutTheme.accent)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(BuildScoutTheme.accent.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(BuildScoutTheme.accent.opacity(0.35)))
        }
    }

    private var missionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 10)], spacing: 10) {
            ForEach(MissionType.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        store.mission.type = item
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: item.symbol)
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            if store.mission.type == item {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BuildScoutTheme.accent)
                            }
                        }

                        Text(item.rawValue.uppercased())
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(0.7)
                    }
                    .foregroundStyle(store.mission.type == item ? .white : BuildScoutTheme.muted)
                    .padding(15)
                    .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(store.mission.type == item ? BuildScoutTheme.raised : BuildScoutTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(
                                store.mission.type == item ? BuildScoutTheme.accent : BuildScoutTheme.border,
                                lineWidth: store.mission.type == item ? 1.5 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var controls: some View {
        ScoutPanel {
            VStack(spacing: 18) {
                HStack(spacing: 18) {
                    budgetField("Vehicle", value: $store.mission.vehicleBudget)
                    budgetField("All-in build", value: $store.mission.totalBudget)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text("SEARCH RADIUS")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(1.0)
                                .foregroundStyle(BuildScoutTheme.faint)
                            Spacer()
                            Text("\(Int(store.mission.radiusKM)) KM")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(BuildScoutTheme.accent)
                        }

                        Slider(value: $store.mission.radiusKM, in: 25...1000, step: 25)
                    }
                    .frame(maxWidth: .infinity)
                }

                Divider().overlay(BuildScoutTheme.border)

                HStack(spacing: 10) {
                    toleranceChip(
                        "NON-RUNNERS",
                        icon: "engine.combustion",
                        isOn: $store.mission.allowNonRunner
                    )
                    toleranceChip(
                        "TOWABLE",
                        icon: "truck.box",
                        isOn: $store.mission.allowTow
                    )
                    toleranceChip(
                        "TRANS SWAPS",
                        icon: "gearshape.2",
                        isOn: $store.mission.allowTransmissionSwap
                    )
                    Spacer()
                }
            }
        }
    }

    private var topCandidate: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScoutEyebrow(text: "Top candidate")
                    Spacer()
                    if let best {
                        scorePill(best.score)
                    }
                }

                if let best {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(best.listing.title)
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .lineLimit(2)
                        Text(best.listing.location.isEmpty ? best.listing.source : best.listing.location)
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)
                    }

                    HStack {
                        compactMetric("BUY", money(best.listing.price))
                        compactMetric("BUILD", money(best.projectedTotal))
                        compactMetric("DRIVE", best.listing.drivetrain.rawValue)
                    }

                    Divider().overlay(BuildScoutTheme.border)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(best.reasons.prefix(3), id: \.self) { reason in
                            Label {
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(BuildScoutTheme.muted)
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BuildScoutTheme.success)
                            }
                        }
                    }

                    if best.projectedTotal <= store.mission.totalBudget {
                        Label(
                            "\(money(store.mission.totalBudget - best.projectedTotal)) headroom",
                            systemImage: "arrow.down.right.circle.fill"
                        )
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BuildScoutTheme.success)
                    } else {
                        Label(
                            "\(money(best.projectedTotal - store.mission.totalBudget)) over target",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BuildScoutTheme.warning)
                    }
                } else {
                    ContentUnavailableView(
                        "No candidates yet",
                        systemImage: "car.side",
                        description: Text("Import a listing or open Hunter.")
                    )
                }
            }
        }
    }

    private func budgetField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(BuildScoutTheme.faint)

            HStack(spacing: 6) {
                Text("$")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(BuildScoutTheme.muted)

                TextField(title, value: value, format: .number)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(BuildScoutTheme.border)
            )
        }
        .frame(width: 150)
    }

    private func toleranceChip(
        _ title: String,
        icon: String,
        isOn: Binding<Bool>
    ) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.4)
            }
            .foregroundStyle(isOn.wrappedValue ? .black : BuildScoutTheme.muted)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isOn.wrappedValue ? BuildScoutTheme.accent : BuildScoutTheme.raised)
            )
        }
        .buttonStyle(.plain)
    }

    private func compactMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(BuildScoutTheme.faint)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scorePill(_ score: Int) -> some View {
        Text("\(score)")
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(score >= 80 ? BuildScoutTheme.success : BuildScoutTheme.warning)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.06), in: Capsule())
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
    }
}

struct BuildCard: View {
    let evaluation: BuildEvaluation

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(evaluation.listing.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .lineLimit(2)
                    Text(evaluation.listing.location.isEmpty ? evaluation.listing.source : evaluation.listing.location)
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }

                Spacer()

                Text("\(evaluation.score)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(evaluation.score >= 80 ? BuildScoutTheme.success : BuildScoutTheme.warning)
            }

            HStack(spacing: 12) {
                MiniStat(label: "BUY", value: money(evaluation.listing.price))
                MiniStat(label: "FINISHED", value: money(evaluation.projectedTotal))
                MiniStat(label: "DRIVE", value: evaluation.listing.drivetrain.rawValue)
            }

            Divider().overlay(BuildScoutTheme.border)

            Text(evaluation.reasons.first ?? "Scored from mission fit, cost, platform, garage, and risk.")
                .font(.caption)
                .foregroundStyle(BuildScoutTheme.muted)
                .lineLimit(2)
                .frame(minHeight: 32, alignment: .top)

            HStack {
                Label(evaluation.listing.transmission.rawValue, systemImage: "gearshape")
                Spacer()
                if evaluation.listing.runs {
                    Label("RUNS", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(BuildScoutTheme.success)
                } else {
                    Label("PROJECT", systemImage: "wrench.fill")
                        .foregroundStyle(BuildScoutTheme.warning)
                }
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(BuildScoutTheme.muted)
        }
        .padding(17)
        .background(
            RoundedRectangle(cornerRadius: BuildScoutTheme.cardRadius, style: .continuous)
                .fill(BuildScoutTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BuildScoutTheme.cardRadius, style: .continuous)
                .stroke(BuildScoutTheme.border)
        )
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
    }
}

private struct MiniStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(BuildScoutTheme.faint)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
