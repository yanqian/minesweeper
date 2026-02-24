import SwiftUI

struct StatsSummaryView: View {
    @EnvironmentObject private var statsStore: StatsStore
    let mode: ModeID

    var body: some View {
        let stats = statsStore.stats(for: mode)
        let overall = statsStore.overallStats

        VStack(alignment: .leading, spacing: 8) {
            Text("Stats")
                .font(.headline)
            HStack {
                StatPill(title: "Mode Win %", value: formatPercent(stats.successRate))
                StatPill(title: "Overall Win %", value: formatPercent(overall.successRate))
            }
            HStack {
                StatPill(title: "Mode Avg", value: formatSeconds(stats.averageTimeSeconds))
                StatPill(title: "Best", value: formatBest(stats.bestTimeSeconds))
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.0f%%", value * 100)
    }

    private func formatSeconds(_ seconds: Double) -> String {
        guard seconds > 0 else { return "—" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func formatBest(_ seconds: Int?) -> String {
        guard let seconds else { return "—" }
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.001))
    }
}
