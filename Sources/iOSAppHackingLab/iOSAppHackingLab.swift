import SwiftUI

@main
struct iOSAppHackingLabApp: App {
    @StateObject private var labStore = LabStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(labStore)
                .frame(minWidth: 1040, minHeight: 720)
        }
        .windowStyle(.titleBar)
    }
}
