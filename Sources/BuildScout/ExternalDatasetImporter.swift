import Foundation

enum ExternalDatasetImporter {
    static func decodeJSON(_ data: Data, sourceName: String = "External JSON") throws -> [VehicleListing] {
        let object = try JSONSerialization.jsonObject(with: data)

        let rows: [[String: Any]]
        if let array = object as? [[String: Any]] {
            rows = array
        } else if let dict = object as? [String: Any],
                  let items = firstArray(dict, keys: ["items", "results", "listings", "data"]) {
            rows = items
        } else if let dict = object as? [String: Any] {
            rows = [dict]
        } else {
            throw ImportError.unsupportedShape
        }

        return rows.compactMap { vehicle(from: $0, fallbackSource: sourceName) }
    }

    static func decodeCSV(_ text: String, sourceName: String = "External CSV") -> [VehicleListing] {
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard let headerLine = lines.first else { return [] }

        let headers = csvCells(headerLine).map(normalizeKey)
        return lines.dropFirst().compactMap { line in
            let cells = csvCells(line)
            var row: [String: Any] = [:]
            for (index, header) in headers.enumerated() where index < cells.count {
                row[header] = cells[index]
            }
            return vehicle(from: row, fallbackSource: sourceName)
        }
    }

    static func vehicle(
        from row: [String: Any],
        fallbackSource: String
    ) -> VehicleListing? {
        let title = firstString(row, keys: [
            "title", "heading", "name", "vehicletitle", "titlename",
            "listingtitle", "adtitle"
        ]) ?? synthesizedTitle(row)

        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let description = firstString(row, keys: [
            "description", "snippet", "body", "details", "condition",
            "primarydamage", "summary"
        ]) ?? ""

        let make = firstString(row, keys: ["make", "vehiclemake"]) ?? ""
        let model = firstString(row, keys: ["model", "vehiclemodel"]) ?? ""
        let year = firstInt(row, keys: ["year", "modelyear", "vehicleyear"])
        let price = firstNumber(row, keys: [
            "price", "pricevalue", "priceamount", "amount",
            "currentbid", "buynowprice", "actualcashvalue", "acv"
        ])

        var parserText = title + "\n" + description
        if let year { parserText += "\n\(year)" }
        if !make.isEmpty { parserText += "\n\(make)" }
        if !model.isEmpty { parserText += "\n\(model)" }
        if let price { parserText += "\nCA$\(Int(price))" }

        if let transmission = firstString(row, keys: [
            "transmission", "transmissiontype", "gearbox"
        ]) {
            parserText += "\n\(transmission)"
        }

        if let drivetrain = firstString(row, keys: [
            "drivetrain", "drivetraintext", "drive", "drivetype"
        ]) {
            parserText += "\n\(drivetrain)"
        }

        if let vin = firstString(row, keys: ["vin", "vehiclevin"]) {
            parserText += "\nVIN \(vin)"
        }

        var draft = ListingImportParser.parse(parserText)
        draft.source = firstString(row, keys: [
            "source", "provider", "marketplace", "site"
        ]) ?? fallbackSource

        draft.title = title
        if let year { draft.year = year }
        if !make.isEmpty { draft.make = make }
        if !model.isEmpty { draft.model = model }
        if let price { draft.price = price }

        draft.location = firstString(row, keys: [
            "location", "locationtext", "city", "address",
            "neighborhood", "branch", "yard"
        ]) ?? ""

        draft.url = firstString(row, keys: [
            "url", "link", "listingurl", "listing_url", "adurl",
            "loturl", "itemurl", "vdpurl", "vdp_url"
        ])

        draft.vin = firstString(row, keys: ["vin", "vehiclevin"]) ?? draft.vin
        draft.odometerKM = normalizedOdometer(row) ?? draft.odometerKM

        if let running = firstBool(row, keys: [
            "runs", "running", "rundrive", "runanddrive", "run_and_drive"
        ]) {
            draft.runs = running
        }

        if let transmission = firstString(row, keys: [
            "transmission", "transmissiontype", "gearbox"
        ]) {
            draft.transmission = parseTransmission(transmission)
        }

        if let drivetrain = firstString(row, keys: [
            "drivetrain", "drivetraintext", "drive", "drivetype"
        ]) {
            draft.drivetrain = parseDrivetrain(drivetrain)
        }

        let noteParts = [
            description,
            firstString(row, keys: ["primarydamage", "secondarydamage"]),
            firstString(row, keys: ["titlestatus", "titlebrand"]),
            firstString(row, keys: ["condition"])
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if !noteParts.isEmpty {
            draft.notes = noteParts.joined(separator: " • ")
        }

        return draft.makeListing()
    }

    private static func firstArray(
        _ row: [String: Any],
        keys: [String]
    ) -> [[String: Any]]? {
        for key in keys {
            if let array = row[key] as? [[String: Any]] { return array }
        }
        return nil
    }

    private static func firstString(
        _ row: [String: Any],
        keys: [String]
    ) -> String? {
        let normalized = normalizedDictionary(row)

        for key in keys.map(normalizeKey) {
            guard let value = normalized[key] else { continue }

            if let string = value as? String, !string.isEmpty {
                return string
            }
            if let number = value as? NSNumber {
                return number.stringValue
            }
            if let dict = value as? [String: Any] {
                for nestedKey in ["text", "name", "value", "label", "formatted"] {
                    if let string = dict[nestedKey] as? String, !string.isEmpty {
                        return string
                    }
                }
            }
        }

        return nil
    }

    private static func firstNumber(
        _ row: [String: Any],
        keys: [String]
    ) -> Double? {
        let normalized = normalizedDictionary(row)

        for key in keys.map(normalizeKey) {
            guard let value = normalized[key] else { continue }

            if let number = value as? NSNumber { return number.doubleValue }
            if let number = value as? Double { return number }
            if let number = value as? Int { return Double(number) }

            if let string = value as? String {
                let cleaned = string
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: "CAD", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "USD", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let numeric = cleaned.filter { $0.isNumber || $0 == "." || $0 == "-" }
                if let value = Double(numeric), !numeric.isEmpty { return value }
            }
        }

        return nil
    }

    private static func firstInt(
        _ row: [String: Any],
        keys: [String]
    ) -> Int? {
        firstNumber(row, keys: keys).map(Int.init)
    }

    private static func firstBool(
        _ row: [String: Any],
        keys: [String]
    ) -> Bool? {
        let normalized = normalizedDictionary(row)

        for key in keys.map(normalizeKey) {
            guard let value = normalized[key] else { continue }

            if let bool = value as? Bool { return bool }
            if let number = value as? NSNumber { return number.boolValue }
            if let string = value as? String {
                let lower = string.lowercased()
                if ["true", "yes", "1", "run", "runs", "run & drive"].contains(lower) { return true }
                if ["false", "no", "0", "no run", "non-runner"].contains(lower) { return false }
            }
        }

        return nil
    }

    private static func synthesizedTitle(_ row: [String: Any]) -> String {
        [
            firstString(row, keys: ["year", "modelyear"]),
            firstString(row, keys: ["make"]),
            firstString(row, keys: ["model"]),
            firstString(row, keys: ["trim"])
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    private static func normalizedOdometer(_ row: [String: Any]) -> Double? {
        guard let value = firstNumber(row, keys: [
            "odometerkm", "kilometres", "kilometers", "mileage", "odometer"
        ]) else { return nil }

        let unit = firstString(row, keys: ["mileageunit", "odometerunit", "unit"])?.lowercased()
        if unit == "mi" || unit == "miles" {
            return value * 1.609344
        }

        if normalizedDictionary(row).keys.contains("odometerkm") ||
            normalizedDictionary(row).keys.contains("kilometres") ||
            normalizedDictionary(row).keys.contains("kilometers") {
            return value
        }

        return value
    }

    private static func parseTransmission(_ raw: String) -> TransmissionType {
        let lower = raw.lowercased()
        if lower.contains("manual") || lower.contains("5-speed") || lower.contains("6-speed") {
            return .manual
        }
        if lower.contains("auto") || lower.contains("cvt") {
            return .automatic
        }
        if lower.contains("missing") || lower.contains("none") {
            return .none
        }
        return .unknown
    }

    private static func parseDrivetrain(_ raw: String) -> Drivetrain {
        let lower = raw.lowercased()
        if lower.contains("rwd") || lower.contains("rear") { return .rwd }
        if lower.contains("awd") || lower.contains("all wheel") { return .awd }
        if lower.contains("4wd") || lower.contains("4x4") || lower.contains("four wheel") { return .fourWD }
        if lower.contains("fwd") || lower.contains("front") { return .fwd }
        return .unknown
    }

    private static func normalizedDictionary(_ row: [String: Any]) -> [String: Any] {
        Dictionary(uniqueKeysWithValues: row.map { (normalizeKey($0.key), $0.value) })
    }

    private static func normalizeKey(_ key: String) -> String {
        key
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
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

    enum ImportError: Error {
        case unsupportedShape
    }
}
