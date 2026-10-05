import SwiftUI

struct SourcesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Data sources").font(.largeTitle.bold())
                Text("BuildScout is source-agnostic. Providers normalize into one schema, so legal APIs, feeds, community datasets and user imports can coexist without baking brittle scraping into the app.")
                    .foregroundStyle(.secondary)

                ForEach(SeedData.sources) { source in
                    HStack(alignment: .top, spacing: 18) {
                        Image(systemName: source.status == "Ready" ? "checkmark.circle.fill" : "shippingbox")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(source.name).font(.headline)
                                Text(source.status).font(.caption.bold()).padding(.horizontal, 8).padding(.vertical, 3).background(.quaternary, in: Capsule())
                            }
                            Text(source.method).font(.caption).foregroundStyle(.secondary)
                            Text(source.notes)
                        }
                    }
                    .padding(16)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                }

                GroupBox("Adapter contract") {
                    Text("Every source should emit normalized VehicleListing or PartListing records. Source-specific authentication, rate limits and terms stay isolated inside the adapter.")
                        .padding(8)
                }
            }.padding(28)
        }
    }
}
