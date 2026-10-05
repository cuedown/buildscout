import Foundation

struct VINDecodeResponse: Codable, Sendable {
    let Results: [VINDecodeResult]
}

struct VINDecodeResult: Codable, Sendable, Identifiable {
    var id: String { VIN }

    let VIN: String
    let ModelYear: String
    let Make: String
    let Model: String
    let Trim: String
    let BodyClass: String
    let DriveType: String
    let TransmissionStyle: String
    let TransmissionSpeeds: String
    let EngineCylinders: String
    let DisplacementL: String
    let EngineHP: String
    let FuelTypePrimary: String
    let PlantCountry: String
    let ErrorCode: String
    let ErrorText: String

    var decodedCleanly: Bool {
        ErrorCode == "0" || ErrorCode.split(separator: ",").allSatisfy { $0.trimmingCharacters(in: .whitespaces) == "0" }
    }

    var drivetrain: Drivetrain {
        let lower = DriveType.lowercased()
        if lower.contains("rear") { return .rwd }
        if lower.contains("all") { return .awd }
        if lower.contains("4wd") || lower.contains("four") { return .fourWD }
        if lower.contains("front") { return .fwd }
        return .unknown
    }

    var transmission: TransmissionType {
        let lower = TransmissionStyle.lowercased()
        if lower.contains("manual") { return .manual }
        if lower.contains("automatic") || lower.contains("cvt") { return .automatic }
        return .unknown
    }

    func asListing() -> VehicleListing {
        let year = Int(ModelYear) ?? Calendar.current.component(.year, from: Date())
        let titleParts = [ModelYear, Make.capitalized, Model, Trim]
            .filter { !$0.isEmpty }

        return VehicleListing(
            source: "NHTSA vPIC VIN decode",
            title: titleParts.joined(separator: " "),
            year: year,
            make: Make.capitalized,
            model: Model,
            price: 0,
            location: "",
            drivetrain: drivetrain,
            transmission: transmission,
            runs: true,
            towRequired: false,
            horsepower: Int(EngineHP),
            notes: [
                BodyClass,
                engineDescription,
                FuelTypePrimary.isEmpty ? nil : FuelTypePrimary,
                PlantCountry.isEmpty ? nil : "Built in \(PlantCountry)"
            ].compactMap { $0 }.joined(separator: " • "),
            url: nil
        )
    }

    var engineDescription: String? {
        var pieces: [String] = []
        if !DisplacementL.isEmpty { pieces.append("\(DisplacementL)L") }
        if !EngineCylinders.isEmpty { pieces.append("\(EngineCylinders)-cyl") }
        if !EngineHP.isEmpty { pieces.append("\(EngineHP) hp") }
        return pieces.isEmpty ? nil : pieces.joined(separator: " ")
    }
}

struct CanadianSpecResponse: Codable, Sendable {
    let Results: [CanadianSpecResult]
}

struct CanadianSpecItem: Codable, Sendable {
    let Name: String
    let Value: String
}

struct CanadianSpecResult: Codable, Sendable, Identifiable {
    let Specs: [CanadianSpecItem]

    var values: [String: String] {
        Dictionary(uniqueKeysWithValues: Specs.map { ($0.Name, $0.Value) })
    }

    var id: String {
        "\(values["Make"] ?? "")-\(values["Model"] ?? "")-\(values["MYR"] ?? "")"
    }

    var make: String { values["Make"] ?? "" }
    var model: String { values["Model"] ?? "" }
    var overallLengthCM: String { values["OL"] ?? "" }
    var overallWidthCM: String { values["OW"] ?? "" }
    var overallHeightCM: String { values["OH"] ?? "" }
    var wheelbaseCM: String { values["WB"] ?? "" }
    var curbWeightKG: String { values["CW"] ?? "" }
    var frontTrackCM: String { values["TWF"] ?? "" }
    var rearTrackCM: String { values["TWR"] ?? "" }
    var weightDistribution: String { values["WD"] ?? "" }
}

enum VPICClient {
    static func decode(vin: String) async throws -> VINDecodeResult {
        let cleaned = vin
            .uppercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "*" }

        guard cleaned.count >= 5 else {
            throw VPICError.invalidVIN
        }

        guard let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/\(encoded)?format=json") else {
            throw VPICError.invalidVIN
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("BuildScout/0.1 (open-source vehicle planning app)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw VPICError.serverError
        }

        let decoded = try JSONDecoder().decode(VINDecodeResponse.self, from: data)
        guard let result = decoded.Results.first else {
            throw VPICError.noResult
        }
        return result
    }

    static func canadianSpecs(year: Int, make: String) async throws -> [CanadianSpecResult] {
        var components = URLComponents(string: "https://vpic.nhtsa.dot.gov/api/vehicles/GetCanadianVehicleSpecifications/")!
        components.queryItems = [
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "make", value: make),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else { throw VPICError.serverError }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("BuildScout/0.1 (open-source vehicle planning app)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw VPICError.serverError
        }

        return try JSONDecoder().decode(CanadianSpecResponse.self, from: data).Results
    }

    enum VPICError: LocalizedError {
        case invalidVIN
        case serverError
        case noResult

        var errorDescription: String? {
            switch self {
            case .invalidVIN: return "Enter at least 5 VIN characters."
            case .serverError: return "The VIN service returned an error."
            case .noResult: return "No VIN decode was returned."
            }
        }
    }
}
