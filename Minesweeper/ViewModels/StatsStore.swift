import Foundation

struct ModeStats: Codable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalTimeSeconds: Int = 0
    var bestTimeSeconds: Int? = nil
    var lastPlayedAt: Date? = nil

    var successRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }

    var averageTimeSeconds: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(totalTimeSeconds) / Double(gamesPlayed)
    }
}

struct StatsSnapshot: Codable {
    var modeStats: [String: ModeStats]
    var overall: ModeStats
    var schemaVersion: Int = 1
}

@MainActor
final class StatsStore: ObservableObject {
    @Published private(set) var modeStats: [ModeID: ModeStats] = [:]
    @Published private(set) var overallStats: ModeStats = ModeStats()

    private let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Minesweeper", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.fileURL = dir.appendingPathComponent("stats.json")
        load()
    }

    func stats(for mode: ModeID) -> ModeStats {
        return modeStats[mode] ?? ModeStats()
    }

    func recordGame(mode: ModeID, didWin: Bool, durationSeconds: Int) {
        var stats = modeStats[mode] ?? ModeStats()
        stats.gamesPlayed += 1
        if didWin { stats.gamesWon += 1 }
        stats.totalTimeSeconds += durationSeconds
        if let best = stats.bestTimeSeconds {
            stats.bestTimeSeconds = min(best, durationSeconds)
        } else {
            stats.bestTimeSeconds = durationSeconds
        }
        stats.lastPlayedAt = Date()
        modeStats[mode] = stats

        var overall = overallStats
        overall.gamesPlayed += 1
        if didWin { overall.gamesWon += 1 }
        overall.totalTimeSeconds += durationSeconds
        if let best = overall.bestTimeSeconds {
            overall.bestTimeSeconds = min(best, durationSeconds)
        } else {
            overall.bestTimeSeconds = durationSeconds
        }
        overall.lastPlayedAt = Date()
        overallStats = overall

        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            modeStats = Dictionary(uniqueKeysWithValues: ModeID.allCases.map { ($0, ModeStats()) })
            overallStats = ModeStats()
            return
        }
        guard let snapshot = try? JSONDecoder().decode(StatsSnapshot.self, from: data) else {
            modeStats = Dictionary(uniqueKeysWithValues: ModeID.allCases.map { ($0, ModeStats()) })
            overallStats = ModeStats()
            return
        }

        var loaded: [ModeID: ModeStats] = [:]
        for mode in ModeID.allCases {
            loaded[mode] = snapshot.modeStats[mode.rawValue] ?? ModeStats()
        }
        modeStats = loaded
        overallStats = snapshot.overall
    }

    private func save() {
        let snapshot = StatsSnapshot(
            modeStats: Dictionary(uniqueKeysWithValues: modeStats.map { ($0.key.rawValue, $0.value) }),
            overall: overallStats
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL)
    }
}
