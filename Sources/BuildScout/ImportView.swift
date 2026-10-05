import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @EnvironmentObject private var store: ListingStore
    @State private var rawText = ""
    @State private var draft = ListingDraft()
    @State private var parsed = false
    @State private var showFileImporter = false
    @State private var importMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bring your own listing").font(.largeTitle.bold())
                    Text("Paste the ad exactly as you found it. BuildScout will pull out the useful bits, then you can correct anything before saving it.")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Import JSON / CSV") { showFileImporter = true }
                    Button("Parse pasted listing") {
                        draft = ListingImportParser.parse(rawText)
                        parsed = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let importMessage {
                        Text(importMessage).font(.caption).foregroundStyle(.secondary)
                    }
                }

                TextEditor(text: $rawText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 190)
                    .padding(8)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topLeading) {
                        if rawText.isEmpty {
                            Text("Paste a Marketplace, auction, Kijiji, forum, or private-sale description here…")
                                .foregroundStyle(.tertiary)
                                .padding(14)
                                .allowsHitTesting(false)
                        }
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

                GroupBox("What the parser recognizes") {
                    Text("Year, make, asking price, transmission, drivetrain, running/tow status, URL, and useful risk/build keywords such as welded diff, angle kit, cage, rust, misfire, leaks, and engine failure.")
                        .padding(8)
                }
            }
            .padding(28)
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
}

private struct DraftEditor: View {
    @Binding var draft: ListingDraft
    let save: () -> Void

    var body: some View {
        GroupBox("Review parsed candidate") {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Title", text: $draft.title)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    TextField("Year", value: $draft.year, format: .number)
                        .textFieldStyle(.roundedBorder)
                    TextField("Make", text: $draft.make)
                        .textFieldStyle(.roundedBorder)
                    TextField("Model", text: $draft.model)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    TextField("Price", value: $draft.price, format: .number)
                        .textFieldStyle(.roundedBorder)
                    TextField("Location", text: $draft.location)
                        .textFieldStyle(.roundedBorder)
                    TextField("Source", text: $draft.source)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Picker("Drive", selection: $draft.drivetrain) {
                        ForEach(Drivetrain.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Gearbox", selection: $draft.transmission) {
                        ForEach(TransmissionType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Toggle("Runs", isOn: $draft.runs)
                    Toggle("Tow required", isOn: $draft.towRequired)
                }

                if !draft.strengths.isEmpty {
                    Text("Detected strengths: \(draft.strengths.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !draft.riskTags.isEmpty {
                    Text("Detected risks: \(draft.riskTags.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Spacer()
                    Button("Add candidate", action: save)
                        .buttonStyle(.borderedProminent)
                        .disabled(draft.title.isEmpty || draft.price < 0)
                }
            }
            .padding(8)
        }
    }
}
