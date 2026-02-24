import SwiftUI

struct CustomModeView: View {
    @StateObject private var viewModel: GameViewModel

    @AppStorage("customRows") private var rows: Int = 12
    @AppStorage("customCols") private var cols: Int = 18
    @AppStorage("customMines") private var mines: Int = 40

    init(statsStore: StatsStore) {
        let config = CustomConfig(rows: 12, cols: 18, mines: 40)
        _viewModel = StateObject(wrappedValue: GameViewModel(mode: .custom(config), statsStore: statsStore))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                GameHeaderView(modeTitle: "Custom", state: viewModel.state)
                customControls
                GameBoardView(viewModel: viewModel)
                StatsSummaryView(mode: .custom)
            }
            .padding(.horizontal, 16)
            .padding(.top, 80)
            .padding(.bottom, 24)
        }
        .alert(viewModel.resultTitle, isPresented: $viewModel.showResult) {
            Button("New Game") {
                startCustomGame()
            }
        } message: {
            Text(viewModel.resultMessage)
        }
        .onAppear {
            clampMines()
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

            Button("Apply and Restart") {
                startCustomGame()
            }
            .buttonStyle(.borderedProminent)
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
