import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    let isActive: Bool
    let onPlayingChanged: (Bool) -> Void
    let onElapsedChanged: (Int) -> Void
    let onZoomChanged: (Bool) -> Void
    @State private var isZoomed = false

    init(
        mode: GameMode,
        statsStore: StatsStore,
        isActive: Bool,
        onPlayingChanged: @escaping (Bool) -> Void = { _ in },
        onElapsedChanged: @escaping (Int) -> Void = { _ in },
        onZoomChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: GameViewModel(mode: mode, statsStore: statsStore))
        self.isActive = isActive
        self.onPlayingChanged = onPlayingChanged
        self.onElapsedChanged = onElapsedChanged
        self.onZoomChanged = onZoomChanged
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: isZoomed ? 0 : 12) {
                GameBoardView(viewModel: viewModel, isZoomed: $isZoomed)
                if !isZoomed {
                    CollapsibleStatsView(mode: viewModel.mode.id)
                }
            }
            .padding(.horizontal, isZoomed ? 0 : 16)
            .padding(.top, isZoomed ? 0 : 16)
            .padding(.bottom, isZoomed ? 0 : 24)
            .ignoresSafeArea(edges: isZoomed ? .top : [])
        }
        .alert(viewModel.resultTitle, isPresented: $viewModel.showResult) {
            Button("New Game") {
                viewModel.startNewGame()
            }
        } message: {
            Text(viewModel.resultMessage)
        }
        .onAppear { viewModel.setActive(isActive) }
        .onChange(of: isActive) { value in
            viewModel.setActive(value)
        }
        .onChange(of: viewModel.hasStarted) { value in
            onPlayingChanged(value)
        }
        .onChange(of: viewModel.state.status) { value in
            if value != .playing {
                onPlayingChanged(false)
            }
        }
        .onChange(of: viewModel.elapsedSeconds) { value in
            onElapsedChanged(value)
        }
        .onAppear {
            onElapsedChanged(viewModel.elapsedSeconds)
        }
        .onChange(of: isZoomed) { value in
            onZoomChanged(value)
        }
        .onAppear {
            onZoomChanged(isZoomed)
        }
        .onReceive(NotificationCenter.default.publisher(for: .startNewGame)) { notification in
            guard let target = notification.object as? ModePage else { return }
            if target == modePage {
                viewModel.startNewGame()
            }
        }
    }

    private var modePage: ModePage {
        switch viewModel.mode.id {
        case .easy: return .easy
        case .medium: return .medium
        case .hard: return .hard
        case .custom: return .custom
        }
    }
}

struct ElapsedTimeView: View {
    let elapsedSeconds: Int

    var body: some View {
        Text(elapsedString)
            .font(.headline.monospacedDigit())
            .foregroundStyle(.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.12))
            .clipShape(Capsule())
    }

    private var elapsedString: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var isZoomed: Bool
    @State private var zoomScale: CGFloat = 1.0
    @State private var gestureScale: CGFloat = 1.0
    @State private var didAutoScale = false
    private let zoomThreshold: CGFloat = 1.05

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let availableHeight = proxy.size.height
            let rows = viewModel.state.board.rows
            let cols = viewModel.state.board.cols
            let gridSpacing: CGFloat = 2
            let gridPadding: CGFloat = isZoomed ? 0 : 4
            let widthCell = (availableWidth - (gridPadding * 2) - (gridSpacing * CGFloat(cols - 1))) / CGFloat(cols)
            let heightCell = (availableHeight - (gridPadding * 2) - (gridSpacing * CGFloat(rows - 1))) / CGFloat(rows)
            let rawSize = min(widthCell, heightCell)
            let cellSize = max(16, floor(rawSize))
            let effectiveScale = zoomScale * gestureScale

            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: cols), spacing: gridSpacing) {
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
                .padding(gridPadding)
                .scaleEffect(effectiveScale, anchor: .center)
                .compositingGroup()
                .drawingGroup()
                .transaction { $0.animation = nil }
            }
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        gestureScale = value
                        updateZoomState()
                    }
                    .onEnded { value in
                        zoomScale = clampScale(zoomScale * value)
                        gestureScale = 1.0
                        updateZoomState()
                    }
            )
            .onAppear {
                applyAutoScaleIfNeeded(widthCell: widthCell, heightCell: heightCell, cols: cols)
                updateZoomState()
            }
            .onChange(of: proxy.size) { _ in
                applyAutoScaleIfNeeded(widthCell: widthCell, heightCell: heightCell, cols: cols)
                updateZoomState()
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func clampScale(_ scale: CGFloat) -> CGFloat {
        min(2.0, max(0.8, scale))
    }

    private func applyAutoScaleIfNeeded(widthCell: CGFloat, heightCell: CGFloat, cols: Int) {
        guard !didAutoScale else { return }
        guard cols >= 16, widthCell > 0, heightCell > 0 else { return }
        let ratio = heightCell / widthCell
        let targetScale = clampScale(max(1.0, ratio))
        zoomScale = targetScale
        didAutoScale = true
    }

    private func updateZoomState() {
        isZoomed = (zoomScale * gestureScale) > zoomThreshold
    }
}
