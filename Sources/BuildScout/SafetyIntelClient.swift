import Foundation

struct SafetyIntel: Sendable {
    var recalls: [NHTSARecall] = []
    var complaints: [NHTSAComplaint] = []
    var ratings: [NHTSARatingSummary] = []
}

struct NHTSARecall: Decodable, Identifiable, Sendable {
    var id: String { NHTSACampaignNumber ?? UUID().uuidString }

    let Manufacturer: String?
    let NHTSACampaignNumber: String?
    let ReportReceivedDate: String?
    let Component: String?
    let Summary: String?
    let Consequence: String?
    let Remedy: String?
    let ModelYear: String?
    let Make: String?
    let Model: String?
}

private struct NHTSARecallResponse: Decodable {
    let results: [NHTSARecall]?
}

struct NHTSAComplaint: Decodable, Identifiable, Sendable {
    var id: String { String(odiNumber ?? 0) }

    let odiNumber: Int?
    let manufacturer: String?
    let crash: Bool?
    let fire: Bool?
    let numberOfInjuries: Int?
    let numberOfDeaths: Int?
    let dateOfIncident: String?
    let components: String?
    let summary: String?
    let products: [NHTSAComplaintProduct]?
}

struct NHTSAComplaintProduct: Decodable, Sendable {
    let type: String?
    let productYear: String?
    let productMake: String?
    let productModel: String?
}

private struct NHTSAComplaintResponse: Decodable {
    let results: [NHTSAComplaint]?
}

struct NHTSARatingSummary: Decodable, Identifiable, Sendable {
    var id: String { VehicleId ?? VehicleDescription ?? UUID().uuidString }
    let VehicleId: String?
    let VehicleDescription: String?
}

private struct NHTSARatingResponse: Decodable {
    let Results: [NHTSARatingSummary]?
}

enum SafetyIntelClient {
    static func fetch(year: Int, make: String, model: String) async -> SafetyIntel {
        async let recalls = recalls(year: year, make: make, model: model)
        async let complaints = complaints(year: year, make: make, model: model)
        async let ratings = ratings(year: year, make: make, model: model)

        return await SafetyIntel(
            recalls: (try? recalls) ?? [],
            complaints: (try? complaints) ?? [],
            ratings: (try? ratings) ?? []
        )
    }

    static func recalls(year: Int, make: String, model: String) async throws -> [NHTSARecall] {
        var c = URLComponents(string: "https://api.nhtsa.gov/recalls/recallsByVehicle")!
        c.queryItems = [
            .init(name: "make", value: make),
            .init(name: "model", value: model),
            .init(name: "modelYear", value: String(year))
        ]
        let data = try await load(c.url!)
        return try JSONDecoder().decode(NHTSARecallResponse.self, from: data).results ?? []
    }

    static func complaints(year: Int, make: String, model: String) async throws -> [NHTSAComplaint] {
        var c = URLComponents(string: "https://api.nhtsa.gov/complaints/complaintsByVehicle")!
        c.queryItems = [
            .init(name: "make", value: make),
            .init(name: "model", value: model),
            .init(name: "modelYear", value: String(year))
        ]
        let data = try await load(c.url!)
        return try JSONDecoder().decode(NHTSAComplaintResponse.self, from: data).results ?? []
    }

    static func ratings(year: Int, make: String, model: String) async throws -> [NHTSARatingSummary] {
        let encodedMake = make.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? make
        let encodedModel = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model
        let url = URL(string: "https://api.nhtsa.gov/SafetyRatings/modelyear/\(year)/make/\(encodedMake)/model/\(encodedModel)?format=json")!
        let data = try await load(url)
        return try JSONDecoder().decode(NHTSARatingResponse.self, from: data).Results ?? []
    }

    private static func load(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("BuildScout/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
