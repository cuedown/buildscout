import Foundation

enum ApifyAutomotiveSources {
    static let facebookActor = "automly/facebook-marketplace-scraper"
    static let kijijiActor = "fayoussef/kijiji-scraper"
    static let craigslistActor = "logiover/craigslist-scraper"
    static let copartActor = "crawlerbros/copart-public-search-scraper"
    static let iaaActor = "scrapers_lat/iaai-salvage-cars-scraper"

    @MainActor
    static func search(
        request: HuntRequest,
        connections: ConnectionStore
    ) async -> [HuntResult] {
        guard connections.hasApify else { return [] }

        let token = connections.apifyToken
        let maxItems = max(5, min(connections.apifyMaxResultsPerSource, 100))
        var all: [HuntResult] = []

        await withTaskGroup(of: [HuntResult].self) { group in
            if connections.enableApifyFacebook {
                group.addTask {
                    await facebook(
                        request: request,
                        token: token,
                        maxItems: maxItems
                    )
                }
            }

            if connections.enableApifyKijiji {
                group.addTask {
                    await kijiji(
                        request: request,
                        token: token,
                        maxItems: maxItems
                    )
                }
            }

            if connections.enableApifyCraigslist {
                group.addTask {
                    await craigslist(
                        request: request,
                        token: token,
                        maxItems: maxItems
                    )
                }
            }

            if connections.enableApifySalvage {
                group.addTask {
                    await copart(
                        request: request,
                        token: token,
                        maxItems: maxItems
                    )
                }

                group.addTask {
                    await iaa(
                        request: request,
                        token: token,
                        maxItems: maxItems
                    )
                }
            }

            for await batch in group {
                all.append(contentsOf: batch)
            }
        }

        return dedupe(all)
    }

    private static func facebook(
        request: HuntRequest,
        token: String,
        maxItems: Int
    ) async -> [HuntResult] {
        var results: [HuntResult] = []

        for query in request.keywords.prefix(3) {
            let input: [String: Any] = [
                "searchQueries": [query],
                "location": request.location,
                "category": "vehicles",
                "maxPrice": Int(request.maxVehiclePrice),
                "maxItems": maxItems,
                "includeDetails": true
            ]

            guard let rows = try? await ApifyClient.runActor(
                actorID: facebookActor,
                token: token,
                input: input
            ) else { continue }

            results.append(contentsOf: rows.map {
                result(
                    row: $0,
                    provider: "Apify • Facebook Marketplace",
                    kind: .vehicle,
                    preferredURLKeys: ["listing_url", "listingUrl", "url", "listingLink"],
                    preferredPriceKeys: ["price", "priceAmount", "amount"],
                    preferredLocationKeys: ["location", "locationText", "city"],
                    preferredMileageKeys: ["mileage", "vehicleMileage", "odometer"]
                )
            })
        }

        return results
    }

    private static func kijiji(
        request: HuntRequest,
        token: String,
        maxItems: Int
    ) async -> [HuntResult] {
        var results: [HuntResult] = []

        for query in request.keywords.prefix(3) {
            let pages = max(1, min(5, Int(ceil(Double(maxItems) / 40.0))))
            let searchURL = kijijiSearchURL(
                query: query,
                location: request.location,
                maxPrice: request.maxVehiclePrice
            )

            let input: [String: Any] = [
                "start_urls": [["url": searchURL]],
                "max_pages": pages
            ]

            guard let rows = try? await ApifyClient.runActor(
                actorID: kijijiActor,
                token: token,
                input: input
            ) else { continue }

            results.append(contentsOf: rows.map {
                result(
                    row: $0,
                    provider: "Apify • Kijiji",
                    kind: .vehicle,
                    preferredURLKeys: ["kijiji_url", "url", "adUrl", "listingUrl"],
                    preferredPriceKeys: ["price_amount", "price", "priceValue"],
                    preferredLocationKeys: ["location_name", "location_address", "location", "address", "city"],
                    preferredMileageKeys: ["mileage_km", "kilometres", "kilometers", "mileage", "odometer"]
                )
            })
        }

        return results
    }

