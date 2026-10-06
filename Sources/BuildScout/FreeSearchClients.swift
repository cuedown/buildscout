import Foundation

enum SearchResultParsing {
    static func price(from text: String) -> Double? {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?:CA\$|C\$|CAD\s*\$?|\$)\s*([0-9]{2,7}(?:,[0-9]{3})*(?:\.\d{1,2})?)"#
        ) else { return nil }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let priceRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return Double(
            text[priceRange]
                .replacingOccurrences(of: ",", with: "")
        )
    }

    static func host(from raw: String) -> String? {
        URL(string: raw)?.host
    }

    static func joinedText(_ values: Any?...) -> String {
        values.compactMap { $0 as? String }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }
}

enum TavilySearchClient {
    static func search(
        query: String,
        apiKey: String,
        kind: HuntResultKind
    ) async throws -> [HuntResult] {
        let url = URL(string: "https://api.tavily.com/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": query,
            "search_depth": "basic",
            "max_results": 20,
            "topic": "general",
            "include_answer": false,
            "include_raw_content": false,
            "include_images": false
        ])

        let object = try await json(request)
        let rows = object["results"] as? [[String: Any]] ?? []

        return rows.compactMap { row in
            guard let title = row["title"] as? String,
                  let url = row["url"] as? String else { return nil }

            let content = row["content"] as? String ?? ""
            return HuntResult(
                provider: "Tavily • Web",
                kind: kind,
                title: title,
                url: url,
                snippet: content,
                price: SearchResultParsing.price(from: content),
                currency: "CAD",
                location: nil,
                thumbnailURL: nil,
                sourceDomain: SearchResultParsing.host(from: url)
            )
        }
    }

    private static func json(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.badServerResponse)
        }
        return object
    }
}

enum ExaSearchClient {
    static func search(
        query: String,
        apiKey: String,
        kind: HuntResultKind
    ) async throws -> [HuntResult] {
        let url = URL(string: "https://api.exa.ai/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": query,
            "type": "fast",
            "numResults": 20,
            "contents": [
                "highlights": true
            ]
        ])

        let object = try await json(request)
        let rows = object["results"] as? [[String: Any]] ?? []

        return rows.compactMap { row in
            guard let title = row["title"] as? String,
                  let url = row["url"] as? String else { return nil }

            let highlights = (row["highlights"] as? [String])?.joined(separator: " ") ?? ""
            let text = row["text"] as? String ?? ""
            let summary = row["summary"] as? String ?? ""
            let snippet = [summary, highlights, text]
                .filter { !$0.isEmpty }
                .joined(separator: " • ")

            return HuntResult(
                provider: "Exa • Web",
                kind: kind,
                title: title,
                url: url,
                snippet: String(snippet.prefix(1200)),
                price: SearchResultParsing.price(from: snippet),
                currency: "CAD",
                location: nil,
                thumbnailURL: row["image"] as? String,
                sourceDomain: SearchResultParsing.host(from: url)
            )
        }
    }

    private static func json(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.badServerResponse)
        }
        return object
    }
}

enum BraveSearchClient {
    static func search(
        query: String,
        apiKey: String,
        kind: HuntResultKind
    ) async throws -> [HuntResult] {
        var components = URLComponents(
            string: "https://api.search.brave.com/res/v1/web/search"
        )!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "country", value: "CA"),
            URLQueryItem(name: "search_lang", value: "en"),
            URLQueryItem(name: "count", value: "20")
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 20
        request.setValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let object = try await json(request)
        let web = object["web"] as? [String: Any]
        let rows = web?["results"] as? [[String: Any]] ?? []

        return rows.compactMap { row in
            guard let title = row["title"] as? String,
                  let url = row["url"] as? String else { return nil }

            let description = row["description"] as? String ?? ""
            return HuntResult(
                provider: "Brave Search • Web",
                kind: kind,
                title: title,
                url: url,
                snippet: description,
                price: SearchResultParsing.price(from: description),
                currency: "CAD",
                location: nil,
                thumbnailURL: nil,
                sourceDomain: SearchResultParsing.host(from: url)
            )
        }
    }

    private static func json(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.badServerResponse)
        }
        return object
    }
}

enum FreeWebDiscovery {
    @MainActor
    static func search(
        request: HuntRequest,
        connections: ConnectionStore,
        kind: HuntResultKind = .vehicle
    ) async -> [HuntResult] {
        let queries = request.keywords
        guard !queries.isEmpty else { return [] }

        let tavilyKey = connections.tavilyAPIKey
        let exaKey = connections.exaAPIKey
        let braveKey = connections.braveAPIKey

        var results: [HuntResult] = []

        await withTaskGroup(of: [HuntResult].self) { group in
            if connections.hasTavily {
                for query in distributedQueries(
                    queries,
                    start: 0,
                    count: 3
                ) {
                    group.addTask {
                        (try? await TavilySearchClient.search(
                            query: query,
                            apiKey: tavilyKey,
                            kind: kind
                        )) ?? []
                    }
                }
            }

            if connections.hasExa {
                for query in distributedQueries(
                    queries,
                    start: 2,
                    count: 3
                ) {
                    group.addTask {
                        (try? await ExaSearchClient.search(
                            query: query,
                            apiKey: exaKey,
                            kind: kind
                        )) ?? []
                    }
                }
            }

            if connections.hasBrave {
                for query in distributedQueries(
                    queries,
                    start: 4,
                    count: 3
                ) {
                    group.addTask {
                        (try? await BraveSearchClient.search(
                            query: query,
                            apiKey: braveKey,
                            kind: kind
                        )) ?? []
                    }
                }
            }

            for await batch in group {
                results.append(contentsOf: batch)
            }
        }

        return dedupe(results)
    }

    private static func distributedQueries(
        _ queries: [String],
        start: Int,
        count: Int
    ) -> [String] {
        guard !queries.isEmpty else { return [] }

        return (0..<min(count, queries.count)).map { offset in
            queries[(start + offset) % queries.count]
        }
    }

    private static func dedupe(_ results: [HuntResult]) -> [HuntResult] {
        var seen = Set<String>()
        return results.filter {
            let key = $0.url.isEmpty
                ? "\($0.provider)|\($0.title.lowercased())"
                : $0.url
            return seen.insert(key).inserted
        }
    }
}
