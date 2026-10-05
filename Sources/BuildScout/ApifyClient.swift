import Foundation

enum ApifyClient {
    static func runActor(
        actorID: String,
        token: String,
        input: [String: Any],
        timeoutSeconds: Int = 90
    ) async throws -> [[String: Any]] {
        let encodedActor = actorID.replacingOccurrences(of: "/", with: "~")
        var components = URLComponents(
            string: "https://api.apify.com/v2/acts/\(encodedActor)/run-sync-get-dataset-items"
        )!
        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "clean", value: "true")
        ]

        guard let url = components.url else {
            throw ApifyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = TimeInterval(timeoutSeconds)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("BuildScout/0.2", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: input)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ApifyError.invalidResponse
        }

        guard 200..<300 ~= http.statusCode else {
            let detail = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw ApifyError.actorFailed(detail)
        }

        let object = try JSONSerialization.jsonObject(with: data)
        if let rows = object as? [[String: Any]] {
            return rows
        }

        if let envelope = object as? [String: Any],
           let rows = envelope["items"] as? [[String: Any]] {
            return rows
        }

        throw ApifyError.invalidResponse
    }

    enum ApifyError: LocalizedError {
        case invalidURL
        case invalidResponse
        case actorFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Could not construct the Apify actor URL."
            case .invalidResponse:
                return "Apify returned an unexpected response."
            case .actorFailed(let detail):
                return "Apify actor failed: \(detail.prefix(240))"
            }
        }
    }
}
