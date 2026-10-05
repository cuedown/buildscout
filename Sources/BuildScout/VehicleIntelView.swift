import SwiftUI

struct VehicleIntelView: View {
    @EnvironmentObject private var store: ListingStore
    @EnvironmentObject private var connections: ConnectionStore

    @State private var vin = ""
    @State private var decoded: VINDecodeResult?
    @State private var selectedCandidateID: UUID?
    @State private var safetyIntel: SafetyIntel?
    @State private var canadianSpecs: [CanadianSpecResult] = []
    @State private var fuelEconomyVehicles: [FuelEconomyVehicle] = []
    @State private var carsXEReports: [CarsXEReport] = []
    @State private var marketComparables: [HuntResult] = []
    @State private var isLoading = false
    @State private var isLoadingIntel = false
    @State private var errorMessage: String?
    @State private var addedMessage: String?

    private var selectedCandidate: VehicleListing? {
        guard let selectedCandidateID else { return store.listings.first }
        return store.listings.first(where: { $0.id == selectedCandidateID })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                candidateIntelPanel
                vinPanel

                if let decoded {
                    VINResultCard(result: decoded)

                    HStack {
                        if let addedMessage {
                            Text(addedMessage)
                                .font(.caption)
                                .foregroundStyle(BuildScoutTheme.success)
                        }
                        Spacer()
                        Button {
                            let listing = decoded.asListing()
                            store.addListing(listing)
                            addedMessage = "Added to Candidates. Set asking price and location there."
                        } label: {
                            Label("ADD TO CANDIDATES", systemImage: "plus.circle.fill")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(0.5)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if let safetyIntel {
                    safetyOverview(safetyIntel)
                    recallsPanel(safetyIntel.recalls)
                    complaintsPanel(safetyIntel.complaints)
                    fuelEconomyPanel
                    canadaSpecsPanel
                    marketComparablesPanel
                    carsXEPanel
                }

                dataPipelinePanel
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
        }
        .background(BuildScoutTheme.background)
        .task {
            if selectedCandidateID == nil {
                selectedCandidateID = store.listings.first?.id
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            ScoutEyebrow(text: "Vehicle intelligence")
            Text("KNOW WHAT YOU'RE BUYING.")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(-0.7)
            Text("Identity, specs, recalls, complaints, safety-test variants, and platform knowledge before build math begins.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BuildScoutTheme.muted)
        }
    }

    private var candidateIntelPanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        ScoutEyebrow(text: "Candidate intelligence")
                        Text("Run keyless government APIs against a saved candidate.")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Spacer()

                    if isLoadingIntel {
                        ProgressView().controlSize(.small)
                    }
                }

                HStack(spacing: 12) {
                    Picker("Candidate", selection: Binding(
                        get: { selectedCandidateID ?? store.listings.first?.id },
                        set: { selectedCandidateID = $0 }
                    )) {
                        ForEach(store.listings) { listing in
                            Text(listing.title).tag(Optional(listing.id))
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    Button {
                        loadCandidateIntel()
                    } label: {
                        Label("RUN INTEL", systemImage: "waveform.path.ecg.rectangle")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.5)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCandidate == nil || isLoadingIntel)
                }

                if let candidate = selectedCandidate {
                    HStack(spacing: 12) {
                        compact("YEAR", String(candidate.year))
                        compact("MAKE", candidate.make)
                        compact("MODEL", candidate.model)
                        compact("SOURCE", candidate.source)
                    }
                }
            }
        }
    }

    private var vinPanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ScoutEyebrow(text: "VIN decoder")
                    Spacer()
                    Text("NHTSA vPIC")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(BuildScoutTheme.success)
                }

                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundStyle(BuildScoutTheme.faint)
                        TextField("VIN", text: $vin)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .textCase(.uppercase)
                    }
                    .padding(.horizontal, 11)
                    .frame(height: 40)
                    .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                    Button {
                        decodeVIN()
                    } label: {
                        if isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("DECODE")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(0.6)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vin.trimmingCharacters(in: .whitespacesAndNewlines).count < 5 || isLoading)
                }

                Text("Full 17-character VINs are best. Partial decoding is supported by vPIC when enough VIN structure is available.")
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.faint)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.warning)
                }
            }
        }
    }

    private func safetyOverview(_ intel: SafetyIntel) -> some View {
        HStack(spacing: 14) {
            ScoutPanel {
                ScoutMetric(label: "Recalls", value: "\(intel.recalls.count)", detail: "NHTSA campaigns")
            }
            ScoutPanel {
                ScoutMetric(label: "Complaints", value: "\(intel.complaints.count)", detail: "owner reports")
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Crash reports",
                    value: "\(intel.complaints.filter { $0.crash == true }.count)",
                    detail: "complaints flagged crash"
                )
            }
            ScoutPanel {
                ScoutMetric(
                    label: "Safety variants",
                    value: "\(intel.ratings.count)",
                    detail: "NHTSA rating matches"
                )
            }
        }
    }

    private func recallsPanel(_ recalls: [NHTSARecall]) -> some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ScoutEyebrow(text: "Open safety history")
                    Spacer()
                    Text("NHTSA RECALLS")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                if recalls.isEmpty {
                    Text("No matching NHTSA recalls returned for this year / make / model.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                } else {
                    ForEach(recalls.prefix(10)) { recall in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(recall.Component ?? "Unknown component")
                                    .font(.system(size: 12, weight: .bold))
                                Spacer()
                                Text(recall.NHTSACampaignNumber ?? "")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BuildScoutTheme.faint)
                            }

                            Text(recall.Summary ?? "")
                                .font(.caption)
                                .foregroundStyle(BuildScoutTheme.muted)
                                .lineLimit(3)

                            if let consequence = recall.Consequence, !consequence.isEmpty {
                                Label(consequence, systemImage: "exclamationmark.triangle")
                                    .font(.caption2)
                                    .foregroundStyle(BuildScoutTheme.warning)
                                    .lineLimit(2)
                            }
                        }

                        if recall.id != recalls.prefix(10).last?.id {
                            Divider().overlay(BuildScoutTheme.border)
                        }
                    }
                }
            }
        }
    }

    private func complaintsPanel(_ complaints: [NHTSAComplaint]) -> some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ScoutEyebrow(text: "Complaint signal")
                    Spacer()
                    Text("NHTSA ODI")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                if complaints.isEmpty {
                    Text("No matching complaint records returned.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                } else {
                    let top = complaintComponents(complaints)
                    HStack(spacing: 10) {
                        ForEach(top.prefix(5), id: \.0) { item in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.0)
                                    .font(.system(size: 10, weight: .bold))
                                    .lineLimit(1)
                                Text("\(item.1) reports")
                                    .font(.caption2)
                                    .foregroundStyle(BuildScoutTheme.faint)
                            }
                            .padding(9)
                            .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    ForEach(complaints.prefix(6)) { complaint in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(complaint.components ?? "General")
                                    .font(.system(size: 11, weight: .bold))
                                Spacer()
                                if complaint.crash == true {
                                    Label("CRASH", systemImage: "exclamationmark.octagon.fill")
                                        .font(.caption2.bold())
                                        .foregroundStyle(BuildScoutTheme.warning)
                                }
                                if complaint.fire == true {
                                    Label("FIRE", systemImage: "flame.fill")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.red)
                                }
                            }
                            Text(complaint.summary ?? "")
                                .font(.caption)
                                .foregroundStyle(BuildScoutTheme.muted)
                                .lineLimit(3)
                        }
                        Divider().overlay(BuildScoutTheme.border)
                    }
                }
            }
        }
    }

    private var fuelEconomyPanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ScoutEyebrow(text: "EPA drivetrain / economy variants")
                    Spacer()
                    Text("FUELECONOMY.GOV")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                if fuelEconomyVehicles.isEmpty {
                    Text("No matching FuelEconomy.gov configuration returned for this candidate.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                } else {
                    ForEach(fuelEconomyVehicles.prefix(6)) { vehicle in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                Text(vehicle.model)
                                    .font(.system(size: 13, weight: .bold))
                                Spacer()
                                Text(vehicle.id)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BuildScoutTheme.faint)
                            }

                            HStack {
                                compact("TRANS", vehicle.transmission)
                                compact("DRIVE", vehicle.drive)
                                compact("ENGINE", [vehicle.displacementL.isEmpty ? nil : "\(vehicle.displacementL)L", vehicle.cylinders.isEmpty ? nil : "\(vehicle.cylinders)cyl"].compactMap { $0 }.joined(separator: " "))
                                compact("CITY", vehicle.cityMPG.isEmpty ? "—" : "\(vehicle.cityMPG) mpg")
                                compact("HWY", vehicle.highwayMPG.isEmpty ? "—" : "\(vehicle.highwayMPG) mpg")
                                compact("COMB", vehicle.combinedMPG.isEmpty ? "—" : "\(vehicle.combinedMPG) mpg")
                            }
                        }
                        Divider().overlay(BuildScoutTheme.border)
                    }
                }
            }
        }
    }

    private var canadaSpecsPanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ScoutEyebrow(text: "Canadian specifications")
                    Spacer()
                    Text("NHTSA / CANADA SPEC DATA")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                if canadianSpecs.isEmpty {
                    Text("No Canadian specification row matched this candidate.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                } else {
                    ForEach(canadianSpecs.prefix(4)) { spec in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(spec.model)
                                .font(.system(size: 13, weight: .bold))
                            HStack {
                                compact("LENGTH", spec.overallLengthCM.isEmpty ? "—" : "\(spec.overallLengthCM) cm")
                                compact("WIDTH", spec.overallWidthCM.isEmpty ? "—" : "\(spec.overallWidthCM) cm")
                                compact("HEIGHT", spec.overallHeightCM.isEmpty ? "—" : "\(spec.overallHeightCM) cm")
                                compact("WEIGHT", spec.curbWeightKG.isEmpty ? "—" : "\(spec.curbWeightKG) kg")
                                compact("DIST.", spec.weightDistribution.isEmpty ? "—" : spec.weightDistribution)
                            }
                        }
                        Divider().overlay(BuildScoutTheme.border)
                    }
                }
            }
        }
    }

    private var marketComparablesPanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ScoutEyebrow(text: "Canadian market comparables")
                    Spacer()
                    Text(connections.hasMarketCheck ? "MARKETCHECK" : "CONNECT MARKETCHECK")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(connections.hasMarketCheck ? BuildScoutTheme.success : BuildScoutTheme.faint)
                }

                if !connections.hasMarketCheck {
                    Text("Add a MarketCheck key in Connections to pull direct Canadian active-inventory comps.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                } else if marketComparables.isEmpty {
                    Text("No matching Canadian comparables returned for this candidate.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                } else {
                    ForEach(marketComparables.prefix(8)) { item in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .lineLimit(1)
                                Text([item.location, item.snippet].compactMap { $0 }.joined(separator: " • "))
                                    .font(.caption2)
                                    .foregroundStyle(BuildScoutTheme.faint)
                                    .lineLimit(2)
                            }

                            Spacer()

                            if let price = item.price {
                                Text(price.formatted(.currency(code: item.currency ?? "CAD").precision(.fractionLength(0))))
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(BuildScoutTheme.success)
                            }

                            if let url = URL(string: item.url), !item.url.isEmpty {
                                Link(destination: url) {
                                    Image(systemName: "arrow.up.right.square")
                                }
                            }
                        }
                        Divider().overlay(BuildScoutTheme.border)
                    }
                }
            }
        }
    }

    private var carsXEPanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ScoutEyebrow(text: "VIN-grade commercial intelligence")
                    Spacer()
                    Text(connections.hasCarsXE ? "CARSXE" : "CONNECT CARSXE")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(connections.hasCarsXE ? BuildScoutTheme.success : BuildScoutTheme.faint)
                }

                if selectedCandidate?.vin == nil {
                    Text("Add or decode a VIN to unlock VIN-level history, valuation, recall, specification, lien and theft calls.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                } else if !connections.hasCarsXE {
                    Text("CarsXE is optional. Add a key in Connections for the extra VIN-level reports.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                } else if carsXEReports.isEmpty {
                    Text("No CarsXE report returned for this VIN.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                } else {
                    ForEach(carsXEReports) { report in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Text(report.name)
                                    .font(.system(size: 12, weight: .bold))
                                Spacer()
                                Text(report.endpoint)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BuildScoutTheme.faint)
                            }

                            if report.facts.isEmpty {
                                Text("Endpoint responded but no high-signal fields were extracted.")
                                    .font(.caption2)
                                    .foregroundStyle(BuildScoutTheme.faint)
                            } else {
                                ForEach(report.facts.prefix(8)) { fact in
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(fact.key)
                                            .font(.caption2)
                                            .foregroundStyle(BuildScoutTheme.faint)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(fact.value)
                                            .font(.caption.bold())
                                            .lineLimit(2)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                        }
                        Divider().overlay(BuildScoutTheme.border)
                    }
                }
            }
        }
    }

    private var dataPipelinePanel: some View {
        ScoutPanel {
            HStack(spacing: 16) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.title2)
                    .foregroundStyle(BuildScoutTheme.accent)
                VStack(alignment: .leading, spacing: 5) {
                    ScoutEyebrow(text: "Data pipeline")
                    Text("VIN → identity → platform → recalls / complaints / specs → candidate score → parts → build graph")
                        .font(.system(size: 13, weight: .bold))
                    Text("This is the spine of BuildScout: raw listing text gets progressively upgraded into structured facts before the app recommends spending money.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }
                Spacer()
            }
        }
    }

    private func decodeVIN() {
        isLoading = true
        errorMessage = nil
        addedMessage = nil

        Task {
            do {
                let result = try await VPICClient.decode(vin: vin)
                await MainActor.run {
                    decoded = result
                    isLoading = false
                    if !result.decodedCleanly {
                        errorMessage = result.ErrorText
                    }
                }
            } catch {
                await MainActor.run {
                    decoded = nil
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func loadCandidateIntel() {
        guard let candidate = selectedCandidate else { return }
        isLoadingIntel = true
        errorMessage = nil

        Task {
            async let safety = SafetyIntelClient.fetch(
                year: candidate.year,
                make: candidate.make,
                model: candidate.model
            )
            async let specs = try? VPICClient.canadianSpecs(
                year: candidate.year,
                make: candidate.make
            )
            async let fuel = try? FuelEconomyClient.lookup(
                year: candidate.year,
                make: candidate.make,
                model: candidate.model
            )

            let loadedSafety = await safety
            let allSpecs = await specs ?? []
            let loadedFuel = await fuel ?? []

            let loadedCarsXE: [CarsXEReport]
            if connections.hasCarsXE, let vin = candidate.vin, vin.count == 17 {
                loadedCarsXE = await CarsXEClient.vehicleBundle(
                    vin: vin,
                    apiKey: connections.carsXEAPIKey,
                    mileageKM: candidate.odometerKM
                )
            } else {
                loadedCarsXE = []
            }

            let loadedComparables: [HuntResult]
            if connections.hasMarketCheck {
                loadedComparables = (try? await MarketCheckClient.comparables(
                    apiKey: connections.marketCheckAPIKey,
                    listing: candidate,
                    region: connections.preferredRegion
                )) ?? []
            } else {
                loadedComparables = []
            }

            let modelNeedle = candidate.model
                .split(separator: " ")
                .first
                .map(String.init)?
                .lowercased() ?? candidate.model.lowercased()

            let matchedSpecs = allSpecs.filter {
                $0.model.lowercased().contains(modelNeedle)
            }

            await MainActor.run {
                safetyIntel = loadedSafety
                canadianSpecs = matchedSpecs
                fuelEconomyVehicles = loadedFuel
                carsXEReports = loadedCarsXE
                marketComparables = loadedComparables
                isLoadingIntel = false
            }
        }
    }

    private func complaintComponents(_ complaints: [NHTSAComplaint]) -> [(String, Int)] {
        var counts: [String: Int] = [:]
        for complaint in complaints {
            let raw = complaint.components ?? "Unknown"
            for component in raw.split(separator: ",") {
                let key = component.trimmingCharacters(in: .whitespacesAndNewlines)
                if !key.isEmpty { counts[key, default: 0] += 1 }
            }
        }
        return counts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    private func compact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(BuildScoutTheme.faint)
            Text(value.isEmpty ? "Unknown" : value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VINResultCard: View {
    let result: VINDecodeResult

    var body: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        ScoutEyebrow(text: "Decoded identity")
                        Text([result.ModelYear, result.Make.capitalized, result.Model, result.Trim]
                            .filter { !$0.isEmpty }
                            .joined(separator: " "))
                            .font(.system(size: 22, weight: .bold, design: .rounded))

                        Text(result.VIN)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(BuildScoutTheme.faint)
                    }

                    Spacer()

                    Label(
                        result.decodedCleanly ? "DECODED" : "CHECK RESULT",
                        systemImage: result.decodedCleanly ? "checkmark.seal.fill" : "exclamationmark.triangle"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(result.decodedCleanly ? BuildScoutTheme.success : BuildScoutTheme.warning)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                    IntelStat(label: "BODY", value: result.BodyClass)
                    IntelStat(label: "DRIVETRAIN", value: result.DriveType)
                    IntelStat(label: "TRANSMISSION", value: transmissionText)
                    IntelStat(label: "ENGINE", value: result.engineDescription ?? "")
                    IntelStat(label: "FUEL", value: result.FuelTypePrimary)
                    IntelStat(label: "PLANT COUNTRY", value: result.PlantCountry)
                }

                if !result.ErrorText.isEmpty && !result.decodedCleanly {
                    Text(result.ErrorText)
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.warning)
                }
            }
        }
    }

    private var transmissionText: String {
        [result.TransmissionStyle, result.TransmissionSpeeds.isEmpty ? nil : "\(result.TransmissionSpeeds)-speed"]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }
}

private struct IntelStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(BuildScoutTheme.faint)
            Text(value.isEmpty ? "Unknown" : value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
