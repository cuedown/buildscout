import Foundation

struct ListingDraft {
    var source = "Manual import"
    var title = ""
    var year = Calendar.current.component(.year, from: Date())
    var make = ""
    var model = ""
    var price: Double = 0
    var location = ""
    var drivetrain: Drivetrain = .unknown
    var transmission: TransmissionType = .unknown
    var runs = true
    var towRequired = false
    var horsepower: Int?
    var notes = ""
    var url: String?
    var riskTags: [String] = []
    var strengths: [String] = []

    func makeListing() -> VehicleListing {
        VehicleListing(
            source: source,
            title: title.isEmpty ? "\(year) \(make) \(model)".trimmingCharacters(in: .whitespaces) : title,
            year: year,
            make: make,
            model: model,
            price: price,
            location: location,
            drivetrain: drivetrain,
            transmission: transmission,
            runs: runs,
            towRequired: towRequired,
            horsepower: horsepower,
            notes: notes,
            url: url,
            riskTags: riskTags,
            strengths: strengths
        )
    }
}

enum ListingImportParser {
    static let knownMakes = [
        "BMW", "Nissan", "Infiniti", "Ford", "Mazda", "Toyota", "Lexus",
        "Volvo", "Subaru", "Hyundai", "Chevrolet", "Datsun", "Mercedes-Benz",
        "Mercedes", "Honda", "Acura", "Audi", "Volkswagen", "Jeep", "Suzuki"
    ]

