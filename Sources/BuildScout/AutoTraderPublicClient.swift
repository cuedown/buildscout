import Foundation

enum AutoTraderPublicClient {
    private static let maximumPagesPerRun = 60
    private static let batchSize = 5

    static func search(
        request: HuntRequest,
        maxPages: Int = maximumPagesPerRun
    ) async -> [HuntResult] {
        guard let firstURL = searchURL(request: request, page: 1),
              let firstPage = try? await fetchPage(firstURL) else {
            return []
        }

        var results = normalized(
            firstPage.listings,
            request: request
        )

        let totalPages = max(1, firstPage.numberOfPages ?? 1)
        let pagesToFetch = min(totalPages, max(1, min(maxPages, maximumPagesPerRun)))

        guard pagesToFetch > 1 else {
            return dedupe(results)
        }

        var page = 2
        while page <= pagesToFetch {
            let upper = min(page + batchSize - 1, pagesToFetch)
            let pageNumbers = Array(page...upper)

            let batch = await withTaskGroup(of: [HuntResult].self) { group in
                for pageNumber in pageNumbers {
                    guard let url = searchURL(
                        request: request,
                        page: pageNumber
                    ) else { continue }

                    group.addTask {
                        guard let parsed = try? await fetchPage(url) else {
                            return []
                        }
                        return normalized(
                            parsed.listings,
                            request: request
                        )
                    }
                }

                var combined: [HuntResult] = []
                for await rows in group {
                    combined.append(contentsOf: rows)
                }
                return combined
            }

            results.append(contentsOf: batch)
            page = upper + 1
        }

        return dedupe(results)
    }

    private static func searchURL(
        request: HuntRequest,
        page: Int
    ) -> URL? {
        let geo = regionParts(request.location)
        let price = max(500, Int(request.maxVehiclePrice.rounded()))
        let radius = max(25, min(1000, Int(request.radiusKM.rounded())))

        let provincePath = geo.provinceCode.isEmpty
            ? ""
            : "/reg_\(geo.provinceCode.lowercased())"
        let cityPath = geo.citySlug.isEmpty
            ? ""
            : "/cit_\(geo.citySlug)"

        var components = URLComponents(
            string: "https://www.autotrader.ca/cars\(provincePath)\(cityPath)/ot_used/pr_\(price)"
        )
        components?.queryItems = [
            URLQueryItem(name: "zipr", value: String(radius)),
            URLQueryItem(name: "page", value: String(page))
        ]
        return components?.url
    }

    private static func fetchPage(_ url: URL) async throws -> AutoTraderPage {
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 BuildScout/0.3",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue(
            "text/html,application/xhtml+xml",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "en-CA,en;q=0.9",
            forHTTPHeaderField: "Accept-Language"
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode,
              let html = String(data: data, encoding: .utf8),
              let jsonData = nextData(in: html) else {
            throw URLError(.cannotParseResponse)
        }

        let decoded = try JSONDecoder().decode(
            AutoTraderNextData.self,
            from: jsonData
        )
        return decoded.props.pageProps
    }

    private static func nextData(in html: String) -> Data? {
        let marker = "<script id=\"__NEXT_DATA__\" type=\"application/json\">"
        guard let start = html.range(of: marker),
              let end = html.range(
                of: "</script>",
                range: start.upperBound..<html.endIndex
              ) else {
            return nil
        }

        let json = String(html[start.upperBound..<end.lowerBound])
        return json.data(using: .utf8)
    }

