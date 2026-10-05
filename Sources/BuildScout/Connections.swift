import Foundation
import Combine

@MainActor
final class ConnectionStore: ObservableObject {
    @Published var serpAPIKey = "" {
        didSet {
            if serpAPIKey != SecureStore.get("serpapi-key") {
                SecureStore.set(serpAPIKey, for: "serpapi-key")
            }
        }
    }

    @Published var eBayClientID = "" {
        didSet {
            if eBayClientID != SecureStore.get("ebay-client-id") {
                SecureStore.set(eBayClientID, for: "ebay-client-id")
            }
        }
    }

    @Published var eBayClientSecret = "" {
        didSet {
            if eBayClientSecret != SecureStore.get("ebay-client-secret") {
                SecureStore.set(eBayClientSecret, for: "ebay-client-secret")
            }
        }
    }

    @Published var marketCheckAPIKey = "" {
        didSet {
            if marketCheckAPIKey != SecureStore.get("marketcheck-api-key") {
                SecureStore.set(marketCheckAPIKey, for: "marketcheck-api-key")
            }
        }
    }

    @Published var carsXEAPIKey = "" {
        didSet {
            if carsXEAPIKey != SecureStore.get("carsxe-api-key") {
                SecureStore.set(carsXEAPIKey, for: "carsxe-api-key")
            }
        }
    }

    @Published var apifyToken = "" {
        didSet {
            if apifyToken != SecureStore.get("apify-token") {
                SecureStore.set(apifyToken, for: "apify-token")
            }
        }
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
        eBayClientID = SecureStore.get("ebay-client-id")
        eBayClientSecret = SecureStore.get("ebay-client-secret")
        marketCheckAPIKey = SecureStore.get("marketcheck-api-key")
        carsXEAPIKey = SecureStore.get("carsxe-api-key")
        apifyToken = SecureStore.get("apify-token")
    }

    var hasSerpAPI: Bool { !serpAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var hasEBay: Bool {
        !eBayClientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !eBayClientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var hasMarketCheck: Bool {
        !marketCheckAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var hasCarsXE: Bool {
        !carsXEAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var hasApify: Bool {
        !apifyToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum ProviderStatus: String {
    case live = "LIVE"
    case configured = "CONFIGURED"
    case needsKey = "NEEDS KEY"
    case directoryOnly = "DIRECTORY"
}
