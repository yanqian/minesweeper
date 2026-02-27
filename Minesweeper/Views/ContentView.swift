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
            TopBar(
                selection: $selection,
                elapsedSeconds: elapsedSeconds[selection] ?? 0,
                onSelect: { selection = $0 },
                onStart: startNewGame,
                onCustomSettings: {
                    NotificationCenter.default.post(name: .openCustomSettings, object: nil)
                }
            )
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
    let onCustomSettings: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                Button("Easy") { onSelect(.easy) }
                Button("Medium") { onSelect(.medium) }
                Button("Hard") { onSelect(.hard) }
                Button("Custom") { onSelect(.custom) }
            } label: {
                HStack(spacing: 6) {
                    Text(selection.title)
                        .font(.custom("AvenirNext-DemiBold", size: 15))
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }

            Button {
                onStart()
            } label: {
                Label("New", systemImage: "arrow.clockwise")
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.18), in: Capsule())
            }

            Spacer(minLength: 8)

            ElapsedTimeView(elapsedSeconds: elapsedSeconds)

            if selection == .custom {
                Button {
                    onCustomSettings()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Custom settings")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}

extension Notification.Name {
    static let startNewGame = Notification.Name("startNewGame")
    static let openCustomSettings = Notification.Name("openCustomSettings")
}
