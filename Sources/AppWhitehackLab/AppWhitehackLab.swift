import SwiftUI
import Foundation

@main
struct AppWhitehackLabApp: App {
    @StateObject private var labStore = LabStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(labStore)
                .frame(minWidth: 980, minHeight: 680)
        }
        .windowStyle(.titleBar)
    }
}

struct ContentView: View {
    @EnvironmentObject private var labStore: LabStore
    @State private var selection: LabChallenge.ID? = LabChallenge.seed.first?.id

    var body: some View {
        NavigationSplitView {
            List(LabChallenge.seed, selection: $selection) { challenge in
                VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.title)
                        .font(.headline)
                    Text(challenge.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Swift Lab")
        } detail: {
            if let challenge = LabChallenge.seed.first(where: { $0.id == selection }) {
                ChallengeDetail(challenge: challenge)
            } else {
                Text("Choose a lab")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ChallengeDetail: View {
    @EnvironmentObject private var labStore: LabStore
    let challenge: LabChallenge

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.title)
                        .font(.largeTitle.weight(.bold))
                    Text(challenge.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    StatusPill(text: challenge.category)
                    StatusPill(text: challenge.difficulty)
                }

                Divider()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Practice")
                        .font(.title2.weight(.semibold))
                    Text(challenge.practice)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }

                LabConsole(challenge: challenge)

                VStack(alignment: .leading, spacing: 14) {
                    Text("What To Inspect")
                        .font(.title2.weight(.semibold))
                    ForEach(challenge.inspectHints, id: \.self) { hint in
                        Label(hint, systemImage: "magnifyingglass")
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 820, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct LabConsole: View {
    @EnvironmentObject private var labStore: LabStore
    let challenge: LabChallenge

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Lab Actions")
                .font(.title2.weight(.semibold))

            switch challenge.kind {
            case .insecureStorage:
                InsecureStorageLab()
            case .weakSecret:
                WeakSecretLab()
            case .verboseLogging:
                VerboseLoggingLab()
            case .tamperableState:
                TamperableStateLab()
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct InsecureStorageLab: View {
    @EnvironmentObject private var labStore: LabStore
    @State private var username = "student"
    @State private var password = "passw0rd!"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Save Plaintext Credentials") {
                    labStore.savePlaintextCredentials(username: username, password: password)
                }
                Button("Show Saved Value") {
                    labStore.revealSavedCredentials()
                }
            }

            ConsoleOutput(text: labStore.console)
        }
    }
}

struct WeakSecretLab: View {
    @EnvironmentObject private var labStore: LabStore
    @State private var message = "transfer=250000&to=lab-admin"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Message", text: $message)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Encode With Static XOR Key") {
                    labStore.encodeWithWeakKey(message)
                }
                Button("Decode Last Payload") {
                    labStore.decodeLastPayload()
                }
            }

            ConsoleOutput(text: labStore.console)
        }
    }
}

struct VerboseLoggingLab: View {
    @EnvironmentObject private var labStore: LabStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This simulates an app that accidentally logs sensitive session data.")
                .foregroundStyle(.secondary)
            Button("Perform Debug Login") {
                labStore.performDebugLogin()
            }
            ConsoleOutput(text: labStore.console)
        }
    }
}

struct TamperableStateLab: View {
    @EnvironmentObject private var labStore: LabStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Premium enabled")
                Spacer()
                Toggle("", isOn: $labStore.isPremiumEnabled)
                    .labelsHidden()
            }

            HStack {
                Button("Save Local Entitlement") {
                    labStore.saveLocalEntitlement()
                }
                Button("Reload Local Entitlement") {
                    labStore.reloadLocalEntitlement()
                }
            }

            ConsoleOutput(text: labStore.console)
        }
    }
}

struct ConsoleOutput: View {
    let text: String

