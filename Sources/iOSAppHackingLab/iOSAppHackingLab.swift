import Darwin
import SwiftUI

@main
struct iOSAppHackingLabApp: App {
    @StateObject private var labStore = LabStore()

    init() {
        if CommandLine.arguments.contains("--self-check") {
            let result = SelfCheck.run()
            print(result.output)
            Darwin.exit(result.didPass ? EXIT_SUCCESS : EXIT_FAILURE)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(labStore)
                .frame(minWidth: 1040, minHeight: 720)
        }
        .windowStyle(.titleBar)
    }
}
