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
            case .runtimeObservation:
                RuntimeObservationLab()
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
    @State private var account: String

    init() {
        let demoAccount = AppLaunchOptions.demoMode == "entitlement-paid"
            || AppLaunchOptions.demoMode == "entitlement-api-mock"
            ? "paid@example.com"
            : "student@example.com"
        _account = State(initialValue: demoAccount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Local premium flag")
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

            Divider()

            Text("Safer comparison")
                .font(.headline)

            TextField("Account", text: $account)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Server premium")
                Spacer()
                Image(systemName: labStore.serverAuthorizedPremium ? "checkmark.seal.fill" : "xmark.seal")
                    .foregroundStyle(labStore.serverAuthorizedPremium ? .green : .secondary)
                Text(labStore.serverAuthorizedPremium ? "authorized" : "not authorized")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Button {
                    labStore.requestServerEntitlement(account: account)
                } label: {
                    Label("Request Server Entitlement", systemImage: "checkmark.shield")
                }

                Button {
                    labStore.reloadServerEntitlementCache()
                } label: {
                    Label("Reload Cached Server Claim", systemImage: "arrow.clockwise")
                }

                Button {
                    labStore.verifyServerEntitlementCache()
                } label: {
                    Label("Verify Signed Claim", systemImage: "signature")
                }

                Button {
                    Task {
                        await labStore.requestSignedEntitlementAPIMock(account: account)
                    }
                } label: {
                    Label("Run API Client Mock", systemImage: "network")
                }

                Button {
                    labStore.attemptLocalEntitlementOverride()
                } label: {
                    Label("Try Local Override", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                }
            }
            .buttonStyle(.bordered)

            ConsoleOutput(text: labStore.console)
        }
    }
}

struct RuntimeObservationLab: View {
    @EnvironmentObject private var labStore: LabStore
    @State private var account = "student@example.com"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("com.jungyeons.iosapphackinglab", systemImage: "iphone.gen3")
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)

            TextField("Lab account", text: $account)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 10) {
                Button {
                    labStore.runRuntimeObservation(account: account)
                } label: {
                    Label("Run Observation Scenario", systemImage: "record.circle")
                }

                Button {
                    labStore.showLLDBObservationGuide()
                } label: {
                    Label("Show LLDB Guide", systemImage: "terminal")
                }

                Button {
                    labStore.showFridaObservationGuide()
                } label: {
                    Label("Show Frida Observer", systemImage: "dot.radiowaves.left.and.right")
                }
            }
            .buttonStyle(.bordered)

            ConsoleOutput(text: labStore.console, minHeight: 190)
        }
    }
}
