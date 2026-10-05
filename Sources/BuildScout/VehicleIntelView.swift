import SwiftUI

struct VehicleIntelView: View {
    @EnvironmentObject private var store: ListingStore

    @State private var vin = ""
    @State private var decoded: VINDecodeResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var addedMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vehicle Intel").font(.largeTitle.bold())
                    Text("Decode a VIN into structured vehicle facts before you start pricing the build.")
                        .foregroundStyle(.secondary)
                }

                GroupBox("VIN decoder") {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            TextField("VIN", text: $vin)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .textCase(.uppercase)

                            Button {
                                decode()
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Label("Decode", systemImage: "barcode.viewfinder")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(vin.trimmingCharacters(in: .whitespacesAndNewlines).count < 5 || isLoading)
                        }

                        Text("Uses the public NHTSA vPIC API. Full 17-character VINs give the best result; partial VIN decoding is also supported by the service.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(8)
                }

                if let decoded {
                    VINResultCard(result: decoded)

                    HStack {
                        if let addedMessage {
                            Text(addedMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            let listing = decoded.asListing()
                            store.addListing(listing)
                            addedMessage = "Added to Candidates. Set its asking price and location there."
                        } label: {
                            Label("Add to Candidates", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                GroupBox("Why this matters") {
                    Text("The eventual goal is to combine decoded identity with platform knowledge, recalls/spec data, live listings, donor compatibility, and build costs. VIN decoding gives BuildScout a trustworthy starting identity instead of guessing from an ad title.")
                        .padding(8)
                }
            }
            .padding(28)
        }
    }

    private func decode() {
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
}

private struct VINResultCard: View {
    let result: VINDecodeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text([result.ModelYear, result.Make.capitalized, result.Model, result.Trim]
                        .filter { !$0.isEmpty }
                        .joined(separator: " "))
                        .font(.title2.bold())

                    Text(result.VIN)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(
                    result.decodedCleanly ? "Decoded" : "Check result",
                    systemImage: result.decodedCleanly ? "checkmark.seal.fill" : "exclamationmark.triangle"
                )
                .foregroundStyle(result.decodedCleanly ? .green : .orange)
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
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
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
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption2.bold()).foregroundStyle(.secondary)
            Text(value.isEmpty ? "Unknown" : value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
