import Foundation

enum GitHubSearchClient {
    static func repositories(
        query: String,
        token: String?
    ) async throws -> [HuntResult] {
        var components = URLComponents(
            string: "https://api.github.com/search/repositories"
        )!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sort", value: "updated"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: "20")
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 20
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("BuildScout/0.3", forHTTPHeaderField: "User-Agent")

        if let token,
           !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.badServerResponse)
        }

        let rows = object["items"] as? [[String: Any]] ?? []

        return rows.compactMap { row in
            guard let name = row["full_name"] as? String,
                  let url = row["html_url"] as? String else {
                return nil
            }

            let description = row["description"] as? String ?? ""
            let language = row["language"] as? String ?? ""
            let stars = row["stargazers_count"] as? Int ?? 0

            return HuntResult(
                provider: "GitHub REST API",
                kind: .guide,
                title: name,
                url: url,
                snippet: [description, language, "\(stars) stars"]
                    .filter { !$0.isEmpty }
                    .joined(separator: " • "),
                price: nil,
                currency: nil,
                location: nil,
                thumbnailURL: nil,
                sourceDomain: "github.com"
            )
        }
    }
}
