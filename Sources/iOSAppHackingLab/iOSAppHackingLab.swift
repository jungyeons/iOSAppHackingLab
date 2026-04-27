import Darwin
import SwiftUI

enum AppLaunchOptions {
    static var initialLabID: String? {
        value(after: "--lab")
    }

    static var demoMode: String? {
        value(after: "--demo")
    }

    static var shouldFocusDemoOutput: Bool {
        demoMode != nil
    }

    static var demoFocusAnchorID: String? {
        switch demoMode {
        case "sanitized-report", "sanitized-report-exported":
            return "report"
        case .some:
            return "lab-actions"
        case .none:
            return nil
        }
    }

    private static func value(after flag: String) -> String? {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: flag) else {
            return nil
        }

        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else {
            return nil
        }

        return arguments[valueIndex]
    }
}

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
                #if os(macOS)
                .frame(minWidth: 1040, minHeight: 720)
                #endif
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        #endif
    }
}
