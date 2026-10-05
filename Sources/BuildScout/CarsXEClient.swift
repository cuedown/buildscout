import Foundation

struct CarsXEFact: Identifiable, Sendable {
    let id = UUID()
    let key: String
    let value: String
}

struct CarsXEReport: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let endpoint: String
    let facts: [CarsXEFact]
    let rawJSON: String

    var hasFacts: Bool { !facts.isEmpty }
}

enum CarsXEClient {
    static func vehicleBundle(
        vin: String,
        apiKey: String,
        mileageKM: Double? = nil
    ) async -> [CarsXEReport] {
        await withTaskGroup(of: CarsXEReport?.self) { group in
            group.addTask {
                try? await report(
                    name: "Specifications",
                    path: "/specs",
                    query: [
                        .init(name: "vin", value: vin),
                        .init(name: "deepdata", value: "1")
                    ],
                    apiKey: apiKey,
                    interestingKeys: [
                        "year", "make", "model", "trim", "style", "engine",
                        "transmission", "drivetrain", "horsepower", "torque",
                        "curb_weight", "wheelbase", "doors"
                    ]
                )
            }

            group.addTask {
                var query = [URLQueryItem(name: "vin", value: vin)]
                if let mileageKM {
                    query.append(.init(name: "mileage", value: String(Int(mileageKM))))
                    query.append(.init(name: "condition", value: "average"))
                }
                return try? await report(
                    name: "Market Value",
                    path: "/v2/marketvalue",
                    query: query,
                    apiKey: apiKey,
                    interestingKeys: [
                        "retail", "wholesale", "trade", "auction", "adjusted",
                        "average", "clean", "rough", "excellent", "xclean",
                        "msrp", "mileage", "condition"
                    ]
                )
            }

            group.addTask {
                try? await report(
                    name: "Vehicle History",
                    path: "/history",
                    query: [.init(name: "vin", value: vin)],
                    apiKey: apiKey,
                    interestingKeys: [
                        "title", "brand", "salvage", "junk", "insurance",
                        "odometer", "accident", "damage", "event", "record"
                    ]
                )
            }

            group.addTask {
                try? await report(
                    name: "Open Recalls",
                    path: "/v1/recalls",
                    query: [.init(name: "vin", value: vin)],
                    apiKey: apiKey,
                    interestingKeys: [
                        "recall", "campaign", "component", "remedy", "risk",
                        "open", "status", "manufacturer"
                    ]
                )
            }

            group.addTask {
                try? await report(
                    name: "Lien & Theft",
                    path: "/v1/lien-theft",
                    query: [.init(name: "vin", value: vin)],
                    apiKey: apiKey,
                    interestingKeys: [
                        "lien", "theft", "stolen", "record", "status", "date"
                    ]
                )
            }

            var reports: [CarsXEReport] = []
            for await result in group {
                if let result { reports.append(result) }
            }
            return reports.sorted { $0.name < $1.name }
        }
    }

    private static func report(
        name: String,
        path: String,
        query: [URLQueryItem],
        apiKey: String,
        interestingKeys: Set<String>
    ) async throws -> CarsXEReport {
        var components = URLComponents(string: "https://api.carsxe.com\(path)")!
        components.queryItems = query + [.init(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("BuildScout/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let object = try JSONSerialization.jsonObject(with: data)
        let flattened = flatten(object)
        let facts = flattened
            .filter { path, value in
                let lower = path.lowercased()
                return interestingKeys.contains(where: { lower.contains($0) }) &&
                    !value.isEmpty &&
                    value.lowercased() != "null"
            }
            .sorted { $0.key < $1.key }
            .prefix(35)
            .map { CarsXEFact(key: prettyKey($0.key), value: $0.value) }

        let pretty = (try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""

        return CarsXEReport(
            name: name,
            endpoint: path,
            facts: facts,
            rawJSON: pretty
        )
    }

    private static func flatten(
        _ object: Any,
        prefix: String = ""
    ) -> [String: String] {
        var output: [String: String] = [:]

        if let dict = object as? [String: Any] {
            for (key, value) in dict {
                let next = prefix.isEmpty ? key : "\(prefix).\(key)"
                output.merge(flatten(value, prefix: next)) { _, new in new }
            }
        } else if let array = object as? [Any] {
            for (index, value) in array.prefix(20).enumerated() {
                output.merge(flatten(value, prefix: "\(prefix)[\(index)]")) { _, new in new }
            }
        } else if let number = object as? NSNumber {
            output[prefix] = number.stringValue
        } else if let string = object as? String {
            output[prefix] = string
        } else {
            output[prefix] = String(describing: object)
        }

        return output
    }

    private static func prettyKey(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: ".", with: " › ")
    }
}
