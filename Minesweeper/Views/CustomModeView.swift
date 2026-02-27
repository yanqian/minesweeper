import SwiftUI

struct CustomModeView: View {
    @StateObject private var viewModel: GameViewModel
    let isActive: Bool
    let onPlayingChanged: (Bool) -> Void
    let onElapsedChanged: (Int) -> Void
    let onZoomChanged: (Bool) -> Void
    @State private var isZoomed = false
    @State private var showSettingsSheet = false
    @State private var zoomResetToken = UUID()
    private let topBarReserve: CGFloat = 70
    private let statsReserve: CGFloat = 66

    @AppStorage("customRows") private var rows: Int = 12
    @AppStorage("customCols") private var cols: Int = 18
    @AppStorage("customMines") private var mines: Int = 40

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
            GameBackgroundView().ignoresSafeArea()
            GameBoardView(viewModel: viewModel, isZoomed: $isZoomed, resetToken: zoomResetToken)
                .padding(.horizontal, 12)
                .padding(.top, topBarReserve)
                .padding(.bottom, statsReserve)
                .ignoresSafeArea(edges: [])

            StatsOverlay(mode: .custom)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .frame(maxHeight: .infinity, alignment: .bottomLeading)
                .opacity(isZoomed ? 0.0 : 1.0)
        }
        .onAppear { viewModel.setActive(isActive) }
        .onChange(of: isActive) { value in
            viewModel.setActive(value)
        }
        .onChange(of: rows) { _ in
            clampMines()
        }
        .onChange(of: cols) { _ in
            clampMines()
        }
        .onChange(of: mines) { _ in
            clampMines()
        }
        .onChange(of: viewModel.hasStarted) { value in
            onPlayingChanged(value)
        }
        .onChange(of: viewModel.state.status) { value in
            if value != .playing {
                onPlayingChanged(false)
                zoomResetToken = UUID()
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
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCustomSettings)) { _ in
            showSettingsSheet = true
        }
        .sheet(isPresented: $showSettingsSheet) {
            CustomSettingsSheet(
                rows: $rows,
                cols: $cols,
                mines: $mines,
                onStart: {
                    startCustomGame()
                    showSettingsSheet = false
                }
            )
        }
        .alert(viewModel.resultTitle, isPresented: $viewModel.showResult) {
            Button("New Game") {
                startCustomGame()
            }
        } message: {
            Text(viewModel.resultMessage)
        }
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
        clampMines()
        let config = CustomConfig(rows: rows, cols: cols, mines: mines)
        viewModel.startNewGame(mode: .custom(config))
    }
}

struct CustomSettingsSheet: View {
    @Binding var rows: Int
    @Binding var cols: Int
    @Binding var mines: Int
    let onStart: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom Board")
                        .font(.custom("AvenirNext-DemiBold", size: 22))
                    Text("Tune size and mines, then start a new game.")
                        .font(.custom("AvenirNext-Medium", size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    Stepper(value: $rows, in: 8...24, step: 1) {
                        Text("Rows: \(rows)")
                            .font(.custom("AvenirNext-Medium", size: 16))
                    }
                    Stepper(value: $cols, in: 8...30, step: 1) {
                        Text("Columns: \(cols)")
                            .font(.custom("AvenirNext-Medium", size: 16))
                    }
                    Stepper(value: $mines, in: 10...maxMines, step: 1) {
                        Text("Mines: \(mines)")
                            .font(.custom("AvenirNext-Medium", size: 16))
                    }
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button(action: onStart) {
                    Text("Start New Game")
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle("Custom Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var maxMines: Int {
        let total = rows * cols
        return max(10, Int(Double(total) * 0.3))
    }
}
