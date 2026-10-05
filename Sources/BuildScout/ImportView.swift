import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @EnvironmentObject private var store: ListingStore
    @State private var rawText = ""
    @State private var draft = ListingDraft()
    @State private var parsed = false
    @State private var showFileImporter = false
    @State private var importMessage: String?
    @State private var capturedBatch: [VehicleListing] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                pastePanel

                if !capturedBatch.isEmpty {
                    capturedBatchPanel
                }

                if parsed {
                    DraftEditor(draft: $draft) {
                        let listing = draft.makeListing()
                        store.addListing(listing)
                        importMessage = "Added \(listing.title)"
                        rawText = ""
                        parsed = false
                    }
                }

                parserLegend
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
        }
        .background(BuildScoutTheme.background)
        .onAppear {
            consumeBrowserCaptureIfNeeded()
        }
        .onChange(of: store.pendingBrowserCapture?.id) { _, _ in
            consumeBrowserCaptureIfNeeded()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json, .commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let url = try result.get().first else { return }
                let listings = try ListingImportParser.decodeFile(url: url)
                store.addListings(listings)
                importMessage = "Imported \(listings.count) listing\(listings.count == 1 ? "" : "s")."
            } catch {
                importMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    private func consumeBrowserCaptureIfNeeded() {
        guard let capture = store.pendingBrowserCapture else { return }

        if !capture.items.isEmpty {
            var seen = Set<String>()
            capturedBatch = capture.items.compactMap { item in
                let composite = [
                    item.title,
                    item.text,
                    item.url
                ]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")

                var parsedDraft = ListingImportParser.parse(composite)
                parsedDraft.source = capture.source
                parsedDraft.url = item.url

                let listing = parsedDraft.makeListing()
                let key = listing.url ?? "\(listing.title)|\(Int(listing.price))"
                guard seen.insert(key).inserted else { return nil }

                let titleHasYear = listing.title.range(
                    of: #"\b(19[7-9]\d|20[0-2]\d)\b"#,
                    options: .regularExpression
                ) != nil
                let useful = listing.price > 0 || titleHasYear || !listing.make.isEmpty
                return useful ? listing : nil
            }

            parsed = false
            rawText = ""
            importMessage = "Captured \(capturedBatch.count) visible listing leads from \(capture.source)."
        } else {
            rawText = [
                capture.title,
                capture.text,
                capture.pageURL
            ]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")

            draft = ListingImportParser.parse(rawText)
            draft.source = capture.source
            draft.url = capture.pageURL
            parsed = true
            capturedBatch = []
            importMessage = "Captured from \(capture.source). Review before saving."
        }

        store.pendingBrowserCapture = nil
    }

    private var capturedBatchPanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ScoutEyebrow(text: "Visible results capture")
                        Text("\(capturedBatch.count) LISTING LEADS")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                    }

                    Spacer()

                    Button {
                        store.addListings(capturedBatch)
                        importMessage = "Added \(capturedBatch.count) captured candidates."
                        capturedBatch = []
                    } label: {
                        Label("ADD ALL CANDIDATES", systemImage: "tray.and.arrow.down.fill")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.5)
                    }
                    .buttonStyle(.borderedProminent)
                }

                ForEach(capturedBatch.prefix(20)) { listing in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(listing.title)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)

                            Text(
                                [
                                    listing.location,
                                    listing.transmission == .unknown ? nil : listing.transmission.rawValue,
                                    listing.drivetrain == .unknown ? nil : listing.drivetrain.rawValue
                                ]
                                .compactMap { $0 }
                                .filter { !$0.isEmpty }
                                .joined(separator: " • ")
                            )
                            .font(.caption2)
                            .foregroundStyle(BuildScoutTheme.faint)
                        }

                        Spacer()

                        if listing.price > 0 {
                            Text(
                                listing.price.formatted(
                                    .currency(code: "CAD").precision(.fractionLength(0))
                                )
                            )
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(BuildScoutTheme.success)
                        }
                    }

                    Divider().overlay(BuildScoutTheme.border)
                }

                if capturedBatch.count > 20 {
                    Text("+ \(capturedBatch.count - 20) more captured leads")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                Text("This is a user-triggered snapshot of the results already rendered in your browser. BuildScout does not crawl pagination or silently browse behind your session.")
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.muted)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                ScoutEyebrow(text: "Listing intake")
                Text("DROP THE AD. GET THE MATH.")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(-0.7)
                Text("Paste a messy ad, import a dataset, or bring in community leads. Review the facts before BuildScout scores it.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BuildScoutTheme.muted)
            }
            Spacer()

            Button {
                showFileImporter = true
            } label: {
                Label("JSON / CSV", systemImage: "tray.and.arrow.down.fill")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.6)
            }
            .buttonStyle(.bordered)
        }
    }

    private var pastePanel: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ScoutEyebrow(text: "Paste listing")
                    Spacer()
                    if let importMessage {
                        Text(importMessage)
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.success)
                    }
                }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $rawText)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 210)
                        .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BuildScoutTheme.border))

                    if rawText.isEmpty {
                        Text("Paste the full Marketplace / auction / forum description here…")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(BuildScoutTheme.faint)
                            .padding(18)
                            .allowsHitTesting(false)
                    }
                }

                HStack {
                    Label(
                        "Year • make • price • gearbox • drivetrain • running status • URL • risks • drift hardware",
                        systemImage: "sparkles"
                    )
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.faint)

                    Spacer()

                    Button {
                        draft = ListingImportParser.parse(rawText)
                        parsed = true
                    } label: {
                        Label("PARSE LISTING", systemImage: "bolt.fill")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var parserLegend: some View {
        ScoutPanel {
            HStack(alignment: .top, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(BuildScoutTheme.accent.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(BuildScoutTheme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ScoutEyebrow(text: "Parser")
                    Text("Designed for ugly real-world ads")
                        .font(.system(size: 14, weight: .bold))
                    Text("It extracts obvious structured clues, then deliberately makes you review them. A seller's description is a lead, not a mechanical inspection.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                }
                Spacer()
            }
        }
    }
}

private struct DraftEditor: View {
    @Binding var draft: ListingDraft
    let save: () -> Void

    var body: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScoutEyebrow(text: "Review parsed candidate")
                    Spacer()
                    Text("EDIT BEFORE SAVING")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.9)
                        .foregroundStyle(BuildScoutTheme.faint)
                }

                field("TITLE") {
                    TextField("Title", text: $draft.title)
                }

                HStack(spacing: 12) {
                    field("YEAR") {
                        TextField("Year", value: $draft.year, format: .number)
                    }
                    field("MAKE") {
                        TextField("Make", text: $draft.make)
                    }
                    field("MODEL") {
                        TextField("Model", text: $draft.model)
                    }
                }

                HStack(spacing: 12) {
                    field("PRICE") {
                        TextField("Price", value: $draft.price, format: .number)
                    }
                    field("LOCATION") {
                        TextField("Location", text: $draft.location)
                    }
                    field("SOURCE") {
                        TextField("Source", text: $draft.source)
                    }
                }

                HStack(spacing: 14) {
                    Picker("Drive", selection: $draft.drivetrain) {
                        ForEach(Drivetrain.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Gearbox", selection: $draft.transmission) {
                        ForEach(TransmissionType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Toggle("Runs", isOn: $draft.runs)
                    Toggle("Tow required", isOn: $draft.towRequired)
                    Spacer()
                }

                if !draft.strengths.isEmpty || !draft.riskTags.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        if !draft.strengths.isEmpty {
                            detectedPanel(
                                title: "STRENGTHS",
                                icon: "checkmark.circle.fill",
                                color: BuildScoutTheme.success,
                                values: draft.strengths
                            )
                        }
                        if !draft.riskTags.isEmpty {
                            detectedPanel(
                                title: "RISKS",
                                icon: "exclamationmark.triangle.fill",
                                color: BuildScoutTheme.warning,
                                values: draft.riskTags
                            )
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button(action: save) {
                        Label("ADD CANDIDATE", systemImage: "plus.circle.fill")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.title.isEmpty || draft.price < 0)
                }
            }
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(BuildScoutTheme.faint)

            content()
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .frame(height: 36)
                .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(BuildScoutTheme.border))
        }
        .frame(maxWidth: .infinity)
    }

    private func detectedPanel(
        title: String,
        icon: String,
        color: Color,
        values: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(color)

            Text(values.joined(separator: " • "))
                .font(.caption)
                .foregroundStyle(BuildScoutTheme.muted)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }
}
