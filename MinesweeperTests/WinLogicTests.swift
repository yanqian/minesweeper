import XCTest
@testable import Minesweeper

@MainActor
final class WinLogicTests: XCTestCase {
    func testWinWhenAllSafeCellsRevealed() {
        let statsStore = StatsStore()
        let viewModel = GameViewModel(mode: .easy, statsStore: statsStore)

        var board = Board(rows: 2, cols: 2, mines: 1)
        board.cells[0].isMine = true
        board.cells[1].isRevealed = true
        board.cells[2].isRevealed = true
        board.cells[3].isRevealed = true

        viewModel.setBoardForTesting(board)

        XCTAssertTrue(viewModel.checkWin())
    }

    func testNotWinWhenSafeCellHidden() {
        let statsStore = StatsStore()
        let viewModel = GameViewModel(mode: .easy, statsStore: statsStore)

        var board = Board(rows: 2, cols: 2, mines: 1)
        board.cells[0].isMine = true
        board.cells[1].isRevealed = true
        board.cells[2].isRevealed = false
        board.cells[3].isRevealed = true

        viewModel.setBoardForTesting(board)

        XCTAssertFalse(viewModel.checkWin())
    }
}