    static func parse(_ raw: String) -> ListingDraft {
        let text = raw.replacingOccurrences(of: "\r", with: "")
        var draft = ListingDraft()
        draft.notes = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = firstMatch(in: text, pattern: #"https?://[^\s]+"#) {
            draft.url = url
        }

        if let yearText = firstMatch(in: text, pattern: #"\b(19[7-9]\d|20[0-2]\d)\b"#),
           let year = Int(yearText) {
            draft.year = year
        }

        for make in knownMakes {
            if text.range(of: make, options: [.caseInsensitive]) != nil {
                draft.make = make
                break
            }
        }

        if let priceText = firstMatch(in: text, pattern: #"(?:CA\$|CAD\s*\$?|\$)\s*([0-9]{2,6}(?:,[0-9]{3})*(?:\.\d{1,2})?)"#, capture: 1) {
            draft.price = Double(priceText.replacingOccurrences(of: ",", with: "")) ?? 0
        }

        let lower = text.lowercased()
        draft.transmission = inferTransmission(lower)
        draft.drivetrain = inferDrivetrain(lower)

        let nonRunnerPhrases = ["does not run", "doesn't run", "non running", "non-running", "no engine", "blown engine", "needs engine", "crank no start", "cranks no start"]
        if nonRunnerPhrases.contains(where: lower.contains) {
            draft.runs = false
        }

        let towPhrases = ["tow away", "needs to be towed", "will need to be towed", "tow required", "no engine"]
        draft.towRequired = towPhrases.contains(where: lower.contains)

        if lower.contains("welded diff") { draft.strengths.append("Welded diff") }
        if lower.contains("limited slip") || lower.contains("lsd") { draft.strengths.append("LSD") }
        if lower.contains("angle kit") { draft.strengths.append("Angle kit") }
        if lower.contains("roll cage") || lower.contains("full cage") { draft.strengths.append("Cage") }
        if lower.contains("hydro") || lower.contains("hydraulic handbrake") { draft.strengths.append("Hydraulic handbrake") }

        let riskMap: [(String, String)] = [
            ("rust", "Rust inspection required"),
            ("overheat", "Cooling / overheating history"),
            ("misfire", "Misfire"),
            ("leak", "Fluid leak"),
            ("rebuilt title", "Rebuilt title"),
            ("salvage", "Salvage history"),
            ("no engine", "No engine"),
            ("blown engine", "Engine failure"),
            ("transmission", "Transmission condition requires verification")
        ]
        for (needle, label) in riskMap where lower.contains(needle) {
            if !draft.riskTags.contains(label) { draft.riskTags.append(label) }
        }

        let firstLine = text.split(separator: "\n").first.map(String.init) ?? ""
        draft.title = firstLine.count <= 100 ? firstLine : String(firstLine.prefix(100))

        if !draft.make.isEmpty, let makeRange = firstLine.range(of: draft.make, options: [.caseInsensitive]) {
            let afterMake = firstLine[makeRange.upperBound...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let cleaned = afterMake
                .replacingOccurrences(of: #"\$.*$"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                draft.model = cleaned
            }
        }

        return draft
    }

    static func decodeFile(url: URL) throws -> [VehicleListing] {
        let gotAccess = url.startAccessingSecurityScopedResource()
        defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let ext = url.pathExtension.lowercased()

        if ext == "json" {
            if let many = try? JSONDecoder().decode([VehicleListing].self, from: data) {
                return many
            }
            return [try JSONDecoder().decode(VehicleListing.self, from: data)]
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw ImportError.unreadableFile
        }
        return try decodeCSV(text)
    }

    static func decodeCSV(_ text: String) throws -> [VehicleListing] {
        let rows = text.split(whereSeparator: \.isNewline).map(String.init)
        guard let headerRow = rows.first else { return [] }
        let headers = csvCells(headerRow).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        func value(_ cells: [String], _ name: String) -> String {
            guard let index = headers.firstIndex(of: name), index < cells.count else { return "" }
            return cells[index]
        }

        return rows.dropFirst().compactMap { row in
            let cells = csvCells(row)
            let title = value(cells, "title")
            if title.isEmpty { return nil }

            let year = Int(value(cells, "year")) ?? Calendar.current.component(.year, from: Date())
            let price = Double(value(cells, "price").replacingOccurrences(of: ",", with: "")) ?? 0
            let drivetrain = Drivetrain(rawValue: value(cells, "drivetrain").uppercased()) ?? .unknown
            let transmissionText = value(cells, "transmission").lowercased()
            let transmission: TransmissionType = transmissionText.contains("manual") ? .manual :
                transmissionText.contains("auto") ? .automatic : .unknown

            return VehicleListing(
                source: value(cells, "source").isEmpty ? "CSV import" : value(cells, "source"),
                title: title,
                year: year,
                make: value(cells, "make"),
                model: value(cells, "model"),
                price: price,
                location: value(cells, "location"),
                drivetrain: drivetrain,
                transmission: transmission,
                runs: value(cells, "runs").lowercased() != "false",
                towRequired: value(cells, "towrequired").lowercased() == "true",
                horsepower: Int(value(cells, "horsepower")),
                notes: value(cells, "notes"),
                url: value(cells, "url").isEmpty ? nil : value(cells, "url")
            )
        }
    }

    private static func csvCells(_ row: String) -> [String] {
        var cells: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = row.makeIterator()

        while let char = iterator.next() {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                cells.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        cells.append(current)
        return cells.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private static func inferTransmission(_ lower: String) -> TransmissionType {
        if lower.contains("6 speed manual") || lower.contains("6-speed manual") ||
            lower.contains("5 speed manual") || lower.contains("5-speed manual") ||
            lower.contains(" manual ") || lower.hasSuffix(" manual") {
            return .manual
        }
        if lower.contains("automatic") || lower.contains(" auto ") {
            return .automatic
        }
        if lower.contains("no transmission") || lower.contains("missing transmission") {
            return .none
        }
        return .unknown
    }

    private static func inferDrivetrain(_ lower: String) -> Drivetrain {
        if lower.contains("rwd") || lower.contains("rear wheel drive") || lower.contains("rear-wheel drive") { return .rwd }
        if lower.contains("awd") || lower.contains("all wheel drive") || lower.contains("all-wheel drive") { return .awd }
        if lower.contains("4wd") || lower.contains("4x4") { return .fourWD }
        if lower.contains("fwd") || lower.contains("front wheel drive") || lower.contains("front-wheel drive") { return .fwd }
        return .unknown
    }

    private static func firstMatch(in text: String, pattern: String, capture: Int = 0) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              capture < match.numberOfRanges,
              let swiftRange = Range(match.range(at: capture), in: text) else { return nil }
        return String(text[swiftRange])
    }

    enum ImportError: Error {
        case unreadableFile
    }
}
