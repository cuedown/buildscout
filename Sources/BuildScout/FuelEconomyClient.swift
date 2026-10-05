import Foundation

struct FuelEconomyVehicle: Identifiable, Sendable {
    var id: String
    var year: Int
    var make: String
    var model: String
    var transmission: String
    var drive: String
    var cylinders: String
    var displacementL: String
    var fuelType: String
    var cityMPG: String
    var highwayMPG: String
    var combinedMPG: String
    var co2TailpipeGPM: String
    var barrelsPerYear: String
}

private struct FuelMenuItem: Sendable {
    var text: String
    var value: String
}

enum FuelEconomyClient {
    static func lookup(year: Int, make: String, model: String) async throws -> [FuelEconomyVehicle] {
        let models = try await menu(
            path: "vehicle/menu/model",
            query: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "make", value: make)
            ]
        )

        let normalizedNeedle = normalizeModel(model)
        let rankedModels = models.sorted {
            modelMatchScore($0.text, needle: normalizedNeedle) >
            modelMatchScore($1.text, needle: normalizedNeedle)
        }

        var optionItems: [FuelMenuItem] = []

        for modelItem in rankedModels.prefix(3) where modelMatchScore(modelItem.text, needle: normalizedNeedle) > 0 {
            let options = try await menu(
                path: "vehicle/menu/options",
                query: [
                    URLQueryItem(name: "year", value: String(year)),
                    URLQueryItem(name: "make", value: make),
                    URLQueryItem(name: "model", value: modelItem.value)
                ]
            )
            optionItems.append(contentsOf: options)
        }

        var vehicles: [FuelEconomyVehicle] = []
        for option in optionItems.prefix(6) {
            if let vehicle = try? await vehicle(id: option.value) {
                vehicles.append(vehicle)
            }
        }

        return vehicles
    }

    private static func menu(path: String, query: [URLQueryItem]) async throws -> [FuelMenuItem] {
        var components = URLComponents(string: "https://www.fueleconomy.gov/ws/rest/\(path)")!
        components.queryItems = query

        let data = try await load(components.url!)
        let parser = FuelMenuParser()
        return try parser.parse(data)
    }

    private static func vehicle(id: String) async throws -> FuelEconomyVehicle {
        let url = URL(string: "https://www.fueleconomy.gov/ws/rest/vehicle/\(id)")!
        let data = try await load(url)
        let parser = FuelVehicleParser()
        let values = try parser.parse(data)

        return FuelEconomyVehicle(
            id: values["id"] ?? id,
            year: Int(values["year"] ?? "") ?? 0,
            make: values["make"] ?? "",
            model: values["model"] ?? "",
            transmission: values["trany"] ?? "",
            drive: values["drive"] ?? "",
            cylinders: values["cylinders"] ?? "",
            displacementL: values["displ"] ?? "",
            fuelType: values["fuelType1"] ?? "",
            cityMPG: values["city08"] ?? "",
            highwayMPG: values["highway08"] ?? "",
            combinedMPG: values["comb08"] ?? "",
            co2TailpipeGPM: values["co2TailpipeGpm"] ?? "",
            barrelsPerYear: values["barrels08"] ?? ""
        )
    }

    private static func load(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/xml", forHTTPHeaderField: "Accept")
        request.setValue("BuildScout/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private static func normalizeModel(_ model: String) -> [String] {
        model
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { token in
                !["series", "sedan", "coupe", "wagon", "e90", "e46", "e36", "e30", "z33"].contains(token)
            }
    }

    private static func modelMatchScore(_ candidate: String, needle: [String]) -> Int {
        let lower = candidate.lowercased()
        return needle.reduce(0) { score, token in
            score + (lower.contains(token) ? 2 : 0)
        }
    }
}

private final class FuelMenuParser: NSObject, XMLParserDelegate {
    private var items: [FuelMenuItem] = []
    private var currentElement = ""
    private var currentText = ""
    private var currentValue = ""
    private var buffer = ""

    func parse(_ data: Data) throws -> [FuelMenuItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else {
            throw parser.parserError ?? URLError(.cannotParseResponse)
        }
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        buffer = ""
        if elementName == "menuItem" {
            currentText = ""
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if elementName == "text" { currentText = value }
        if elementName == "value" { currentValue = value }
        if elementName == "menuItem" {
            items.append(.init(text: currentText, value: currentValue))
        }
        buffer = ""
    }
}

private final class FuelVehicleParser: NSObject, XMLParserDelegate {
    private var values: [String: String] = [:]
    private var currentElement = ""
    private var buffer = ""

    func parse(_ data: Data) throws -> [String: String] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else {
            throw parser.parserError ?? URLError(.cannotParseResponse)
        }
        return values
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        buffer = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let wanted = Set([
            "id", "year", "make", "model", "trany", "drive", "cylinders",
            "displ", "fuelType1", "city08", "highway08", "comb08",
            "co2TailpipeGpm", "barrels08"
        ])
        if wanted.contains(elementName) {
            values[elementName] = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        buffer = ""
    }
}
