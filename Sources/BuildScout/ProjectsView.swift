import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var store: ListingStore
    @State private var selectedID: UUID?

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                HStack {
                    Text("Builds").font(.title2.bold())
                    Spacer()
                    Text("\(store.projects.count)").foregroundStyle(.secondary)
                }
                .padding()

                if store.projects.isEmpty {
                    ContentUnavailableView(
                        "No active builds",
                        systemImage: "wrench.and.screwdriver",
                        description: Text("Open a candidate and choose Start build.")
                    )
                } else {
                    List(selection: $selectedID) {
                        ForEach(store.projects) { project in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(project.name).font(.headline)
                                ProgressView(value: project.completionFraction)
                                HStack {
                                    Text(project.actualSpent.formatted(.currency(code: "CAD").precision(.fractionLength(0))))
                                    Text("spent")
                                    Text("•")
                                    Text("\(Int(project.completionFraction * 100))%")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 5)
                            .tag(project.id)
                        }
                    }
                }
            }
            .frame(minWidth: 340)

            if let binding = selectedProjectBinding {
                ProjectDetail(project: binding)
            } else if let first = store.projects.first,
                      let index = store.projects.firstIndex(where: { $0.id == first.id }) {
                ProjectDetail(project: $store.projects[index])
            } else {
                ContentUnavailableView("Pick a build", systemImage: "wrench")
            }
        }
        .navigationTitle("Projects")
    }

    private var selectedProjectBinding: Binding<BuildProject>? {
        guard let selectedID,
              let index = store.projects.firstIndex(where: { $0.id == selectedID }) else {
            return nil
        }
        return $store.projects[index]
    }
}

private struct ProjectDetail: View {
    @EnvironmentObject private var store: ListingStore
    @Binding var project: BuildProject

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name).font(.largeTitle.bold())
                        Text(project.vehicle.location).foregroundStyle(.secondary)
                    }
                    Spacer()
                    ProgressView(value: project.completionFraction)
                        .frame(width: 150)
                }

                HStack {
                    ProjectMetric(
                        title: "TARGET",
                        value: project.targetBudget.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
                    )
                    ProjectMetric(
                        title: "ESTIMATE",
                        value: project.estimatedTotal.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
                    )
                    ProjectMetric(
                        title: "ACTUAL",
                        value: project.actualSpent.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
                    )
                    ProjectMetric(
                        title: "PROGRESS",
                        value: "\(Int(project.completionFraction * 100))%"
                    )
                }

                if project.actualSpent > project.targetBudget {
                    Label(
                        "Actual spending is over target by \((project.actualSpent - project.targetBudget).formatted(.currency(code: "CAD").precision(.fractionLength(0)))).",
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Build ledger").font(.title2.bold())
                        Spacer()
                        Button {
                            project.tasks.append(
                                ProjectTask(
                                    title: "New item",
                                    category: "Custom",
                                    estimatedCost: 0,
                                    actualCost: nil,
                                    required: false
                                )
                            )
                        } label: {
                            Label("Add item", systemImage: "plus")
                        }
                    }

                    ForEach($project.tasks) { $task in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    TextField("Item", text: $task.title)
                                        .font(.headline)
                                        .textFieldStyle(.plain)
                                    TextField("Category", text: $task.category)
                                        .font(.caption)
                                        .textFieldStyle(.plain)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Picker("Status", selection: $task.status) {
                                    ForEach(ProjectTaskStatus.allCases) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 120)
                            }

                            HStack {
                                Text("Estimate")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(task.estimatedCost.formatted(.currency(code: "CAD").precision(.fractionLength(0))))

                                if let sourceURL = task.sourceURL,
                                   let url = URL(string: sourceURL),
                                   !sourceURL.isEmpty {
                                    Link(destination: url) {
                                        Label(
                                            task.sourceProvider ?? "Source",
                                            systemImage: "arrow.up.right.square"
                                        )
                                        .font(.caption2.bold())
                                    }
                                    .help(task.sourceTitle ?? sourceURL)
                                }

                                Spacer()

                                Text("Actual")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TextField(
                                    "Actual",
                                    value: $task.actualCost,
                                    format: .number
                                )
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            }
                        }
                        .padding(.vertical, 6)
                        Divider()
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes").font(.title2.bold())
                    TextEditor(text: $project.notes)
                        .frame(minHeight: 110)
                        .padding(6)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                }

                HStack {
                    Menu {
                        Button("Markdown") {
                            ProjectExporter.saveMarkdown(project)
                        }
                        Button("JSON") {
                            ProjectExporter.saveJSON(project)
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Spacer()

                    Button("Delete project", role: .destructive) {
                        store.removeProject(project.id)
                    }
                }
            }
            .padding(28)
        }
    }
}

private struct ProjectMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption2.bold()).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
