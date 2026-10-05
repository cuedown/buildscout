import SwiftUI

struct GarageView: View {
    let tools = [
        ("Socket + breaker bar set", "Owned"),
        ("Impact / drill", "Owned"),
        ("Jack + stands", "Confirm"),
        ("Torque wrench", "Recommended"),
        ("Welder", "Borrow / friend"),
        ("Engine hoist", "Rent / borrow"),
        ("Alignment rack", "Shop")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Garage profile").font(.largeTitle.bold())
                Text("The scoring engine will eventually price builds differently based on what you already own, what you can borrow, and what requires a shop.")
                    .foregroundStyle(.secondary)
                ForEach(tools, id: \.0) { tool in
                    HStack {
                        Label(tool.0, systemImage: "wrench.and.screwdriver")
                        Spacer()
                        Text(tool.1).foregroundStyle(.secondary)
                    }
                    Divider()
                }
            }.padding(28)
        }
    }
}
