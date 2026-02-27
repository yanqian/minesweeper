import SwiftUI

struct StatsOverlay: View {
    @EnvironmentObject private var statsStore: StatsStore
    let mode: ModeID
    @State private var showDetails = false

    var body: some View {
        let stats = statsStore.stats(for: mode)

        Button {
            showDetails = true
        } label: {
            HStack(spacing: 10) {
                StatChip(title: "Win", value: StatsFormatter.percent(stats.successRate))
                StatChip(title: "Best", value: StatsFormatter.best(stats.bestTimeSeconds))
                StatChip(title: "Played", value: "\(stats.gamesPlayed)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetails) {
            StatsSheet(mode: mode)
        }
        .accessibilityLabel("Show stats")
    }
}

struct StatChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 10))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.custom("AvenirNext-DemiBold", size: 14))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatsSheet: View {
    let mode: ModeID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                StatsSummaryView(mode: mode)
                Spacer()
            }
            .padding(16)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

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

        HStack {
            CompactStatPill(title: "Played", value: "\(stats.gamesPlayed)")
            CompactStatPill(title: "Won", value: "\(stats.gamesWon)")
            CompactStatPill(title: "Win %", value: StatsFormatter.percent(stats.successRate))
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
                .font(.custom("AvenirNext-Medium", size: 11))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.custom("AvenirNext-DemiBold", size: 14))
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
            HStack {
                StatPill(title: "Played", value: "\(stats.gamesPlayed)")
                StatPill(title: "Won", value: "\(stats.gamesWon)")
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
                .font(.custom("AvenirNext-Medium", size: 11))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.custom("AvenirNext-DemiBold", size: 15))
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
