import SwiftUI

struct CollapsibleStatsView: View {
    let mode: ModeID
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Stats")
                    .font(.headline)
                Spacer()
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .padding(6)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel(isExpanded ? "Hide stats" : "Show stats")
            }

            if isExpanded {
                StatsSummaryView(mode: mode)
            } else {
                CompactStatsRow(mode: mode)
            }
        }
    }
}

struct CompactStatsRow: View {
    @EnvironmentObject private var statsStore: StatsStore
    let mode: ModeID

    var body: some View {
        let stats = statsStore.stats(for: mode)
        let overall = statsStore.overallStats

        HStack {
            CompactStatPill(title: "Win %", value: StatsFormatter.percent(stats.successRate))
            CompactStatPill(title: "Best", value: StatsFormatter.best(stats.bestTimeSeconds))
            CompactStatPill(title: "Overall", value: StatsFormatter.percent(overall.successRate))
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CompactStatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatsSummaryView: View {
    @EnvironmentObject private var statsStore: StatsStore
    let mode: ModeID

    var body: some View {
        let stats = statsStore.stats(for: mode)
        let overall = statsStore.overallStats

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatPill(title: "Mode Win %", value: StatsFormatter.percent(stats.successRate))
                StatPill(title: "Overall Win %", value: StatsFormatter.percent(overall.successRate))
            }
            HStack {
                StatPill(title: "Mode Avg", value: StatsFormatter.seconds(stats.averageTimeSeconds))
                StatPill(title: "Best", value: StatsFormatter.best(stats.bestTimeSeconds))
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

private enum StatsFormatter {
    static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    static func seconds(_ seconds: Double) -> String {
        guard seconds > 0 else { return "—" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    static func best(_ seconds: Int?) -> String {
        guard let seconds else { return "—" }
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