    private static func craigslist(
        request: HuntRequest,
        token: String,
        maxItems: Int
    ) async -> [HuntResult] {
        var results: [HuntResult] = []

        for query in request.keywords.prefix(2) {
            let input: [String: Any] = [
                "city": craigslistCity(from: request.location),
                "category": "cta",
                "query": query,
                "maxPrice": Int(request.maxVehiclePrice),
                "maxResults": maxItems,
                "includeDetails": true
            ]

            guard let rows = try? await ApifyClient.runActor(
                actorID: craigslistActor,
                token: token,
                input: input
            ) else { continue }

            results.append(contentsOf: rows.map {
                result(
                    row: $0,
                    provider: "Apify • Craigslist",
                    kind: .vehicle,
                    preferredURLKeys: ["url", "link", "postingUrl"],
                    preferredPriceKeys: ["priceValue", "price", "amount"],
                    preferredLocationKeys: ["location", "neighborhood", "city"],
                    preferredMileageKeys: ["odometer", "mileage"]
                )
            })
        }

        return results
    }

    private static func copart(
        request: HuntRequest,
        token: String,
        maxItems: Int
    ) async -> [HuntResult] {
        let query = request.keywords.first ?? request.mission.rawValue
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let input: [String: Any] = [
            "startUrl": "https://www.copart.com/lotSearchResults/?free=true&query=\(encoded)",
            "maxItems": maxItems
        ]

        guard let rows = try? await ApifyClient.runActor(
            actorID: copartActor,
            token: token,
            input: input
        ) else { return [] }

        return rows.map {
            result(
                row: $0,
                provider: "Apify • Copart",
                kind: .auction,
                preferredURLKeys: ["item_url", "lotUrl", "url", "link"],
                preferredPriceKeys: ["current_bid", "buy_it_now_price", "currentBid", "buyNowPrice", "price"],
                preferredLocationKeys: ["sale_location", "location", "yard", "saleLocation", "state"],
                preferredMileageKeys: ["odometer", "mileage"]
            )
        }
    }

    private static func iaa(
        request: HuntRequest,
        token: String,
        maxItems: Int
    ) async -> [HuntResult] {
        let query = request.keywords.first ?? request.mission.rawValue
        let input: [String: Any] = [
            "searchQuery": query,
            "maxResults": maxItems,
            "lotDetails": false,
            "aiLotAssessment": false
        ]

        guard let rows = try? await ApifyClient.runActor(
            actorID: iaaActor,
            token: token,
            input: input
        ) else { return [] }

        return rows.map {
            result(
                row: $0,
                provider: "Apify • IAA",
                kind: .auction,
                preferredURLKeys: ["lotUrl", "url", "link"],
                preferredPriceKeys: ["currentBid", "actualCashValue", "price"],
                preferredLocationKeys: ["branch", "location", "state"],
                preferredMileageKeys: ["odometer", "mileage"]
            )
        }
    }

    private static func result(
        row: [String: Any],
        provider: String,
        kind: HuntResultKind,
        preferredURLKeys: [String],
        preferredPriceKeys: [String],
        preferredLocationKeys: [String],
        preferredMileageKeys: [String]
    ) -> HuntResult {
        var flat = row
        if let vehicle = row["vehicle"] as? [String: Any] {
            for (key, value) in vehicle where flat[key] == nil {
                flat[key] = value
            }
        }

        let title = firstString(flat, [
            "title", "name", "heading", "vehicleTitle", "titleName"
        ]) ?? buildTitle(flat)

        let url = firstString(flat, preferredURLKeys) ?? ""
        let price = firstNumber(flat, preferredPriceKeys)
        let location = firstString(flat, preferredLocationKeys)
        let mileage = firstNumber(flat, preferredMileageKeys)
        let vin = firstString(flat, ["vin", "VIN", "vehicleVin"])
        let transmissionRaw = firstString(flat, ["transmission", "transmissionType"])
        let drivetrainRaw = firstString(flat, ["drivetrain", "driveTrain", "drive"])
        let description = firstString(flat, [
            "description", "snippet", "condition", "primaryDamage", "details"
        ]) ?? ""

        let currency = firstString(flat, ["currency", "priceCurrency", "acvCurrency"])
            ?? (provider.contains("Kijiji") || provider.contains("Facebook") ? "CAD" : nil)

        return HuntResult(
            provider: provider,
            kind: kind,
            title: title.isEmpty ? "Vehicle listing" : title,
            url: url,
            snippet: description,
            price: price,
            currency: currency,
            location: location,
            thumbnailURL: firstString(flat, [
                "photoUrl", "image", "imageUrl", "thumbnail", "imageThumbnail", "mainPhoto"
            ]),
            sourceDomain: host(from: url),
            vin: vin,
            odometerKM: normalizedKilometers(mileage, row: flat),
            drivetrain: parseDrivetrain(drivetrainRaw),
            transmission: parseTransmission(transmissionRaw)
        )
    }

