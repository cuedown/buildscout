import Foundation

enum SerpAPIClient {
    static func googleSearch(
        query: String,
        location: String,
        apiKey: String,
        kind: HuntResultKind
    ) async throws -> [HuntResult] {
        var c = URLComponents(string: "https://serpapi.com/search.json")!
        c.queryItems = [
            .init(name: "engine", value: "google"),
            .init(name: "q", value: query),
            .init(name: "location", value: location),
            .init(name: "gl", value: "ca"),
            .init(name: "hl", value: "en"),
            .init(name: "api_key", value: apiKey)
        ]
        let object = try await json(c.url!)
        let rows = object["organic_results"] as? [[String: Any]] ?? []

        return rows.prefix(20).compactMap { row in
            guard let title = row["title"] as? String,
                  let link = row["link"] as? String else { return nil }

            return HuntResult(
                provider: "SerpApi • Google",
                kind: kind,
                title: title,
                url: link,
                snippet: row["snippet"] as? String ?? "",
                price: extractPrice(from: row["snippet"] as? String ?? ""),
                currency: "CAD",
                location: location,
                thumbnailURL: row["thumbnail"] as? String,
                sourceDomain: row["source"] as? String
            )
        }
    }

    static func shoppingSearch(
        query: String,
        location: String,
        apiKey: String
    ) async throws -> [HuntResult] {
        var c = URLComponents(string: "https://serpapi.com/search.json")!
        c.queryItems = [
            .init(name: "engine", value: "google_shopping_light"),
            .init(name: "q", value: query),
            .init(name: "location", value: location),
            .init(name: "gl", value: "ca"),
            .init(name: "hl", value: "en"),
            .init(name: "api_key", value: apiKey)
        ]

        let object = try await json(c.url!)
        let rows = object["shopping_results"] as? [[String: Any]] ?? []

        return rows.prefix(30).compactMap { row in
            guard let title = row["title"] as? String else { return nil }
            let link = (row["link"] as? String) ?? (row["product_link"] as? String) ?? ""

            return HuntResult(
                provider: "SerpApi • Shopping",
                kind: .part,
                title: title,
                url: link,
                snippet: [row["source"] as? String, row["delivery"] as? String]
                    .compactMap { $0 }
                    .joined(separator: " • "),
                price: row["extracted_price"] as? Double,
                currency: "CAD",
                location: location,
                thumbnailURL: row["thumbnail"] as? String,
                sourceDomain: row["source"] as? String
            )
        }
    }

    static func ebaySearch(
        query: String,
        apiKey: String
    ) async throws -> [HuntResult] {
        var c = URLComponents(string: "https://serpapi.com/search.json")!
        c.queryItems = [
            .init(name: "engine", value: "ebay"),
            .init(name: "_nkw", value: query),
            .init(name: "ebay_domain", value: "ebay.ca"),
            .init(name: "api_key", value: apiKey)
        ]

        let object = try await json(c.url!)
        let rows = object["organic_results"] as? [[String: Any]] ?? []

        return rows.prefix(30).compactMap { row in
            guard let title = row["title"] as? String,
                  let link = row["link"] as? String else { return nil }

            var extracted: Double?
            if let price = row["price"] as? [String: Any] {
                if let from = price["from"] as? [String: Any] {
                    extracted = from["extracted"] as? Double
                } else if let direct = price["extracted"] as? Double {
                    extracted = direct
                }
            }

            return HuntResult(
                provider: "SerpApi • eBay",
                kind: .part,
                title: title,
                url: link,
                snippet: row["condition"] as? String ?? "",
                price: extracted,
                currency: "CAD",
                location: nil,
                thumbnailURL: row["thumbnail"] as? String,
                sourceDomain: "ebay.ca"
            )
        }
    }

    static func youtubeSearch(
        query: String,
        apiKey: String
    ) async throws -> [HuntResult] {
        var c = URLComponents(string: "https://serpapi.com/search.json")!
        c.queryItems = [
            .init(name: "engine", value: "youtube"),
            .init(name: "search_query", value: query),
            .init(name: "gl", value: "ca"),
            .init(name: "hl", value: "en"),
            .init(name: "api_key", value: apiKey)
        ]

        let object = try await json(c.url!)
        let rows = object["video_results"] as? [[String: Any]] ?? []

        return rows.prefix(20).compactMap { row in
            guard let title = row["title"] as? String,
                  let link = row["link"] as? String else { return nil }

            let channel = (row["channel"] as? [String: Any])?["name"] as? String
            let description = row["description"] as? String ?? ""
            let published = row["published_date"] as? String
            let snippet = [channel, published, description]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " • ")

            var thumb: String?
            if let thumbnail = row["thumbnail"] as? [String: Any] {
                thumb = thumbnail["static"] as? String
            } else {
                thumb = row["thumbnail"] as? String
            }

            return HuntResult(
                provider: "SerpApi • YouTube",
                kind: .guide,
                title: title,
                url: link,
                snippet: snippet,
                price: nil,
                currency: nil,
                location: nil,
                thumbnailURL: thumb,
                sourceDomain: "youtube.com"
            )
        }
    }

    static func mapsSearch(
        query: String,
        location: String,
        apiKey: String
    ) async throws -> [HuntResult] {
        var c = URLComponents(string: "https://serpapi.com/search.json")!
        c.queryItems = [
            .init(name: "engine", value: "google_maps"),
            .init(name: "type", value: "search"),
            .init(name: "q", value: "\(query) \(location)"),
            .init(name: "hl", value: "en"),
            .init(name: "api_key", value: apiKey)
        ]

        let object = try await json(c.url!)
        let rows = object["local_results"] as? [[String: Any]] ?? []

        return rows.prefix(20).compactMap { row in
            guard let title = row["title"] as? String else { return nil }
            let website = row["website"] as? String
            let mapsLink = row["link"] as? String
            let address = row["address"] as? String
            let type = row["type"] as? String
            let phone = row["phone"] as? String
            let rating = row["rating"] as? Double
            let reviews = row["reviews"] as? Int

            let details = [
                type,
                rating.map { String(format: "%.1f★", $0) },
                reviews.map { "\($0) reviews" },
                phone
            ].compactMap { $0 }.joined(separator: " • ")

            return HuntResult(
                provider: "SerpApi • Google Maps",
                kind: .service,
                title: title,
                url: website ?? mapsLink ?? "",
                snippet: details,
                price: nil,
                currency: nil,
                location: address,
                thumbnailURL: row["thumbnail"] as? String,
                sourceDomain: website.flatMap { URL(string: $0)?.host }
            )
        }
    }

    private static func json(_ url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("BuildScout/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return object
    }

    private static func extractPrice(from text: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: #"(?:CA\$|C\$|\$)\s*([0-9]{2,6}(?:,[0-9]{3})*)"#) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let priceRange = Range(match.range(at: 1), in: text) else { return nil }
        return Double(text[priceRange].replacingOccurrences(of: ",", with: ""))
    }
}
