import SwiftUI

struct CandidateBrowser: View {
    @EnvironmentObject private var store: ListingStore

    var body: some View {
        HStack(spacing: 0) {
            candidateRail
                .frame(width: 390)

            Rectangle()
                .fill(BuildScoutTheme.border)
                .frame(width: 1)

            if let item = store.selectedEvaluation ?? store.evaluations.first {
                BuildDetail(evaluation: item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "No candidates yet",
                    systemImage: "car.side",
                    description: Text("Import a listing or hunt for a project first.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(BuildScoutTheme.background)
    }

    private var candidateRail: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                ScoutEyebrow(text: "Ranked inventory")
                HStack {
                    Text("CANDIDATES")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Spacer()
                    Text("\(store.evaluations.count)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(BuildScoutTheme.accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(BuildScoutTheme.accent.opacity(0.12), in: Capsule())
                }

                HStack(spacing: 8) {
                    HStack(spacing: 7) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(BuildScoutTheme.faint)
                        TextField("Search title, model, location", text: $store.query)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                    Button {
                        store.favoritesOnly.toggle()
                    } label: {
                        Image(systemName: store.favoritesOnly ? "star.fill" : "star")
                            .frame(width: 34, height: 34)
                            .foregroundStyle(store.favoritesOnly ? BuildScoutTheme.accent : BuildScoutTheme.muted)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                    .help("Favorites only")
                }
            }
            .padding(18)

            Rectangle()
                .fill(BuildScoutTheme.border)
                .frame(height: 1)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(store.evaluations) { item in
                        CandidateRow(
                            evaluation: item,
                            selected: selectedID == item.listing.id,
                            favorite: store.favoriteIDs.contains(item.listing.id),
                            select: { store.selectedListingID = item.listing.id },
                            favoriteAction: { store.toggleFavorite(item.listing) }
                        )
                    }
                }
                .padding(10)
            }
        }
        .background(BuildScoutTheme.sidebar)
    }

    private var selectedID: UUID? {
        store.selectedListingID ?? store.evaluations.first?.listing.id
    }
}

private struct CandidateRow: View {
    let evaluation: BuildEvaluation
    let selected: Bool
    let favorite: Bool
    let select: () -> Void
    let favoriteAction: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(evaluation.listing.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(evaluation.listing.location.isEmpty ? evaluation.listing.source : evaluation.listing.location)
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("\(evaluation.score)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(evaluation.score >= 80 ? BuildScoutTheme.success : BuildScoutTheme.warning)
                }

                HStack(spacing: 12) {
                    railStat("BUY", money(evaluation.listing.price))
                    railStat("FINISHED", money(evaluation.projectedTotal))
                    railStat("DRIVE", evaluation.listing.drivetrain.rawValue)

                    Spacer()

                    Button(action: favoriteAction) {
                        Image(systemName: favorite ? "star.fill" : "star")
                            .foregroundStyle(favorite ? BuildScoutTheme.accent : BuildScoutTheme.faint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? BuildScoutTheme.raised : BuildScoutTheme.surface.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? BuildScoutTheme.accent.opacity(0.75) : BuildScoutTheme.border)
            )
        }
        .buttonStyle(.plain)
    }

    private func railStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(BuildScoutTheme.faint)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(BuildScoutTheme.muted)
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
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
                detailHeader
                metricStrip

                if let profile = PlatformKnowledge.match(evaluation.listing) {
                    platformCard(profile)
                }

                HStack(alignment: .top, spacing: 16) {
                    intelColumn
                    buildPath
                }

