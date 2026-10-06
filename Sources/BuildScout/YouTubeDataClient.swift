import Foundation

enum YouTubeDataClient {
    static func search(
        query: String,
        apiKey: String,
        maxResults: Int = 20
    ) async throws -> [HuntResult] {
        var components = URLComponents(
            string: "https://www.googleapis.com/youtube/v3/search"
        )!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: String(min(max(maxResults, 1), 50))),
            URLQueryItem(name: "regionCode", value: "CA"),
            URLQueryItem(name: "relevanceLanguage", value: "en"),
            URLQueryItem(name: "safeSearch", value: "moderate"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.badServerResponse)
        }

        let rows = object["items"] as? [[String: Any]] ?? []

        return rows.compactMap { row in
            guard let id = row["id"] as? [String: Any],
                  let videoID = id["videoId"] as? String,
                  let snippet = row["snippet"] as? [String: Any],
                  let title = snippet["title"] as? String else {
                return nil
            }

            let description = snippet["description"] as? String ?? ""
            let channel = snippet["channelTitle"] as? String ?? ""
            let published = snippet["publishedAt"] as? String ?? ""

            var thumbnail: String?
            if let thumbnails = snippet["thumbnails"] as? [String: Any] {
                for key in ["high", "medium", "default"] {
                    if let image = thumbnails[key] as? [String: Any],
                       let url = image["url"] as? String {
                        thumbnail = url
                        break
                    }
                }
            }

            return HuntResult(
                provider: "YouTube Data API",
                kind: .guide,
                title: title,
                url: "https://www.youtube.com/watch?v=\(videoID)",
                snippet: [channel, published, description]
                    .filter { !$0.isEmpty }
                    .joined(separator: " • "),
                price: nil,
                currency: nil,
                location: nil,
                thumbnailURL: thumbnail,
                sourceDomain: "youtube.com"
            )
        }
    }
}
