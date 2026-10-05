import SwiftUI
import AppKit

struct BrowserCaptureConnectionCard: View {
    @State private var message: String?

    var body: some View {
        ScoutPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Browser Capture bridge")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("One-click ingestion from pages you are already viewing in Firefox, Chrome, Edge or Brave.")
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.muted)
                    }

                    Spacer()

                    Text("LOCAL")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(BuildScoutTheme.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(BuildScoutTheme.success.opacity(0.1), in: Capsule())
                }

                HStack(spacing: 12) {
                    feature("CURRENT LISTING", "doc.text.magnifyingglass")
                    feature("VISIBLE RESULTS", "rectangle.grid.2x2")
                    feature("NO COOKIE EXPORT", "lock.shield.fill")
                    feature("LOCAL DEEP LINK", "arrow.down.app.fill")
                }

                Text("Use this when a marketplace does not provide a buyer-side API. The extension can capture one listing or the result cards already rendered in the current tab. It does not silently paginate or run in the background.")
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.muted)

                HStack {
                    Button {
                        openExtensionFolder()
                    } label: {
                        Label("OPEN EXTENSION FOLDER", systemImage: "folder.fill")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.5)
                    }
                    .buttonStyle(.borderedProminent)

                    if let message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(BuildScoutTheme.faint)
                    }

                    Spacer()
                }
            }
        }
    }

    private func feature(_ label: String, _ icon: String) -> some View {
        Label(label, systemImage: icon)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(BuildScoutTheme.muted)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(BuildScoutTheme.background, in: Capsule())
    }

    private func openExtensionFolder() {
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent("BrowserExtension"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("browser-extension")
        ]

        guard let folder = candidates.compactMap({ $0 }).first(where: {
            FileManager.default.fileExists(atPath: $0.path)
        }) else {
            message = "Extension folder was not found in this build."
            return
        }

        NSWorkspace.shared.open(folder)
        message = "Opened. Load manifest.json as a temporary/unpacked extension."
    }
}
