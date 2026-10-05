import Foundation

struct BrowserCaptureItem: Codable, Hashable, Identifiable {
    let url: String
    let title: String
    let text: String

    var id: String {
        url.isEmpty ? "\(title)|\(text.prefix(64))" : url
    }
}

struct BrowserCapture: Identifiable, Hashable {
    let id = UUID()
    let pageURL: String
    let title: String
    let text: String
    let source: String
    let items: [BrowserCaptureItem]
    let capturedAt: Date
}

enum BrowserCaptureURLHandler {
    @MainActor
    static func handle(_ url: URL, store: ListingStore) {
        guard url.scheme?.lowercased() == "buildscout",
              url.host?.lowercased() == "capture",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let encoded = components.queryItems?.first(where: { $0.name == "data" })?.value,
              let data = decodeBase64URL(encoded),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return
        }

        let capture = BrowserCapture(
            pageURL: payload.url,
            title: payload.title,
            text: payload.text,
            source: sourceName(for: payload.url),
            items: payload.items ?? [],
            capturedAt: Date()
        )
        store.receiveBrowserCapture(capture)
    }

    private static func sourceName(for rawURL: String) -> String {
        guard let host = URL(string: rawURL)?.host?.lowercased() else {
            return "Browser capture"
        }

        if host.contains("facebook.") { return "Facebook Marketplace • browser capture" }
        if host.contains("kijiji.") { return "Kijiji • browser capture" }
        if host.contains("craigslist.") { return "Craigslist • browser capture" }
        if host.contains("autotrader.") { return "AutoTrader • browser capture" }
        if host.contains("copart.") { return "Copart • browser capture" }
        if host.contains("iaai.") { return "IAA • browser capture" }
        if host.contains("ebay.") { return "eBay • browser capture" }

        return "\(host) • browser capture"
    }

    private static func decodeBase64URL(_ raw: String) -> Data? {
        var base64 = raw
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder != 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: base64)
    }

    private struct Payload: Decodable {
        let url: String
        let title: String
        let text: String
        let items: [BrowserCaptureItem]?
    }
}
