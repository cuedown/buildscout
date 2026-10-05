import SwiftUI

struct BuildLabView: View {
    @EnvironmentObject private var store: ListingStore
    @EnvironmentObject private var connections: ConnectionStore

    @State private var selectedCandidateID: UUID?
    @State private var plan: SourcedBuildPlan?
    @State private var isSourcing = false
    @State private var errorMessage: String?

    private var selectedListing: VehicleListing? {
        guard let selectedCandidateID else { return store.listings.first }
        return store.listings.first(where: { $0.id == selectedCandidateID })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                candidatePanel

                if let plan {
                    totals(plan)
                    buildLines(plan)
                } else {
                    emptyState
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
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                ScoutEyebrow(text: "Build lab")
                Text("SOURCE THE WHOLE BUILD.")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(-0.7)
                Text("Turn one candidate into a parts search plan, pull live options, and compare sourced cost against the original estimate.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BuildScoutTheme.muted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(store.mission.type.rawValue.uppercased())
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(BuildScoutTheme.accent)
                Text("Target \(money(store.mission.totalBudget))")
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.muted)
            }
        }
    }

    private var candidatePanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ScoutEyebrow(text: "Candidate")
                    Spacer()
                    providerStatus
                }

                HStack(spacing: 12) {
                    Picker("Candidate", selection: Binding(
                        get: { selectedCandidateID ?? store.listings.first?.id },
                        set: {
                            selectedCandidateID = $0
                            plan = nil
                        }
                    )) {
                        ForEach(store.listings) { listing in
                            Text(listing.title).tag(Optional(listing.id))
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    Button {
                        sourceBuild()
                    } label: {
                        HStack(spacing: 8) {
                            if isSourcing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "cart.badge.plus")
                            }
                            Text(isSourcing ? "SOURCING…" : "SOURCE BUILD")
                        }
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.5)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedListing == nil || isSourcing || (!connections.hasSerpAPI && !connections.hasEBay))
                }

                if let listing = selectedListing {
                    let eval = ScoringEngine.evaluate(listing, mission: store.mission, garage: store.garage)
                    HStack(spacing: 14) {
                        compact("BUY", money(listing.price))
                        compact("BASE EST.", money(eval.projectedTotal))
                        compact("SCORE", "\(eval.score)/100")
                        compact("DRIVE", listing.drivetrain.rawValue)
                        compact("GEARBOX", listing.transmission.rawValue)
                    }
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.warning)
                }
            }
        }
    }

    private var providerStatus: some View {
        HStack(spacing: 8) {
            statusDot("SERP", connections.hasSerpAPI)
            statusDot("EBAY", connections.hasEBay)
        }
    }

    private func totals(_ plan: SourcedBuildPlan) -> some View {
        HStack(spacing: 14) {
            ScoutPanel {
                ScoutMetric(
                    label: "Purchase",
                    value: money(plan.purchaseCost),
                    detail: plan.listing.title
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Required parts",
                    value: money(plan.requiredPartsCost),
                    detail: "\(plan.requiredLivePriceCount)/\(plan.requiredLineCount) required lines live-priced"
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Minimum viable",
                    value: money(plan.minimumTotal),
                    detail: budgetDeltaText(plan)
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Full wish-list",
                    value: money(plan.fullBuildTotal),
                    detail: "+\(money(plan.optionalPartsCost)) optional"
                )
            }
        }
    }

    private func buildLines(_ plan: SourcedBuildPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    ScoutEyebrow(text: "Sourced BOM")
                    Text("\(plan.lines.count) BUILD LINES")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                }

                Spacer()

                Button {
                    store.startProject(from: plan)
                } label: {
                    Label("START SOURCED PROJECT", systemImage: "wrench.and.screwdriver.fill")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.4)
                }
                .buttonStyle(.borderedProminent)
            }

            ForEach(plan.lines) { line in
                ScoutPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 8) {
                                    Text(line.task.category.uppercased())
                                        .font(.system(size: 8, weight: .black, design: .rounded))
                                        .tracking(0.8)
                                        .foregroundStyle(BuildScoutTheme.accent)

                                    Text(line.task.required ? "REQUIRED" : "OPTIONAL")
                                        .font(.system(size: 7, weight: .black, design: .rounded))
                                        .tracking(0.6)
                                        .foregroundStyle(line.task.required ? BuildScoutTheme.success : BuildScoutTheme.faint)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.white.opacity(0.05), in: Capsule())
                                }

                                Text(line.task.label)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))

                                Text(line.task.query)
                                    .font(.caption)
                                    .foregroundStyle(BuildScoutTheme.faint)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 3) {
                                Text(money(line.planningCost))
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(line.cheapest != nil ? BuildScoutTheme.success : BuildScoutTheme.warning)
                                Text(line.cheapest != nil ? "LIVE LOW" : "FALLBACK")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .tracking(0.6)
                                    .foregroundStyle(BuildScoutTheme.faint)
                            }
                        }

                        if !line.task.notes.isEmpty {
                            Text(line.task.notes)
                                .font(.caption)
                                .foregroundStyle(BuildScoutTheme.muted)
                        }

                        if line.options.isEmpty {
                            Label(
                                "No priced live option returned. BuildScout is carrying the fallback estimate.",
                                systemImage: "questionmark.circle"
                            )
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.warning)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(line.options.prefix(6)) { option in
                                        optionCard(option, cheapest: option.id == line.cheapest?.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ScoutPanel {
            HStack(spacing: 16) {
                Image(systemName: "cart.badge.questionmark")
                    .font(.system(size: 32))
                    .foregroundStyle(BuildScoutTheme.accent)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Nothing sourced yet.")
                        .font(.headline)
                    Text("Pick a candidate and run Source Build. BuildScout will derive component searches from the mission and vehicle, then query every connected parts provider.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }
                Spacer()
            }
        }
    }

    private func optionCard(_ option: HuntResult, cheapest: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(option.provider.uppercased())
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(BuildScoutTheme.faint)
                Spacer()
                if cheapest {
                    Text("LOW")
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .foregroundStyle(BuildScoutTheme.success)
                }
            }

            Text(option.title)
                .font(.system(size: 11, weight: .bold))
                .lineLimit(3)
                .frame(height: 45, alignment: .topLeading)

            Text(option.price.map { money($0, currency: option.currency ?? "CAD") } ?? "Price unavailable")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(option.price == nil ? BuildScoutTheme.warning : BuildScoutTheme.success)

            Spacer()

            if let url = URL(string: option.url), !option.url.isEmpty {
                Link(destination: url) {
                    Label("OPEN", systemImage: "arrow.up.right")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                }
            }
        }
        .padding(11)
        .frame(width: 210, height: 145, alignment: .topLeading)
        .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(cheapest ? BuildScoutTheme.success.opacity(0.55) : BuildScoutTheme.border)
        )
    }

    private func sourceBuild() {
        guard let listing = selectedListing else { return }
        isSourcing = true
        errorMessage = nil

        Task {
            let sourced = await PartSourcingEngine.source(
                listing: listing,
                mission: store.mission,
                garage: store.garage,
                connections: connections
            )

            await MainActor.run {
                plan = sourced
                isSourcing = false
                if sourced.lines.isEmpty {
                    errorMessage = "No sourceable build lines were generated for this mission yet."
                }
            }
        }
    }

    private func compact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(BuildScoutTheme.faint)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusDot(_ label: String, _ on: Bool) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(on ? BuildScoutTheme.success : BuildScoutTheme.faint)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.5)
        }
        .foregroundStyle(on ? .white : BuildScoutTheme.faint)
    }

    private func budgetDeltaText(_ plan: SourcedBuildPlan) -> String {
        let delta = plan.sourcedTotal - store.mission.totalBudget
        if delta <= 0 {
            return "\(money(abs(delta))) under target"
        }
        return "\(money(delta)) over target"
    }

    private func money(_ value: Double, currency: String = "CAD") -> String {
        value.formatted(.currency(code: currency).precision(.fractionLength(0)))
    }
}
