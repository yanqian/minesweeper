import SwiftUI

@main
struct MinesweeperApp: App {
    @StateObject private var statsStore = StatsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(statsStore)
        }
    }
}