    var body: some View {
        Text(text.isEmpty ? "Console output appears here." : text)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(text.isEmpty ? .secondary : .primary)
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct StatusPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.14))
            .foregroundStyle(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

final class LabStore: ObservableObject {
    @Published var console = ""
    @Published var isPremiumEnabled = false

    private let defaults = UserDefaults.standard
    private let weakKey: UInt8 = 0x42
    private var lastPayload = ""

    func savePlaintextCredentials(username: String, password: String) {
        defaults.set(username, forKey: "lab.username")
        defaults.set(password, forKey: "lab.password")
        console = """
        Saved credentials to UserDefaults.
        username=\(username)
        password=\(password)
        """
    }

    func revealSavedCredentials() {
        let username = defaults.string(forKey: "lab.username") ?? "<missing>"
        let password = defaults.string(forKey: "lab.password") ?? "<missing>"
        console = """
        Read from UserDefaults:
        lab.username=\(username)
        lab.password=\(password)
        """
    }

    func encodeWithWeakKey(_ message: String) {
        let encoded = message.utf8.map { $0 ^ weakKey }
        lastPayload = Data(encoded).base64EncodedString()
        console = """
        Encoded payload:
        \(lastPayload)

        Weakness: the XOR key is static and stored in the app binary.
        """
    }

    func decodeLastPayload() {
        guard let data = Data(base64Encoded: lastPayload) else {
            console = "No valid payload has been encoded yet."
            return
        }

        let decodedBytes = data.map { $0 ^ weakKey }
        let decoded = String(decoding: decodedBytes, as: UTF8.self)
        console = """
        Decoded payload:
        \(decoded)
        """
    }

    func performDebugLogin() {
        let token = "lab-token-\(UUID().uuidString)"
        NSLog("DEBUG LOGIN token=%@", token)
        console = """
        Login succeeded.
        A sensitive token was also written to the macOS Console via NSLog.
        token=\(token)
        """
    }

    func saveLocalEntitlement() {
        defaults.set(isPremiumEnabled, forKey: "lab.premium.enabled")
        console = """
        Saved local entitlement:
        lab.premium.enabled=\(isPremiumEnabled)

        Weakness: local-only entitlement state can be modified by the user.
        """
    }

    func reloadLocalEntitlement() {
        isPremiumEnabled = defaults.bool(forKey: "lab.premium.enabled")
        console = """
        Reloaded local entitlement:
        lab.premium.enabled=\(isPremiumEnabled)
        """
    }
}

struct LabChallenge: Identifiable {
    enum Kind {
        case insecureStorage
        case weakSecret
        case verboseLogging
        case tamperableState
    }

    let id: String
    let title: String
    let category: String
    let difficulty: String
    let summary: String
    let practice: String
    let inspectHints: [String]
    let kind: Kind

    static let seed: [LabChallenge] = [
        LabChallenge(
            id: "insecure-storage",
            title: "Insecure Local Storage",
            category: "Storage",
            difficulty: "Beginner",
            summary: "Credentials are saved in UserDefaults as plaintext.",
            practice: "Save a username and password, then inspect the app container or defaults domain to find the stored values. The goal is to understand why secrets do not belong in simple preference storage.",
            inspectHints: [
                "Search the source for lab.username and lab.password.",
                "Inspect the app defaults after saving credentials.",
                "Compare this with Keychain-backed storage."
            ],
            kind: .insecureStorage
        ),
        LabChallenge(
            id: "weak-secret",
            title: "Weak Static Secret",
            category: "Crypto",
            difficulty: "Beginner",
            summary: "A message is protected with a hardcoded XOR byte.",
            practice: "Encode a payload and inspect the implementation. The goal is not to learn real encryption, but to spot static secrets and reversible toy schemes in client apps.",
            inspectHints: [
                "Search for weakKey in the source.",
                "Try changing the message and decoding it.",
                "Notice that anyone with the binary can recover the key."
            ],
            kind: .weakSecret
        ),
        LabChallenge(
            id: "verbose-logging",
            title: "Sensitive Debug Logging",
            category: "Logging",
            difficulty: "Beginner",
            summary: "A debug login writes a session token to NSLog.",
            practice: "Trigger the login and inspect the app output. The goal is to recognize sensitive data exposure through logs during development and testing.",
            inspectHints: [
                "Search for NSLog in the source.",
                "Run the app from Terminal to see stdout and stderr behavior.",
                "Think about production log redaction rules."
            ],
            kind: .verboseLogging
        ),
        LabChallenge(
            id: "tamperable-state",
            title: "Tamperable Entitlement",
            category: "Business Logic",
            difficulty: "Beginner",
            summary: "Premium state is trusted from a local boolean.",
            practice: "Toggle premium, save it, reload it, then inspect where that state lives. The goal is to understand why authorization decisions need server-side validation or signed local state.",
            inspectHints: [
                "Search for lab.premium.enabled in the source.",
                "Inspect and modify the saved defaults value.",
                "Design a safer trust boundary for the entitlement."
            ],
            kind: .tamperableState
        )
    ]
}
