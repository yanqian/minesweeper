import SwiftUI

enum ModePage: Int, CaseIterable, Identifiable {
    case easy = 0
    case medium = 1
    case hard = 2
    case custom = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .custom: return "Custom"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var statsStore: StatsStore
    @State private var selection: ModePage = .easy
    @State private var elapsedSeconds: [ModePage: Int] = [:]
    @State private var isZoomed: [ModePage: Bool] = [:]

    var body: some View {
        ZStack {
            switch selection {
            case .easy:
                GameView(
                    mode: .easy,
                    statsStore: statsStore,
                    isActive: true,
                    onElapsedChanged: { elapsedSeconds[.easy] = $0 },
                    onZoomChanged: { isZoomed[.easy] = $0 }
                )
            case .medium:
                GameView(
                    mode: .medium,
                    statsStore: statsStore,
                    isActive: true,
                    onElapsedChanged: { elapsedSeconds[.medium] = $0 },
                    onZoomChanged: { isZoomed[.medium] = $0 }
                )
            case .hard:
                GameView(
                    mode: .hard,
                    statsStore: statsStore,
                    isActive: true,
                    onElapsedChanged: { elapsedSeconds[.hard] = $0 },
                    onZoomChanged: { isZoomed[.hard] = $0 }
                )
            case .custom:
                CustomModeView(
                    statsStore: statsStore,
                    isActive: true,
                    onElapsedChanged: { elapsedSeconds[.custom] = $0 },
                    onZoomChanged: { isZoomed[.custom] = $0 }
                )
            }
        }
        .safeAreaInset(edge: .top) {
            if !(isZoomed[selection] ?? false) {
                TopBar(
                    selection: $selection,
                    elapsedSeconds: elapsedSeconds[selection] ?? 0,
                    onSelect: { selection = $0 },
                    onStart: startNewGame
                )
            }
        }
    }
    private func startNewGame() {
        NotificationCenter.default.post(name: .startNewGame, object: selection)
    }

}

struct TopBar: View {
    @Binding var selection: ModePage
    let elapsedSeconds: Int
    let onSelect: (ModePage) -> Void
    let onStart: () -> Void
    @State private var showModePicker = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                showModePicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(selection.title)
                        .font(.headline.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
            }
            .confirmationDialog("Select Mode", isPresented: $showModePicker, titleVisibility: .visible) {
                Button("Easy") { onSelect(.easy) }
                Button("Medium") { onSelect(.medium) }
                Button("Hard") { onSelect(.hard) }
                Button("Custom") { onSelect(.custom) }
                Button("Cancel", role: .cancel) {}
            }

            Button("Start") {
                onStart()
            }
            .buttonStyle(.bordered)

            Spacer()

            ElapsedTimeView(elapsedSeconds: elapsedSeconds)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }
}

extension Notification.Name {
    static let startNewGame = Notification.Name("startNewGame")
}
