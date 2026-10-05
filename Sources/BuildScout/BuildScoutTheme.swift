import SwiftUI

enum BuildScoutTheme {
    static let background = Color(red: 0.045, green: 0.05, blue: 0.06)
    static let sidebar = Color(red: 0.07, green: 0.075, blue: 0.085)
    static let surface = Color(red: 0.09, green: 0.095, blue: 0.105)
    static let raised = Color(red: 0.115, green: 0.12, blue: 0.135)
    static let border = Color.white.opacity(0.09)
    static let accent = Color(red: 1.0, green: 0.46, blue: 0.08)
    static let success = Color(red: 0.30, green: 0.86, blue: 0.52)
    static let warning = Color(red: 1.0, green: 0.72, blue: 0.22)
    static let muted = Color.white.opacity(0.58)
    static let faint = Color.white.opacity(0.34)

    static let cardRadius: CGFloat = 14
    static let panelRadius: CGFloat = 18
}

struct ScoutPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: BuildScoutTheme.panelRadius, style: .continuous)
                    .fill(BuildScoutTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BuildScoutTheme.panelRadius, style: .continuous)
                    .stroke(BuildScoutTheme.border, lineWidth: 1)
            )
    }
}

struct ScoutEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1.7)
            .foregroundStyle(BuildScoutTheme.accent)
    }
}

struct ScoutMetric: View {
    let label: String
    let value: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(BuildScoutTheme.faint)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(BuildScoutTheme.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
