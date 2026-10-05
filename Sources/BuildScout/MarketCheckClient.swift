import Foundation

private struct MarketCheckSearchResponse: Decodable {
    let num_found: Int?
    let listings: [MarketCheckListing]?
}

private struct MarketCheckListing: Decodable {
    let id: String?
    let vin: String?
    let alternate_vin: String?
    let heading: String?
    let price: Double?
    let miles: Double?
    let vdp_url: String?
    let seller_type: String?
    let source: String?
    let build: MarketCheckBuild?
    let dealer: MarketCheckDealer?
    let mc_dealership: MarketCheckDealer?
}

private struct MarketCheckBuild: Decodable {
    let year: Int?
    let make: String?
    let model: String?
    let trim: String?
    let body_type: String?
    let transmission: String?
    let drivetrain: String?
    let fuel_type: String?
    let engine: String?
    let cylinders: Int?
}

private struct MarketCheckDealer: Decodable {
    let name: String?
    let city: String?
    let state: String?
    let country: String?
    let website: String?
}

enum MarketCheckClient {
    static func searchInventory(
        apiKey: String,
        mission: MissionType,
        maximumPrice: Double,
        region: String
    ) async throws -> [HuntResult] {
        let geo = canadianRegion(region)

        async let dealer = search(
            endpoint: "https://api.marketcheck.com/v2/search/car/active",
            apiKey: apiKey,
            mission: mission,
            maximumPrice: maximumPrice,
            city: geo.city,
            province: geo.province,
            provider: "MarketCheck • Active"
        )

        async let privateParty = search(
            endpoint: "https://api.marketcheck.com/v2/search/car/fsbo/active",
            apiKey: apiKey,
            mission: mission,
            maximumPrice: maximumPrice,
            city: geo.city,
            province: geo.province,
            provider: "MarketCheck • Private"
        )

        return try await dedupe(dealer + privateParty)
    }

    static func comparables(
        apiKey: String,
        listing: VehicleListing,
        region: String,
        rows: Int = 30
    ) async throws -> [HuntResult] {
        let geo = canadianRegion(region)
        var components = URLComponents(string: "https://api.marketcheck.com/v2/search/car/active")!
        var query: [URLQueryItem] = [
            .init(name: "api_key", value: apiKey),
            .init(name: "country", value: "ca"),
            .init(name: "car_type", value: "used"),
            .init(name: "rows", value: String(min(max(rows, 1), 50))),
            .init(name: "sort_by", value: "price"),
            .init(name: "sort_order", value: "asc"),
            .init(name: "make", value: listing.make),
            .init(name: "model", value: cleanedModel(listing.model)),
            .init(name: "year_range", value: "\(max(listing.year - 2, 1980))-\(listing.year + 2)")
        ]
        if !geo.province.isEmpty { query.append(.init(name: "state", value: geo.province)) }
        if !geo.city.isEmpty { query.append(.init(name: "city", value: geo.city)) }
        components.queryItems = query

        return try await request(
            components.url!,
            provider: "MarketCheck • Comps",
            kind: .vehicle
        )
    }

    private static func search(
        endpoint: String,
        apiKey: String,
        mission: MissionType,
        maximumPrice: Double,
        city: String,
        province: String,
        provider: String
    ) async throws -> [HuntResult] {
        var components = URLComponents(string: endpoint)!
        var query: [URLQueryItem] = [
            .init(name: "api_key", value: apiKey),
            .init(name: "country", value: "ca"),
            .init(name: "car_type", value: "used"),
            .init(name: "price_range", value: "0-\(Int(maximumPrice))"),
            .init(name: "rows", value: "50"),
            .init(name: "sort_by", value: "price"),
            .init(name: "sort_order", value: "asc"),
            .init(name: "include_non_vin_listings", value: "true")
        ]

        if !province.isEmpty { query.append(.init(name: "state", value: province)) }
        if !city.isEmpty { query.append(.init(name: "city", value: city)) }

        switch mission {
        case .drift:
            query.append(.init(name: "drivetrain", value: "RWD"))
        case .overland, .winter:
            query.append(.init(name: "drivetrain", value: "AWD,4WD"))
        case .rally:
            query.append(.init(name: "drivetrain", value: "AWD,4WD,RWD"))
        case .camper:
            query.append(.init(name: "body_type", value: "SUV,Wagon,Van,Minivan"))
        case .track, .custom:
            break
        }

        components.queryItems = query
        return try await request(
            components.url!,
            provider: provider,
            kind: provider.contains("Auction") ? .auction : .vehicle
        )
    }