                footer
            }
            .padding(28)
        }
        .background(BuildScoutTheme.background)
    }

    private var detailHeader: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                ScoutEyebrow(text: "Candidate analysis")
                Text(evaluation.listing.title)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .tracking(-0.5)
                Text(evaluation.listing.location.isEmpty ? evaluation.listing.source : evaluation.listing.location)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BuildScoutTheme.muted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                HStack(spacing: 5) {
                    Text("\(evaluation.score)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text("/100")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(BuildScoutTheme.faint)
                }
                .foregroundStyle(evaluation.score >= 80 ? BuildScoutTheme.success : BuildScoutTheme.warning)

                HStack(spacing: 8) {
                    Button {
                        store.toggleFavorite(evaluation.listing)
                    } label: {
                        Image(systemName: store.favoriteIDs.contains(evaluation.listing.id) ? "star.fill" : "star")
                    }

                    Button {
                        store.startProject(from: evaluation)
                    } label: {
                        Label("START BUILD", systemImage: "wrench.and.screwdriver.fill")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.6)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var metricStrip: some View {
        ScoutPanel {
            HStack(spacing: 18) {
                ScoutMetric(
                    label: "Purchase",
                    value: money(evaluation.listing.price),
                    detail: evaluation.listing.runs ? "runs / drives claimed" : "project / non-runner"
                )
                ScoutMetric(
                    label: "Projected",
                    value: money(evaluation.projectedTotal),
                    detail: "current mission + garage"
                )
                ScoutMetric(
                    label: "Transmission",
                    value: evaluation.listing.transmission.rawValue,
                    detail: "as listed"
                )
                ScoutMetric(
                    label: "Drivetrain",
                    value: evaluation.listing.drivetrain.rawValue,
                    detail: "mission-critical"
                )
            }
        }
    }

    private func platformCard(_ profile: PlatformProfile) -> some View {
        ScoutPanel {
            HStack(alignment: .top, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(BuildScoutTheme.accent.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "cpu.fill")
                        .font(.title2)
                        .foregroundStyle(BuildScoutTheme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        ScoutEyebrow(text: "Platform intelligence")
                        Text(profile.id)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }

                    Text("Parts availability \(profile.partsAvailability)/10  •  Fabrication friendliness \(profile.fabricationFriendliness)/10")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)

                    if let note = profile.driftNotes.first {
                        Text(note)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }

                Spacer()
            }
        }
    }

    private var intelColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScoutPanel {
                VStack(alignment: .leading, spacing: 12) {
                    ScoutEyebrow(text: "Why it works")
                    ForEach(evaluation.reasons.prefix(6), id: \.self) { item in
                        HStack(alignment: .top, spacing: 9) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(BuildScoutTheme.success)
                                .padding(.top, 1)
                            Text(item)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(BuildScoutTheme.muted)
                        }
                    }
                }
            }

            if !evaluation.warnings.isEmpty {
                ScoutPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        ScoutEyebrow(text: "Watch-outs")
                        ForEach(evaluation.warnings.prefix(6), id: \.self) { item in
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(BuildScoutTheme.warning)
                                    .padding(.top, 1)
                                Text(item)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(BuildScoutTheme.muted)
                            }
                        }
                    }
                }
            }

            if !evaluation.listing.notes.isEmpty {
                ScoutPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        ScoutEyebrow(text: "Listing notes")
                        Text(evaluation.listing.notes)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BuildScoutTheme.muted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var buildPath: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    ScoutEyebrow(text: "Build path")
                    Spacer()
                    Text("\(graph.nodes.count) steps")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }

                ForEach(Array(graph.nodes.enumerated()), id: \.element.id) { index, node in
                    HStack(alignment: .top, spacing: 11) {
                        ZStack {
                            Circle()
                                .fill(index == 0 ? BuildScoutTheme.accent : BuildScoutTheme.raised)
                                .frame(width: 27, height: 27)
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(index == 0 ? .black : .white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(node.title)
                                .font(.system(size: 12, weight: .bold))
                            if !node.dependsOnTitles.isEmpty {
                                Text("After: \(node.dependsOnTitles.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundStyle(BuildScoutTheme.faint)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(money(node.estimate))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Text(node.required ? "required" : "optional")
                                .font(.caption2)
                                .foregroundStyle(BuildScoutTheme.faint)
                        }
                    }

                    if index < graph.nodes.count - 1 {
                        Rectangle()
                            .fill(BuildScoutTheme.border)
                            .frame(height: 1)
                            .padding(.leading, 38)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var footer: some View {
        HStack {
            if let urlText = evaluation.listing.url, let url = URL(string: urlText) {
                Link(destination: url) {
                    Label("OPEN ORIGINAL", systemImage: "arrow.up.right.square")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.5)
                }
            }

            Spacer()

            Button("DELETE CANDIDATE", role: .destructive) {
                store.remove(evaluation.listing)
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
    }
}