    private static func normalized(
        _ listings: [AutoTraderListing],
        request: HuntRequest
    ) -> [HuntResult] {
        listings.compactMap { row in
            guard let vehicle = row.vehicle else { return nil }

            let price = row.price?.priceRaw
            if let price, price > request.maxVehiclePrice * 1.05 {
                return nil
            }

            if let distance = row.location?.distanceToSearchLocationInKm,
               distance > request.radiusKM + 5 {
                return nil
            }

            let description = cleanHTML(row.description ?? "")
            let drivetrain = inferDrivetrain(description)
            let transmission = inferTransmission(
                vehicle.transmission ?? description
            )

            let title = [
                vehicle.modelYear.map(String.init),
                vehicle.make,
                vehicle.model,
                vehicle.modelVersionInput
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

            let location = [
                row.location?.city,
                row.location?.provinceCode
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

            let mileage = parseMileage(vehicle.mileageInKm)
            let horsepower = parseHorsepower(row.vehicleDetails)

            var snippetPieces: [String] = []
            if let transmission = vehicle.transmission, !transmission.isEmpty {
                snippetPieces.append(transmission)
            }
            if let drivetrain, drivetrain != .unknown {
                snippetPieces.append(drivetrain.rawValue)
            }
            if let mileage {
                snippetPieces.append("\(Int(mileage)) km")
            }
            if let horsepower {
                snippetPieces.append("\(horsepower) hp")
            }
            if let seller = row.seller?.companyName, !seller.isEmpty {
                snippetPieces.append(seller)
            }

            let descriptionExcerpt = String(description.prefix(900))
            if !descriptionExcerpt.isEmpty {
                snippetPieces.append(descriptionExcerpt)
            }

            return HuntResult(
                provider: "AutoTrader.ca • live public search",
                kind: .vehicle,
                title: title.isEmpty ? "AutoTrader vehicle" : title,
                url: row.url ?? "",
                snippet: snippetPieces.joined(separator: " • "),
                price: price,
                currency: "CAD",
                location: location.isEmpty ? nil : location,
                thumbnailURL: row.images?.first,
                sourceDomain: "autotrader.ca",
                vin: extractVIN(description),
                odometerKM: mileage,
                drivetrain: drivetrain,
                transmission: transmission
            )
        }
    }

    private static func regionParts(
        _ raw: String
    ) -> (citySlug: String, provinceCode: String) {
        let pieces = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let city = pieces.first ?? ""
        let province = pieces.dropFirst().first ?? ""

        let provinceMap: [String: String] = [
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

        let slug = city
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(
                of: #"[^a-z0-9]+"#,
                with: "_",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        return (
            slug,
            provinceMap[province.lowercased()]
                ?? province.uppercased()
        )
    }

    private static func cleanHTML(_ raw: String) -> String {
        raw
            .replacingOccurrences(
                of: #"(?i)<br\s*/?>"#,
                with: "\n",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"<[^>]+>"#,
                with: " ",
                options: .regularExpression
            )
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(
                of: #"[ \t]{2,}"#,
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func inferDrivetrain(
        _ text: String
    ) -> Drivetrain? {
        let lower = text.lowercased()

        if lower.contains("rear-wheel drive") ||
            lower.contains("rear wheel drive") ||
            lower.contains("drivetrain: rwd") ||
            lower.contains(" rwd ") {
            return .rwd
        }

        if lower.contains("all-wheel drive") ||
            lower.contains("all wheel drive") ||
            lower.contains("drivetrain: awd") ||
            lower.contains(" awd ") {
            return .awd
        }

        if lower.contains("four-wheel drive") ||
            lower.contains("four wheel drive") ||
            lower.contains("drivetrain: 4wd") ||
            lower.contains(" 4x4 ") {
            return .fourWD
        }

        if lower.contains("front-wheel drive") ||
            lower.contains("front wheel drive") ||
            lower.contains("drivetrain: fwd") ||
            lower.contains(" fwd ") {
            return .fwd
        }

        return nil
    }

    private static func inferTransmission(
        _ text: String
    ) -> TransmissionType? {
        let lower = text.lowercased()
        if lower.contains("manual") ||
            lower.contains("5-speed") ||
            lower.contains("6-speed manual") {
            return .manual
        }
        if lower.contains("automatic") ||
            lower.contains("cvt") ||
            lower.contains("dct") {
            return .automatic
        }
        return nil
    }

    private static func parseMileage(_ raw: String?) -> Double? {
        guard let raw else { return nil }
        let digits = raw.filter(\.isNumber)
        return Double(digits)
    }

    private static func parseHorsepower(
        _ details: [AutoTraderVehicleDetail]?
    ) -> Int? {
        guard let details else { return nil }

        for detail in details {
            let text = detail.data ?? ""
            if let match = firstMatch(
                in: text,
                pattern: #"([0-9]{2,4})\s*hp"#,
                capture: 1
            ),
               let value = Int(match) {
                return value
            }
        }

        return nil
    }

    private static func extractVIN(_ text: String) -> String? {
        firstMatch(
            in: text.uppercased(),
            pattern: #"\b[A-HJ-NPR-Z0-9]{17}\b"#,
            capture: 0
        )
    }

    private static func firstMatch(
        in text: String,
        pattern: String,
        capture: Int
    ) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return nil
        }

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )
        guard let match = regex.firstMatch(
            in: text,
            range: range
        ),
        capture < match.numberOfRanges,
        let swiftRange = Range(
            match.range(at: capture),
            in: text
        ) else {
            return nil
        }

        return String(text[swiftRange])
    }

    private static func dedupe(
        _ results: [HuntResult]
    ) -> [HuntResult] {
        var seen = Set<String>()

        return results.filter {
            let key = $0.url.isEmpty
                ? "\($0.title.lowercased())|\(Int($0.price ?? 0))"
                : $0.url
            return seen.insert(key).inserted
        }
    }
}

private struct AutoTraderNextData: Decodable {
    let props: AutoTraderProps
}

private struct AutoTraderProps: Decodable {
    let pageProps: AutoTraderPage
}

private struct AutoTraderPage: Decodable {
    let numberOfResults: Int?
    let numberOfPages: Int?
    let listings: [AutoTraderListing]
}

private struct AutoTraderListing: Decodable {
    let id: String?
    let images: [String]?
    let description: String?
    let price: AutoTraderPrice?
    let url: String?
    let vehicle: AutoTraderVehicle?
    let location: AutoTraderLocation?
    let seller: AutoTraderSeller?
    let vehicleDetails: [AutoTraderVehicleDetail]?
}

private struct AutoTraderPrice: Decodable {
    let priceRaw: Double?
}

private struct AutoTraderVehicle: Decodable {
    let make: String?
    let model: String?
    let modelVersionInput: String?
    let modelYear: Int?
    let transmission: String?
    let mileageInKm: String?
}

private struct AutoTraderLocation: Decodable {
    let provinceCode: String?
    let city: String?
    let distanceToSearchLocationInKm: Double?
}

private struct AutoTraderSeller: Decodable {
    let companyName: String?
    let type: String?
}

private struct AutoTraderVehicleDetail: Decodable {
    let data: String?
    let ariaLabel: String?
}
