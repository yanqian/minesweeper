import XCTest
@testable import Minesweeper

@MainActor
final class BoardGenerationTests: XCTestCase {
    func testFirstRevealPlacesMinesAndIsSafe() {
        let statsStore = StatsStore()
        let viewModel = GameViewModel(mode: .easy, statsStore: statsStore)

        let safeIndex = 0
        viewModel.reveal(at: safeIndex)

        XCTAssertTrue(viewModel.state.board.hasPlacedMines)
        XCTAssertFalse(viewModel.state.board.cells[safeIndex].isMine)

        let mineCount = viewModel.state.board.cells.filter { $0.isMine }.count
        XCTAssertEqual(mineCount, viewModel.state.board.mines)
    }

    func testAdjacentMineCountsAreAccurate() {
        let statsStore = StatsStore()
        let viewModel = GameViewModel(mode: .easy, statsStore: statsStore)

        viewModel.reveal(at: 0)
        let board = viewModel.state.board

        for cell in board.cells {
            let expected = board.neighbors(of: cell.id).filter { board.cells[$0].isMine }.count
            XCTAssertEqual(cell.adjacentMines, expected, "Adjacent count mismatch at index \(cell.id)")
        }
    }
}
