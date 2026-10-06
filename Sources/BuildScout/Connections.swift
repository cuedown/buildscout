import Foundation
import Combine

@MainActor
final class ConnectionStore: ObservableObject {
    @Published var serpAPIKey = "" {
        didSet { persistSecret(serpAPIKey, key: "serpapi-key") }
    }

    @Published var tavilyAPIKey = "" {
        didSet { persistSecret(tavilyAPIKey, key: "tavily-api-key") }
    }

    @Published var exaAPIKey = "" {
        didSet { persistSecret(exaAPIKey, key: "exa-api-key") }
    }

    @Published var braveAPIKey = "" {
        didSet { persistSecret(braveAPIKey, key: "brave-search-api-key") }
    }

    @Published var youtubeAPIKey = "" {
        didSet { persistSecret(youtubeAPIKey, key: "youtube-data-api-key") }
    }

    @Published var githubToken = "" {
        didSet { persistSecret(githubToken, key: "github-token") }
    }

    @Published var eBayClientID = "" {
        didSet { persistSecret(eBayClientID, key: "ebay-client-id") }
    }

    @Published var eBayClientSecret = "" {
        didSet { persistSecret(eBayClientSecret, key: "ebay-client-secret") }
    }

    @Published var marketCheckAPIKey = "" {
        didSet { persistSecret(marketCheckAPIKey, key: "marketcheck-api-key") }
    }

    @Published var carsXEAPIKey = "" {
        didSet { persistSecret(carsXEAPIKey, key: "carsxe-api-key") }
    }

    @Published var apifyToken = "" {
        didSet { persistSecret(apifyToken, key: "apify-token") }
    }

    @Published var enableApifyFacebook = false
    @Published var enableApifyKijiji = false
    @Published var enableApifyCraigslist = false
    @Published var enableApifySalvage = false
    @Published var apifyMaxResultsPerSource = 25

    @Published var preferredCountry = "Canada"
    @Published var preferredRegion = "Calgary, Alberta"

    init() {
        serpAPIKey = SecureStore.get("serpapi-key")
        tavilyAPIKey = SecureStore.get("tavily-api-key")
        exaAPIKey = SecureStore.get("exa-api-key")
        braveAPIKey = SecureStore.get("brave-search-api-key")
        youtubeAPIKey = SecureStore.get("youtube-data-api-key")
        githubToken = SecureStore.get("github-token")
        eBayClientID = SecureStore.get("ebay-client-id")
        eBayClientSecret = SecureStore.get("ebay-client-secret")
        marketCheckAPIKey = SecureStore.get("marketcheck-api-key")
        carsXEAPIKey = SecureStore.get("carsxe-api-key")
        apifyToken = SecureStore.get("apify-token")
    }

    var hasSerpAPI: Bool { has(serpAPIKey) }
    var hasTavily: Bool { has(tavilyAPIKey) }
    var hasExa: Bool { has(exaAPIKey) }
    var hasBrave: Bool { has(braveAPIKey) }
    var hasYouTube: Bool { has(youtubeAPIKey) }
    var hasGitHub: Bool { has(githubToken) }

    var hasEBay: Bool {
        has(eBayClientID) && has(eBayClientSecret)
    }

    var hasMarketCheck: Bool { has(marketCheckAPIKey) }
    var hasCarsXE: Bool { has(carsXEAPIKey) }
    var hasApify: Bool { has(apifyToken) }

    var connectedFreeSearchProviderCount: Int {
        [hasSerpAPI, hasTavily, hasExa, hasBrave].filter { $0 }.count
    }

    var hasAnyWebSearch: Bool {
        hasSerpAPI || hasTavily || hasExa || hasBrave
    }

    private func has(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func persistSecret(_ value: String, key: String) {
        if value != SecureStore.get(key) {
            SecureStore.set(value, for: key)
        }
    }
}

enum ProviderStatus: String {
    case live = "LIVE"
    case configured = "CONFIGURED"
    case needsKey = "NEEDS KEY"
    case directoryOnly = "DIRECTORY"
}
