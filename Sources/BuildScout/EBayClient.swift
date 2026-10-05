import Foundation

private struct EBayTokenResponse: Decodable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}

private struct EBayBrowseResponse: Decodable {
    let itemSummaries: [EBayItemSummary]?
}

private struct EBayItemSummary: Decodable {
    let itemId: String?
    let title: String
    let itemWebUrl: String?
    let image: EBayImage?
    let price: EBayMoney?
    let condition: String?
    let itemLocation: EBayItemLocation?
}

private struct EBayImage: Decodable {
    let imageUrl: String?
}

private struct EBayMoney: Decodable {
    let value: String?
    let currency: String?
}

private struct EBayItemLocation: Decodable {
    let city: String?
    let stateOrProvince: String?
    let country: String?
}

enum EBayClient {
    static func search(
        query: String,
        clientID: String,
        clientSecret: String
    ) async throws -> [HuntResult] {
        let token = try await applicationToken(clientID: clientID, clientSecret: clientSecret)

        var components = URLComponents(string: "https://api.ebay.com/buy/browse/v1/item_summary/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "sort", value: "price")
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 20
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("EBAY_CA", forHTTPHeaderField: "X-EBAY-C-MARKETPLACE-ID")
        request.setValue("en-CA", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw EBayError.searchFailed
        }

        let decoded = try JSONDecoder().decode(EBayBrowseResponse.self, from: data)
        return (decoded.itemSummaries ?? []).map { item in
            let location = [item.itemLocation?.city, item.itemLocation?.stateOrProvince, item.itemLocation?.country]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")

            return HuntResult(
                provider: "eBay Browse API",
                kind: .part,
                title: item.title,
                url: item.itemWebUrl ?? "",
                snippet: item.condition ?? "",
                price: item.price?.value.flatMap(Double.init),
                currency: item.price?.currency,
                location: location.isEmpty ? nil : location,
                thumbnailURL: item.image?.imageUrl,
                sourceDomain: "ebay.ca"
            )
        }
    }

    private static func applicationToken(
        clientID: String,
        clientSecret: String
    ) async throws -> String {
        guard let url = URL(string: "https://api.ebay.com/identity/v1/oauth2/token") else {
            throw EBayError.tokenFailed
        }

        let credentials = Data("\(clientID):\(clientSecret)".utf8).base64EncodedString()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let scope = "https://api.ebay.com/oauth/api_scope"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        request.httpBody = Data("grant_type=client_credentials&scope=\(scope)".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw EBayError.tokenFailed
        }

        return try JSONDecoder().decode(EBayTokenResponse.self, from: data).access_token
    }

    enum EBayError: LocalizedError {
        case tokenFailed
        case searchFailed

        var errorDescription: String? {
            switch self {
            case .tokenFailed: return "eBay OAuth token request failed."
            case .searchFailed: return "eBay Browse search failed."
            }
        }
    }
}
