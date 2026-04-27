import SwiftUI

struct LabConsole: View {
    let challenge: LabChallenge

    var body: some View {
        LabSection(title: "Lab Actions", systemImage: "play.circle") {
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

            Divider()

            Text("Safer comparison")
                .font(.headline)

            HStack {
                Button("Save Password to Keychain") {
                    labStore.saveKeychainCredentials(username: username, password: password)
                }
                Button("Read Keychain Password") {
                    labStore.revealKeychainCredentials(username: username)
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
    @State private var account = "student@example.com"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This simulates an app that accidentally logs sensitive session data.")
                .foregroundStyle(.secondary)
            Button("Perform Debug Login") {
                labStore.performDebugLogin()
            }

            Divider()

            Text("Safer comparison")
                .font(.headline)

            TextField("Account", text: $account)
                .textFieldStyle(.roundedBorder)

            Button("Perform Redacted Login Log") {
                labStore.performRedactedDebugLogin(account: account)
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
