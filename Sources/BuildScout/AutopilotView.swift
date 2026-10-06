import SwiftUI

struct AutopilotView: View {
    @EnvironmentObject private var store: ListingStore
    @EnvironmentObject private var connections: ConnectionStore

    @State private var selectedCandidateID: UUID?
    @State private var report: AutopilotReport?
    @State private var missionReport: MissionAutopilotReport?
    @State private var running = false
    @State private var discovering = false

    private var listing: VehicleListing? {
        guard let selectedCandidateID else {
            return store.selectedEvaluation?.listing ?? store.listings.first
        }
        return store.listings.first(where: { $0.id == selectedCandidateID })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                launchPanel

                if let missionReport {
                    discoveryPanel(missionReport)
                }

                if let report {
                    executiveSummary(report)
                    pipelineCoverage(report)
                    unresolvedPanel(report)
                    sourcedSnapshot(report)
                    safetySnapshot(report)
                    researchSnapshot(report)
                    commitPanel(report)
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
                ScoutEyebrow(text: "Build Scout")
                Text("BUILD IT FROM THE MARKET.")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(-0.7)
                Text("Set the mission, pull fresh inventory, rank every normalized candidate, fully source the strongest paths, and pick the easiest A → Z build.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BuildScoutTheme.muted)
            }
            Spacer()

            if running || discovering {
                VStack(alignment: .trailing, spacing: 6) {
                    ProgressView()
                    Text(discovering ? "SCOUTING LIVE MARKET" : "BUILDING CASE FILE")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(BuildScoutTheme.accent)
                }
            }
        }
    }

    private var launchPanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScoutEyebrow(text: "Fresh build mission")
                    Spacer()
                    HStack(spacing: 8) {
                        status("MARKETCHECK", connections.hasMarketCheck)
                        status("WEB", connections.hasSerpAPI)
                        status("APIFY", connections.hasApify)
                        status("EBAY PARTS", connections.hasEBay)
                    }
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("MISSION")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(0.7)
                            .foregroundStyle(BuildScoutTheme.faint)
                        Picker("Mission", selection: $store.mission.type) {
                            ForEach(MissionType.allCases) { item in
                                Label(item.rawValue, systemImage: item.symbol).tag(item)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }

                    quickMoneyField("VEHICLE MAX", value: $store.mission.vehicleBudget)
                    quickMoneyField("ALL-IN MAX", value: $store.mission.totalBudget)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("DRIVETRAIN")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(0.7)
                            .foregroundStyle(BuildScoutTheme.faint)
                        Picker("Drivetrain", selection: $store.mission.preferredDrivetrain) {
                            ForEach(Drivetrain.allCases) { drive in
                                Text(drive.rawValue).tag(drive)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 110)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("RADIUS  \(Int(store.mission.radiusKM)) KM")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(0.7)
                            .foregroundStyle(BuildScoutTheme.faint)
                        Slider(value: $store.mission.radiusKM, in: 25...1000, step: 25)
                            .frame(minWidth: 150)
                    }
                }