    private static func request(
        _ url: URL,
        provider: String,
        kind: HuntResultKind
    ) async throws -> [HuntResult] {
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("BuildScout/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(MarketCheckSearchResponse.self, from: data)
        return (decoded.listings ?? []).map { listing in
            let build = listing.build
            let dealer = listing.dealer ?? listing.mc_dealership
            let title = listing.heading
                ?? [build?.year.map(String.init), build?.make, build?.model, build?.trim]
                    .compactMap { $0 }
                    .joined(separator: " ")

            let location = [dealer?.city, dealer?.state]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")

            let details: [String?] = [
                build?.drivetrain,
                build?.transmission,
                listing.miles.map { "\(Int($0)) mi" },
                listing.seller_type,
                listing.source
            ]

            return HuntResult(
                provider: provider,
                kind: kind,
                title: title.isEmpty ? "Vehicle listing" : title,
                url: listing.vdp_url ?? dealer?.website ?? "",
                snippet: details.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " • "),
                price: listing.price,
                currency: "CAD",
                location: location.isEmpty ? nil : location,
                thumbnailURL: nil,
                sourceDomain: listing.source,
                vin: listing.vin ?? listing.alternate_vin,
                odometerKM: listing.miles.map { $0 * 1.609344 },
                drivetrain: parseDrivetrain(build?.drivetrain),
                transmission: parseTransmission(build?.transmission)
            )
        }
    }

    private static func canadianRegion(_ raw: String) -> (city: String, province: String) {
        let pieces = raw.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let city = pieces.first ?? ""
        let provinceText = pieces.dropFirst().first ?? ""

        let map: [String: String] = [
            "alberta": "AB", "ab": "AB",
            "british columbia": "BC", "bc": "BC",
            "saskatchewan": "SK", "sk": "SK",
            "manitoba": "MB", "mb": "MB",
            "ontario": "ON", "on": "ON",
            "quebec": "QC", "qc": "QC",
            "new brunswick": "NB", "nb": "NB",
            "nova scotia": "NS", "ns": "NS",
            "prince edward island": "PE", "pe": "PE",
            "newfoundland and labrador": "NL", "nl": "NL",
            "yukon": "YT", "yt": "YT",
            "northwest territories": "NT", "nt": "NT",
            "nunavut": "NU", "nu": "NU"
        ]

        return (city, map[provinceText.lowercased()] ?? provinceText.uppercased())
    }

    private static func parseDrivetrain(_ raw: String?) -> Drivetrain {
        let lower = raw?.lowercased() ?? ""
        if lower.contains("rear") || lower == "rwd" { return .rwd }
        if lower.contains("all") || lower == "awd" { return .awd }
        if lower.contains("4wd") || lower.contains("four") || lower == "4x4" { return .fourWD }
        if lower.contains("front") || lower == "fwd" { return .fwd }
        return .unknown
    }

    private static func parseTransmission(_ raw: String?) -> TransmissionType {
        let lower = raw?.lowercased() ?? ""
        if lower.contains("manual") { return .manual }
        if lower.contains("automatic") || lower.contains("cvt") { return .automatic }
        return .unknown
    }

    private static func cleanedModel(_ model: String) -> String {
        model
            .replacingOccurrences(of: #"\b(E30|E36|E46|E90|E91|E92|Z33|V35|BK1|BK2)\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func dedupe(_ results: [HuntResult]) -> [HuntResult] {
        var seen = Set<String>()
        return results.filter {
            let key = $0.url.isEmpty ? $0.title.lowercased() : $0.url
            return seen.insert(key).inserted
        }
    }
}
