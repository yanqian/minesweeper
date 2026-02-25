import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published var showResult: Bool = false
    @Published var resultTitle: String = ""
    @Published var resultMessage: String = ""
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var hasStarted: Bool = false

    private let statsStore: StatsStore
    private(set) var mode: GameMode
    private var timerCancellable: AnyCancellable?
    private var isActive: Bool = true

    init(mode: GameMode, statsStore: StatsStore) {
        self.mode = mode
        self.statsStore = statsStore
        let config = mode.config
        self.state = GameState(
            board: Board(rows: config.rows, cols: config.cols, mines: config.mines),
            status: .playing,
            startedAt: Date(),
            endedAt: nil
        )
    }

    func startNewGame(mode: GameMode? = nil) {
        if let newMode = mode {
            self.mode = newMode
        }
        let config = self.mode.config
        self.state = GameState(
            board: Board(rows: config.rows, cols: config.cols, mines: config.mines),
            status: .playing,
            startedAt: Date(),
            endedAt: nil
        )
        elapsedSeconds = 0
        hasStarted = false
        stopTimer()
        showResult = false
        resultTitle = ""
        resultMessage = ""
    }

    func setActive(_ active: Bool) {
        isActive = active
        if isActive {
            if state.status == .playing, hasStarted {
                startTimer()
            }
        } else {
            stopTimer()
        }
    }

    func toggleFlag(at index: Int) {
        guard state.status == .playing else { return }
        if state.board.cells[index].isRevealed { return }
        state.board.cells[index].isFlagged.toggle()
    }

    func reveal(at index: Int) {
        guard state.status == .playing else { return }
        if state.board.cells[index].isFlagged || state.board.cells[index].isRevealed { return }

        if !hasStarted {
            hasStarted = true
            state.startedAt = Date()
            if isActive {
                startTimer()
            }
        }

        if !state.board.hasPlacedMines {
            placeMines(excluding: index)
        }

        if state.board.cells[index].isMine {
            state.board.cells.indices.forEach { idx in
                if state.board.cells[idx].isMine {
                    state.board.cells[idx].isRevealed = true
                }
            }
            endGame(didWin: false)
            return
        }

        floodReveal(from: index)
        if checkWin() {
            endGame(didWin: true)
        }
    }

    func checkWin() -> Bool {
        return state.board.cells.allSatisfy { cell in
            cell.isMine || cell.isRevealed
        }
    }

    #if DEBUG
    func setBoardForTesting(_ board: Board) {
        state.board = board
    }
    #endif

    private func placeMines(excluding safeIndex: Int) {
        let total = state.board.rows * state.board.cols
        var indices = Array(0..<total)
        indices.removeAll { $0 == safeIndex }
        indices.shuffle()
        let mineIndices = indices.prefix(state.board.mines)

        for idx in mineIndices {
            state.board.cells[idx].isMine = true
        }

        for idx in state.board.cells.indices {
            let count = state.board.neighbors(of: idx).filter { state.board.cells[$0].isMine }.count
            state.board.cells[idx].adjacentMines = count
        }
        state.board.hasPlacedMines = true
    }

    private func floodReveal(from index: Int) {
        var stack = [index]
        while let current = stack.popLast() {
            if state.board.cells[current].isRevealed || state.board.cells[current].isFlagged {
                continue
            }
            state.board.cells[current].isRevealed = true
            if state.board.cells[current].adjacentMines == 0 {
                for neighbor in state.board.neighbors(of: current) {
                    if !state.board.cells[neighbor].isRevealed && !state.board.cells[neighbor].isFlagged {
                        stack.append(neighbor)
                    }
                }
            }
        }
    }

    private func endGame(didWin: Bool) {
        state.status = didWin ? .won : .lost
        state.endedAt = Date()
        stopTimer()

        statsStore.recordGame(mode: mode.id, didWin: didWin, durationSeconds: max(1, elapsedSeconds))

        if didWin {
            resultTitle = "You Win!"
            resultMessage = "Nice work."
            SoundManager.shared.playSuccess()
        } else {
            resultTitle = "Game Over"
            resultMessage = "You hit a mine."
            Haptics.error()
        }
        showResult = true
    }

    private func startTimer() {
        if timerCancellable != nil { return }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.state.status == .playing, self.isActive, self.hasStarted else { return }
                self.elapsedSeconds += 1
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
