import Foundation

enum GameStatus {
    case playing
    case won
    case lost
}

struct CustomConfig: Codable, Equatable {
    var rows: Int
    var cols: Int
    var mines: Int
}

enum GameMode: Equatable {
    case easy
    case medium
    case hard
    case custom(CustomConfig)

    var id: ModeID {
        switch self {
        case .easy: return .easy
        case .medium: return .medium
        case .hard: return .hard
        case .custom: return .custom
        }
    }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .custom: return "Custom"
        }
    }

    var config: CustomConfig {
        switch self {
        case .easy:
            return CustomConfig(rows: 9, cols: 9, mines: 10)
        case .medium:
            return CustomConfig(rows: 16, cols: 16, mines: 40)
        case .hard:
            return CustomConfig(rows: 16, cols: 30, mines: 99)
        case .custom(let config):
            return config
        }
    }
}

enum ModeID: String, Codable, CaseIterable {
    case easy
    case medium
    case hard
    case custom

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .custom: return "Custom"
        }
    }
}

struct Cell: Identifiable {
    let id: Int
    var isMine: Bool
    var isRevealed: Bool
    var isFlagged: Bool
    var adjacentMines: Int
}

struct Board {
    let rows: Int
    let cols: Int
    let mines: Int
    var cells: [Cell]
    var hasPlacedMines: Bool

    init(rows: Int, cols: Int, mines: Int) {
        self.rows = rows
        self.cols = cols
        self.mines = mines
        self.hasPlacedMines = false
        let total = rows * cols
        self.cells = (0..<total).map { index in
            Cell(id: index, isMine: false, isRevealed: false, isFlagged: false, adjacentMines: 0)
        }
    }

    func index(row: Int, col: Int) -> Int {
        return row * cols + col
    }

    func rowCol(for index: Int) -> (row: Int, col: Int) {
        return (index / cols, index % cols)
    }

    func neighbors(of index: Int) -> [Int] {
        let (row, col) = rowCol(for: index)
        var results: [Int] = []
        for r in max(0, row - 1)...min(rows - 1, row + 1) {
            for c in max(0, col - 1)...min(cols - 1, col + 1) {
                if r == row && c == col { continue }
                results.append(self.index(row: r, col: c))
            }
        }
        return results
    }
}

struct GameState {
    var board: Board
    var status: GameStatus
    var startedAt: Date
    var endedAt: Date?
}
