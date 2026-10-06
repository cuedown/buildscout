import Foundation

actor BankOfCanadaFXClient {
    static let shared = BankOfCanadaFXClient()

    private var usdToCADCache: (rate: Double, fetchedAt: Date)?

    func usdToCAD() async -> Double? {
        if let cached = usdToCADCache,
           Date().timeIntervalSince(cached.fetchedAt) < 12 * 60 * 60 {
            return cached.rate
        }

        guard var components = URLComponents(
            string: "https://www.bankofcanada.ca/valet/observations/FXUSDCAD/json"
        ) else { return nil }

        components.queryItems = [
            URLQueryItem(name: "recent", value: "1")
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "BuildScout/0.3 (currency normalization)",
            forHTTPHeaderField: "User-Agent"
        )

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let observations = object["observations"] as? [[String: Any]],
              let latest = observations.last,
              let series = latest["FXUSDCAD"] as? [String: Any],
              let value = series["v"] as? String,
              let rate = Double(value),
              rate > 0 else {
            return nil
        }

        usdToCADCache = (rate, Date())
        return rate
    }

    func normalizeToCAD(_ results: [HuntResult]) async -> [HuntResult] {
        guard results.contains(where: {
            ($0.currency ?? "").uppercased() == "USD" && $0.price != nil
        }) else {
            return results
        }

        guard let rate = await usdToCAD() else {
            return results
        }

        return results.map { result in
            guard (result.currency ?? "").uppercased() == "USD",
                  let price = result.price else {
                return result
            }

            var copy = result
            copy.price = price * rate
            copy.currency = "CAD"
            copy.snippet = copy.snippet.isEmpty
                ? "Converted from USD at Bank of Canada daily FX"
                : copy.snippet + " • Converted from USD at Bank of Canada daily FX"
            return copy
        }
    }
}
