import SwiftUI

struct ApifyConnectionCard: View {
    @EnvironmentObject private var connections: ConnectionStore

    var body: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apify marketplace actors")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("Optional third-party API layer for Facebook Marketplace, Kijiji, Craigslist, Copart and IAA.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)
                    }
                    Spacer()
                    Text(connections.hasApify ? "CONNECTED" : "OPTIONAL TOKEN")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(connections.hasApify ? BuildScoutTheme.success : BuildScoutTheme.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (connections.hasApify ? BuildScoutTheme.success : BuildScoutTheme.warning)
                                .opacity(0.1),
                            in: Capsule()
                        )
                }

                SecureField("Apify API token", text: $connections.apifyToken)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 11)
                    .frame(height: 38)
                    .background(BuildScoutTheme.background, in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(BuildScoutTheme.border))

                Text("Runs are opt-in because actors can consume credits. Credentials stay in macOS Keychain.")
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.faint)

                HStack(spacing: 14) {
                    Toggle("Facebook", isOn: $connections.enableApifyFacebook)
                    Toggle("Kijiji", isOn: $connections.enableApifyKijiji)
                    Toggle("Craigslist", isOn: $connections.enableApifyCraigslist)
                    Toggle("Copart / IAA", isOn: $connections.enableApifySalvage)
                }

                HStack {
                    Text("MAX RESULTS / SOURCE")
                        .font(.caption2.bold())
                        .foregroundStyle(BuildScoutTheme.faint)

                    Stepper(
                        value: $connections.apifyMaxResultsPerSource,
                        in: 5...100,
                        step: 5
                    ) {
                        Text("\(connections.apifyMaxResultsPerSource)")
                            .font(.caption.bold())
                    }

                    Spacer()

                    Link(
                        "Apify Console",
                        destination: URL(string: "https://console.apify.com/")!
                    )
                    .font(.caption.bold())
                }
            }
        }
    }
}
