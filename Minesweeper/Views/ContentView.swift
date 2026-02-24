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
    @State private var selection: ModePage = .medium

    var body: some View {
        TabView(selection: $selection) {
            GameView(mode: .easy, statsStore: statsStore)
                .tag(ModePage.easy)
            GameView(mode: .medium, statsStore: statsStore)
                .tag(ModePage.medium)
            GameView(mode: .hard, statsStore: statsStore)
                .tag(ModePage.hard)
            CustomModeView(statsStore: statsStore)
                .tag(ModePage.custom)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .top) {
            ModeIndicator(selection: $selection)
                .padding(.top, 16)
        }
    }
}

struct ModeIndicator: View {
    @Binding var selection: ModePage

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ModePage.allCases) { page in
                Text(page.title)
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(selection == page ? Color.accentColor.opacity(0.2) : Color.clear)
                    .clipShape(Capsule())
                    .onTapGesture { selection = page }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(radius: 4)
    }
}