                HStack(spacing: 8) {
                    missionToggle("NON-RUNNERS", icon: "engine.combustion", value: $store.mission.allowNonRunner)
                    missionToggle("TOWABLE", icon: "truck.box", value: $store.mission.allowTow)
                    missionToggle("TRANS SWAPS", icon: "gearshape.2", value: $store.mission.allowTransmissionSwap)

                    Spacer()

                    Text(connections.preferredRegion)
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                Divider().overlay(BuildScoutTheme.border)

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LIVE DISCOVERY ONLY")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(BuildScoutTheme.success)
                        Text("This run does not inject saved Candidates or old search results. It starts from the mission above and asks the connected live providers again.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)
                    }

                    Spacer()

                    Button {
                        discoverAndBuild()
                    } label: {
                        HStack(spacing: 9) {
                            if discovering {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "scope")
                            }
                            Text(discovering ? "SCOUTING + BUILDING…" : "BUILD SCOUT NOW")
                        }
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(0.6)
                        .padding(.horizontal, 4)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        discovering ||
                        running ||
                        (!connections.hasMarketCheck &&
                         !connections.hasSerpAPI &&
                         !connections.hasApify)
                    )
                }

                if !connections.hasMarketCheck && !connections.hasSerpAPI && !connections.hasApify {
                    Label(
                        "Connect MarketCheck, SerpApi, or an enabled Apify marketplace source in Connections. Build Scout will not pretend stale local examples are live inventory.",
                        systemImage: "antenna.radiowaves.left.and.right.slash"
                    )
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.warning)
                }

                if !store.listings.isEmpty {
                    Divider().overlay(BuildScoutTheme.border)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("SAVED CANDIDATE DEEP-DIVE")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(0.7)
                            Text("Saved listings stay saved, but they are separate from fresh market discovery.")
                                .font(.caption)
                                .foregroundStyle(BuildScoutTheme.faint)
                        }

                        Spacer()

                        Picker("Saved candidate", selection: Binding(
                            get: { selectedCandidateID ?? store.listings.first?.id },
                            set: {
                                selectedCandidateID = $0
                                report = nil
                            }
                        )) {
                            ForEach(store.listings) { saved in
                                Text(saved.title).tag(Optional(saved.id))
                            }
                        }
                        .labelsHidden()
                        .frame(width: 330)

                        Button {
                            run()
                        } label: {
                            Text(running ? "RUNNING…" : "DEEP-DIVE")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                        }
                        .buttonStyle(.bordered)
                        .disabled(listing == nil || running || discovering)
                    }
                }
            }
        }
    }

    private func discoveryPanel(_ missionReport: MissionAutopilotReport) -> some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ScoutEyebrow(text: "Fresh market run")
                        Text("\(missionReport.rawLeadCount) RAW LEADS → \(missionReport.candidateCount) CANDIDATES → \(missionReport.finalists.count) A→Z FINALISTS")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .tracking(0.3)
                    }

                    Spacer()

                    Text(missionReport.generatedAt.formatted(date: .omitted, time: .standard))
                        .font(.caption2)
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                if missionReport.rankedCandidates.isEmpty {
                    Text("The connected live providers returned no candidate that survived the current mission filters. Change budget/tolerances, region, or provider coverage and run again.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.warning)
                } else {
                    if !missionReport.finalists.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            ScoutEyebrow(text: "A → Z build paths")

                            ForEach(Array(missionReport.finalists.enumerated()), id: \.element.id) { index, finalist in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(index == 0 ? BuildScoutTheme.accent : BuildScoutTheme.raised)
                                            .frame(width: 30, height: 30)
                                        Image(systemName: index == 0 ? "crown.fill" : "\(index + 1).circle")
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundStyle(index == 0 ? .black : .white)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(finalist.listing.title)
                                            .font(.system(size: 13, weight: .bold))
                                            .lineLimit(1)
                                        Text([
                                            finalist.listing.source,
                                            finalist.listing.location
                                        ].filter { !$0.isEmpty }.joined(separator: " • "))
                                            .font(.caption2)
                                            .foregroundStyle(BuildScoutTheme.faint)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 3) {
                                        Text(finalist.sourcedPlan.minimumTotal.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                                            .font(.system(size: 13, weight: .black, design: .rounded))
                                            .foregroundStyle(index == 0 ? BuildScoutTheme.success : .white)
                                        Text("\(finalist.sourcedPlan.requiredLivePriceCount)/\(finalist.sourcedPlan.requiredLineCount) required lines live")
                                            .font(.caption2)
                                            .foregroundStyle(BuildScoutTheme.faint)
                                    }

                                    Button {
                                        store.addListing(finalist.listing)
                                        selectedCandidateID = finalist.listing.id
                                    } label: {
                                        Image(systemName: "bookmark.fill")
                                    }
                                    .buttonStyle(.plain)
                                    .help("Save candidate")

                                    if let urlText = finalist.listing.url,
                                       let url = URL(string: urlText) {
                                        Link(destination: url) {
                                            Image(systemName: "arrow.up.right.square")
                                        }
                                    }
                                }

                                if index < missionReport.finalists.count - 1 {
                                    Divider().overlay(BuildScoutTheme.border)
                                }
                            }
                        }

                        Divider().overlay(BuildScoutTheme.border)
                    }

                    HStack {
                        ScoutEyebrow(text: "Candidate ranking")
                        Spacer()
                        Text("TOP 8 OF \(missionReport.rankedCandidates.count)")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(0.7)
                            .foregroundStyle(BuildScoutTheme.faint)
                    }

                    ForEach(Array(missionReport.rankedCandidates.prefix(8).enumerated()), id: \.element.id) { index, evaluation in
                        HStack(spacing: 12) {
                            Text("#\(index + 1)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(BuildScoutTheme.faint)
                                .frame(width: 28, alignment: .leading)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(evaluation.listing.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .lineLimit(1)
                                Text([
                                    evaluation.listing.source,
                                    evaluation.listing.location
                                ].filter { !$0.isEmpty }.joined(separator: " • "))
                                    .font(.caption2)
                                    .foregroundStyle(BuildScoutTheme.faint)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("\(evaluation.score)/100")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                            Text(evaluation.listing.price.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                                .font(.caption2.bold())

                            Button {
                                store.addListing(evaluation.listing)
                                selectedCandidateID = evaluation.listing.id
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.plain)
                            .help("Save candidate")
                        }
                    }
                }

                if let champion = missionReport.champion {
                    Label(
                        "Best complete path after live sourcing: \(champion.listing.title)",
                        systemImage: "crown.fill"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(BuildScoutTheme.success)
                }
            }
        }
    }

    private func executiveSummary(_ report: AutopilotReport) -> some View {
        HStack(spacing: 14) {
            ScoutPanel {
                ScoutMetric(
                    label: "Candidate score",
                    value: "\(report.evaluation.score)/100",
                    detail: report.evaluation.mission.rawValue
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Original estimate",
                    value: money(report.evaluation.projectedTotal),
                    detail: "rules + garage profile"
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Sourced total",
                    value: money(report.sourcedTotal),
                    detail: "\(report.sourcedPlan.livePriceCount)/\(report.sourcedPlan.lines.count) lines live-priced"
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Data coverage",
                    value: "\(report.dataCoverage)%",
                    detail: "across connected providers"
                )
            }
        }
    }

    private func pipelineCoverage(_ report: AutopilotReport) -> some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                ScoutEyebrow(text: "A → B pipeline")

                HStack(spacing: 8) {
                    stage("CANDIDATE", true, "car.side.fill")
                    arrow
                    stage("IDENTITY", !report.canadianSpecs.isEmpty || !report.fuelEconomy.isEmpty, "barcode.viewfinder")
                    arrow
                    stage("SAFETY", true, "shield.checkered")
                    arrow
                    stage("PARTS", report.sourcedPlan.livePriceCount > 0, "shippingbox.fill")
                    arrow
                    stage("KNOWLEDGE", !report.research.guides.isEmpty, "books.vertical.fill")
                    arrow
                    stage("LOCAL HELP", !report.research.services.isEmpty, "mappin.and.ellipse")
                    arrow
                    stage("PROJECT", false, "wrench.and.screwdriver.fill")
                }
            }
        }
    }

    private func unresolvedPanel(_ report: AutopilotReport) -> some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ScoutEyebrow(text: "Before money changes hands")
                    Spacer()
                    Text("\(report.unresolved.count) OPEN")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(report.unresolved.isEmpty ? BuildScoutTheme.success : BuildScoutTheme.warning)
                }

                if report.unresolved.isEmpty {
                    Label("No major unresolved data gaps detected by the current pipeline.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(BuildScoutTheme.success)
                } else {
                    ForEach(report.unresolved, id: \.self) { item in
                        Label(item, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)
                    }
                }
            }
        }
    }

    private func sourcedSnapshot(_ report: AutopilotReport) -> some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ScoutEyebrow(text: "Sourced build")
                    Spacer()
                    Text(money(report.sourcedPlan.sourcedPartsCost))
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(BuildScoutTheme.success)
                }

                ForEach(report.sourcedPlan.lines.prefix(10)) { line in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(line.task.label)
                                .font(.system(size: 12, weight: .bold))
                            Text(line.cheapest?.title ?? "Fallback estimate")
                                .font(.caption2)
                                .foregroundStyle(BuildScoutTheme.faint)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(money(line.planningCost))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(line.cheapest == nil ? BuildScoutTheme.warning : BuildScoutTheme.success)
                    }
                    Divider().overlay(BuildScoutTheme.border)
                }
            }
        }
    }

    private func safetySnapshot(_ report: AutopilotReport) -> some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 12) {
                ScoutEyebrow(text: "Safety / reliability signal")

                HStack {
                    mini("RECALLS", "\(report.safety.recalls.count)")
                    mini("COMPLAINTS", "\(report.safety.complaints.count)")
                    mini("CRASH-FLAGGED", "\(report.safety.complaints.filter { $0.crash == true }.count)")
                    mini("FIRE-FLAGGED", "\(report.safety.complaints.filter { $0.fire == true }.count)")
                    mini("EPA CONFIGS", "\(report.fuelEconomy.count)")
                    mini("CA SPECS", "\(report.canadianSpecs.count)")
                }
            }
        }
    }

    private func researchSnapshot(_ report: AutopilotReport) -> some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 12) {
                ScoutEyebrow(text: "Execution support")

                HStack {
                    mini("VIDEOS", "\(report.research.guides.count)")
                    mini("THREADS", "\(report.research.forumThreads.count)")
                    mini("LOCAL SHOPS", "\(report.research.services.count)")
                    Spacer()
                }

                if let guide = report.research.guides.first,
                   let url = URL(string: guide.url) {
                    Link(destination: url) {
                        Label(guide.title, systemImage: "play.rectangle.fill")
                            .font(.caption.bold())
                            .lineLimit(1)
                    }
                }

                if let service = report.research.services.first,
                   let url = URL(string: service.url), !service.url.isEmpty {
                    Link(destination: url) {
                        Label(service.title, systemImage: "mappin.and.ellipse")
                            .font(.caption.bold())
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private func commitPanel(_ report: AutopilotReport) -> some View {
        ScoutPanel {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(BuildScoutTheme.success.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "flag.checkered")
                        .font(.title2)
                        .foregroundStyle(BuildScoutTheme.success)
                }

                VStack(alignment: .leading, spacing: 4) {
                    ScoutEyebrow(text: "Commit")
                    Text("Turn the sourced report into a live build ledger.")
                        .font(.headline)
                    Text("The project inherits the sourced line items and provider links so estimates can become actual spend.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }

                Spacer()

                Button {
                    store.startProject(from: report.sourcedPlan)
                } label: {
                    Label("START PROJECT", systemImage: "wrench.and.screwdriver.fill")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.5)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var emptyState: some View {
        ScoutPanel {
            HStack(spacing: 16) {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(BuildScoutTheme.accent)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Ready for a fresh market run.")
                        .font(.headline)
                    Text("Set the mission above and press BUILD SCOUT NOW. Saved candidates are kept separate and never injected into live discovery.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }
                Spacer()
            }
        }
    }

    private func discoverAndBuild() {
        discovering = true
        missionReport = nil
        report = nil

        Task {
            let result = await MissionAutopilotEngine.run(
                mission: store.mission,
                garage: store.garage,
                connections: connections
            )

            await MainActor.run {
                missionReport = result
                report = result.champion
                discovering = false
            }
        }
    }

    private func run() {
        guard let listing else { return }
        running = true
        report = nil

        Task {
            let result = await AutopilotEngine.run(
                listing: listing,
                mission: store.mission,
                garage: store.garage,
                connections: connections
            )
            await MainActor.run {
                report = result
                running = false
            }
        }
    }

    private func stage(_ title: String, _ complete: Bool, _ icon: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(complete ? BuildScoutTheme.success.opacity(0.18) : BuildScoutTheme.raised)
                    .frame(width: 34, height: 34)
                Image(systemName: complete ? "checkmark" : icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(complete ? BuildScoutTheme.success : BuildScoutTheme.faint)
            }
            Text(title)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(complete ? .white : BuildScoutTheme.faint)
        }
        .frame(maxWidth: .infinity)
    }

    private var arrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption2)
            .foregroundStyle(BuildScoutTheme.faint)
    }

    private func quickMoneyField(
        _ label: String,
        value: Binding<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(BuildScoutTheme.faint)

            HStack(spacing: 4) {
                Text("$")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(BuildScoutTheme.muted)
                TextField(label, value: value, format: .number)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 9)
            .frame(width: 120, height: 32)
            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(BuildScoutTheme.border))
        }
    }

    private func missionToggle(
        _ label: String,
        icon: String,
        value: Binding<Bool>
    ) -> some View {
        Button {
            value.wrappedValue.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.4)
            }
            .foregroundStyle(value.wrappedValue ? .black : BuildScoutTheme.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(value.wrappedValue ? BuildScoutTheme.accent : BuildScoutTheme.raised)
            )
        }
        .buttonStyle(.plain)
    }

    private func status(_ title: String, _ on: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(on ? BuildScoutTheme.success : BuildScoutTheme.faint)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
        }
        .foregroundStyle(on ? .white : BuildScoutTheme.faint)
    }

    private func mini(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(BuildScoutTheme.faint)
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
    }
}
