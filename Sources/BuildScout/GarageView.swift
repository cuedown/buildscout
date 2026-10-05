import SwiftUI

struct GarageView: View {
    @EnvironmentObject private var store: ListingStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Garage profile").font(.largeTitle.bold())
                    Text("BuildScout uses this to distinguish a cheap DIY project from a cheap listing that becomes an expensive shop bill.")
                        .foregroundStyle(.secondary)
                }

                GroupBox("Experience") {
                    VStack(spacing: 18) {
                        SkillRow(title: "Basic mechanics", level: $store.garage.basicMechanics)
                        SkillRow(title: "Fabrication", level: $store.garage.fabrication)
                        SkillRow(title: "Welding", level: $store.garage.welding)
                        SkillRow(title: "Electrical / diagnostics", level: $store.garage.electrical)
                        SkillRow(title: "Engine / transmission swaps", level: $store.garage.drivetrainSwaps)
                    }
                    .padding(8)
                }

                GroupBox("Access") {
                    HStack(spacing: 24) {
                        Toggle("Can tow projects", isOn: $store.garage.canTow)
                        Toggle("Mechanic friends / help", isOn: $store.garage.hasMechanicFriends)
                        Toggle("Garage space", isOn: $store.garage.hasGarageSpace)
                    }
                    .padding(8)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Tools").font(.title2.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                        ForEach(GarageTool.allCases) { tool in
                            ToolToggle(
                                tool: tool,
                                owned: Binding(
                                    get: { store.garage.tools.contains(tool) },
                                    set: { value in
                                        if value {
                                            store.garage.tools.insert(tool)
                                        } else {
                                            store.garage.tools.remove(tool)
                                        }
                                    }
                                )
                            )
                        }
                    }
                }

                GroupBox("How this changes estimates") {
                    Text("Missing core tools add a purchase contingency. Non-runners become riskier when diagnosis experience is low. Transmission swaps can trigger outside-labour reserves. Access to experienced mechanic help reduces that penalty.")
                        .padding(8)
                }
            }
            .padding(28)
        }
    }
}

private struct SkillRow: View {
    let title: String
    @Binding var level: Int

    var body: some View {
        HStack {
            Text(title)
                .frame(width: 190, alignment: .leading)

            Slider(
                value: Binding(
                    get: { Double(level) },
                    set: { level = Int($0.rounded()) }
                ),
                in: 0...5,
                step: 1
            )

            Text(skillLabel(level))
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)
        }
    }

    private func skillLabel(_ level: Int) -> String {
        switch level {
        case 0: return "None"
        case 1: return "Beginner"
        case 2: return "DIY"
        case 3: return "Comfortable"
        case 4: return "Advanced"
        default: return "Expert"
        }
    }
}

private struct ToolToggle: View {
    let tool: GarageTool
    @Binding var owned: Bool

    var body: some View {
        Toggle(isOn: $owned) {
            VStack(alignment: .leading, spacing: 3) {
                Text(tool.rawValue).font(.headline)
                Text(tool.category).font(.caption).foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.checkbox)
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}
