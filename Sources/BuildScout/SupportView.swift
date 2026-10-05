import SwiftUI

struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Keep it free").font(.largeTitle.bold())
                Text("BuildScout is free and open source. No paywall is required to find or plan a build.")
                    .foregroundStyle(.secondary)
                GroupBox("Support links") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ko-fi and optional crypto donation addresses can live here once configured by the project maintainer.")
                        Text("No donation address is hard-coded in the repository until it is explicitly supplied.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }.padding(8)
                }
                Text("The better contribution is often data: new source adapters, compatibility facts, real build costs, and corrections.")
                    .font(.headline)
            }.padding(28)
        }
    }
}
