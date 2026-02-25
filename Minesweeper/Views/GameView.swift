import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel

    init(mode: GameMode, statsStore: StatsStore) {
        _viewModel = StateObject(wrappedValue: GameViewModel(mode: mode, statsStore: statsStore))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                GameHeaderView(modeTitle: viewModel.mode.title, state: viewModel.state)
                GameBoardView(viewModel: viewModel)
                CollapsibleStatsView(mode: viewModel.mode.id)
            }
            .padding(.horizontal, 16)
            .padding(.top, 80)
            .padding(.bottom, 24)
        }
        .alert(viewModel.resultTitle, isPresented: $viewModel.showResult) {
            Button("New Game") {
                viewModel.startNewGame()
            }
        } message: {
            Text(viewModel.resultMessage)
        }
    }
}

struct GameHeaderView: View {
    let modeTitle: String
    let state: GameState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(modeTitle)
                    .font(.title2.weight(.bold))
                Text("Minesweeper")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ElapsedTimeView(state: state)
        }
    }
}

struct ElapsedTimeView: View {
    let state: GameState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            Text(elapsedString)
                .font(.headline.monospacedDigit())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private var elapsedString: String {
        let end = state.endedAt ?? Date()
        let seconds = max(0, Int(end.timeIntervalSince(state.startedAt)))
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var zoomScale: CGFloat = 1.0
    @State private var gestureScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let availableHeight = proxy.size.height
            let rows = viewModel.state.board.rows
            let cols = viewModel.state.board.cols
            let rawSize = min(availableWidth / CGFloat(cols), availableHeight / CGFloat(rows))
            let cellSize = max(16, rawSize - 2)
            let effectiveScale = clampScale(zoomScale * gestureScale)

            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 2), count: cols), spacing: 2) {
                    ForEach(viewModel.state.board.cells) { cell in
                        CellView(cell: cell, size: cellSize)
                            .onTapGesture {
                                viewModel.reveal(at: cell.id)
                            }
                            .onLongPressGesture {
                                viewModel.toggleFlag(at: cell.id)
                            }
                    }
                }
                .padding(8)
                .scaleEffect(effectiveScale, anchor: .center)
            }
        }
        .frame(maxHeight: 420)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    gestureScale = value
                }
                .onEnded { value in
                    zoomScale = clampScale(zoomScale * value)
                    gestureScale = 1.0
                }
        )
    }

    private func clampScale(_ scale: CGFloat) -> CGFloat {
        min(2.0, max(0.8, scale))
    }
}
