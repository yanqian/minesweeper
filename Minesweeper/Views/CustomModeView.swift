import SwiftUI

struct CustomModeView: View {
    @StateObject private var viewModel: GameViewModel
    let isActive: Bool
    let onPlayingChanged: (Bool) -> Void
    let onElapsedChanged: (Int) -> Void
    let onZoomChanged: (Bool) -> Void
    @State private var isZoomed = false

    @AppStorage("customRows") private var rows: Int = 12
    @AppStorage("customCols") private var cols: Int = 18
    @AppStorage("customMines") private var mines: Int = 40
    @State private var showSettings = true

    init(
        statsStore: StatsStore,
        isActive: Bool,
        onPlayingChanged: @escaping (Bool) -> Void = { _ in },
        onElapsedChanged: @escaping (Int) -> Void = { _ in },
        onZoomChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        let config = CustomConfig(rows: 12, cols: 18, mines: 40)
        _viewModel = StateObject(wrappedValue: GameViewModel(mode: .custom(config), statsStore: statsStore))
        self.isActive = isActive
        self.onPlayingChanged = onPlayingChanged
        self.onElapsedChanged = onElapsedChanged
        self.onZoomChanged = onZoomChanged
    }

    var body: some View {
        ZStack {
            if showSettings {
                settingsPage
            } else {
                gamePage
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSettings)
        .onAppear { viewModel.setActive(isActive) }
        .onChange(of: isActive) { value in
            viewModel.setActive(value)
        }
        .onChange(of: showSettings) { value in
            if value {
                viewModel.setActive(false)
            } else {
                viewModel.setActive(isActive)
            }
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
            if target == .custom {
                startCustomGame()
                showSettings = false
            }
        }
    }

    private var settingsPage: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Mode")
                            .font(.title2.weight(.bold))
                        Text("Set board size and mines")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.top, 20)

                customControls

                Button("Start Game") {
                    startCustomGame()
                    showSettings = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .onAppear { clampMines() }
    }

    private var gamePage: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: isZoomed ? 0 : 12) {
                HStack {
                    Spacer()
                    Button("Settings") {
                        showSettings = true
                    }
                    .buttonStyle(.bordered)
                }
                GameBoardView(viewModel: viewModel, isZoomed: $isZoomed)
                if !isZoomed {
                    CollapsibleStatsView(mode: .custom)
                }
            }
            .padding(.horizontal, isZoomed ? 0 : 16)
            .padding(.top, isZoomed ? 0 : 16)
            .padding(.bottom, isZoomed ? 0 : 24)
            .ignoresSafeArea(edges: isZoomed ? .top : [])
        }
        .alert(viewModel.resultTitle, isPresented: $viewModel.showResult) {
            Button("New Game") {
                startCustomGame()
            }
        } message: {
            Text(viewModel.resultMessage)
        }
    }

    private var customControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Settings")
                .font(.headline)

            Stepper(value: $rows, in: 8...24, step: 1) {
                Text("Rows: \(rows)")
            }
            .onChange(of: rows) { _ in
                clampMines()
            }

            Stepper(value: $cols, in: 8...30, step: 1) {
                Text("Columns: \(cols)")
            }
            .onChange(of: cols) { _ in
                clampMines()
            }

            Stepper(value: $mines, in: minMines...maxMines, step: 1) {
                Text("Mines: \(mines)")
            }
            .onChange(of: mines) { _ in
                clampMines()
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var maxMines: Int {
        let total = rows * cols
        return max(10, Int(Double(total) * 0.3))
    }

    private var minMines: Int {
        return 10
    }

    private func clampMines() {
        if mines < minMines { mines = minMines }
        if mines > maxMines { mines = maxMines }
    }

    private func startCustomGame() {
        let config = CustomConfig(rows: rows, cols: cols, mines: mines)
        viewModel.startNewGame(mode: .custom(config))
    }
}