    private static func buildTitle(_ row: [String: Any]) -> String {
        [
            firstString(row, ["year", "modelYear"]),
            firstString(row, ["make"]),
            firstString(row, ["model"]),
            firstString(row, ["trim"])
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    private static func firstString(_ row: [String: Any], _ keys: [String]) -> String? {
        for key in keys {
            if let string = row[key] as? String, !string.isEmpty { return string }
            if let number = row[key] as? NSNumber { return number.stringValue }
            if let dict = row[key] as? [String: Any] {
                if let label = dict["text"] as? String { return label }
                if let label = dict["name"] as? String { return label }
                if let label = dict["value"] as? String { return label }
            }
        }
        return nil
    }

    private static func firstNumber(_ row: [String: Any], _ keys: [String]) -> Double? {
        for key in keys {
            if let number = row[key] as? NSNumber { return number.doubleValue }
            if let number = row[key] as? Double { return number }
            if let number = row[key] as? Int { return Double(number) }
            if let string = row[key] as? String {
                let stripped = string
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: "CAD", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let value = Double(stripped) { return value }
            }
        }
        return nil
    }

    private static func normalizedKilometers(
        _ mileage: Double?,
        row: [String: Any]
    ) -> Double? {
        guard let mileage else { return nil }

        if let unit = firstString(
            row,
            ["mileageUnit", "mileage_unit", "odometer_unit", "odometerUnit", "unit"]
        )?.lowercased(),
           unit.contains("mile") || unit == "mi" {
            return mileage * 1.609344
        }

        return mileage
    }

    private static func parseDrivetrain(_ raw: String?) -> Drivetrain? {
        guard let raw else { return nil }
        let lower = raw.lowercased()
        if lower.contains("rwd") || lower.contains("rear") { return .rwd }
        if lower.contains("awd") || lower.contains("all") { return .awd }
        if lower.contains("4wd") || lower.contains("4x4") || lower.contains("four") { return .fourWD }
        if lower.contains("fwd") || lower.contains("front") { return .fwd }
        return nil
    }

    private static func parseTransmission(_ raw: String?) -> TransmissionType? {
        guard let raw else { return nil }
        let lower = raw.lowercased()
        if lower.contains("manual") { return .manual }
        if lower.contains("automatic") || lower.contains("cvt") { return .automatic }
        return nil
    }

    private static func host(from raw: String) -> String? {
        guard let url = URL(string: raw) else { return nil }
        return url.host
    }

    private static func kijijiSearchURL(
        query: String,
        location: String,
        maxPrice: Double
    ) -> String {
        let city = location.split(separator: ",").first.map(String.init) ?? location
        let citySlug = city
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: #"[^a-z0-9-]"#, with: "", options: .regularExpression)

        let querySlug = query
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: #"[^a-z0-9-]"#, with: "", options: .regularExpression)

        let locationID: String
        switch citySlug {
        case "calgary": locationID = "1700199"
        case "edmonton": locationID = "1700203"
        default: locationID = "0"
        }

        let regionSlug = locationID == "0" ? "canada" : citySlug
        let price = Int(maxPrice)
        return "https://www.kijiji.ca/b-cars-trucks/\(regionSlug)/\(querySlug)/k0c174l\(locationID)?price=__\(price)"
    }

    private static func craigslistCity(from region: String) -> String {
        let city = region.split(separator: ",").first.map(String.init) ?? region
        return city
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }

    private static func dedupe(_ items: [HuntResult]) -> [HuntResult] {
        var seen = Set<String>()
        return items.filter { item in
            let key = item.url.isEmpty
                ? "\(item.provider)|\(item.title.lowercased())|\(Int(item.price ?? 0))"
                : item.url
            return seen.insert(key).inserted
        }
    }
}
