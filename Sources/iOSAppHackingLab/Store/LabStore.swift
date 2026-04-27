import Foundation

#if os(macOS)
import AppKit
#endif

final class LabStore: ObservableObject {
    @Published var console = ""
    @Published var isPremiumEnabled = false
    @Published var completedChallengeIDs: Set<String> = []
    @Published var notes: [String: String] = [:]
    @Published var report = ""

    private let defaults: UserDefaults
    private let weakKey: UInt8 = 0x42
    private let progressKey = "lab.progress.completedChallengeIDs"
    private let notesKey = "lab.progress.notes"
    private var lastPayload = ""

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completedChallengeIDs = Set(defaults.stringArray(forKey: progressKey) ?? [])
        notes = defaults.dictionary(forKey: notesKey) as? [String: String] ?? [:]
    }

    func completedCount(in challenges: [LabChallenge]) -> Int {
        challenges.filter { completedChallengeIDs.contains($0.id) }.count
    }

    func completionRatio(in challenges: [LabChallenge]) -> Double {
        guard !challenges.isEmpty else { return 0 }
        return Double(completedCount(in: challenges)) / Double(challenges.count)
    }

    func isCompleted(_ challenge: LabChallenge) -> Bool {
        completedChallengeIDs.contains(challenge.id)
    }

    func toggleCompletion(for challenge: LabChallenge) {
        if completedChallengeIDs.contains(challenge.id) {
            completedChallengeIDs.remove(challenge.id)
        } else {
            completedChallengeIDs.insert(challenge.id)
        }
        persistProgress()
    }

    func note(for challengeID: String) -> String {
        notes[challengeID] ?? ""
    }

    func updateNote(_ value: String, for challengeID: String) {
        notes[challengeID] = value
        persistNotes()
    }

    func generateReport(challenges: [LabChallenge]) {
        let completed = completedCount(in: challenges)
        let generatedAt = ISO8601DateFormatter().string(from: Date())
        let completedTitles = challenges
            .filter { isCompleted($0) }
            .map(\.title)
            .joined(separator: ", ")
        let completedSummary = completedTitles.isEmpty ? "No labs completed yet." : completedTitles
        let labSections = challenges.map { challenge in
            let mark = isCompleted(challenge) ? "x" : " "
            let note = note(for: challenge.id).trimmingCharacters(in: .whitespacesAndNewlines)
            let noteBlock = note.isEmpty ? "No notes yet." : note
            let evidence = challenge.evidencePrompts
                .map { "- [ ] \($0)" }
                .joined(separator: "\n")

            return """
            ## \(challenge.title)

            - Status: [\(mark)] Complete
            - Category: \(challenge.category)
            - Difficulty: \(challenge.difficulty)
            - Attack surface: \(challenge.attackSurface)
            - Objective: \(challenge.objective)
            - Risk: \(challenge.risk)
            - Safer pattern: \(challenge.saferPattern)
            - Portfolio takeaway: \(challenge.portfolioTakeaway)

            Evidence to capture:
            \(evidence)

            Notes:
            \(noteBlock)
            """
        }
        .joined(separator: "\n\n")

        report = """
        # iOSAppHackingLab Study Report

        Generated: \(generatedAt)

        ## Executive Summary

        This report documents defensive security practice against the intentionally vulnerable local app in this repository. It does not authorize testing against third-party apps, production services, or devices without explicit permission.

        Progress: \(completed)/\(challenges.count) labs complete

        Completed labs: \(completedSummary)

        ## Scope

        - Target: iOSAppHackingLab local SwiftUI lab app
        - Allowed activity: inspect, run, modify, and document this intentionally vulnerable codebase
        - Out of scope: real user data, third-party apps, production services, and bypassing access controls on systems you do not own

        \(labSections)
        """
    }

    func copyReportToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        #endif
    }

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

    func saveKeychainCredentials(username: String, password: String) {
        switch KeychainService.savePassword(password, account: username) {
        case .success:
            console = """
            Saved password to Keychain.
            account=\(username)

            Safer pattern: credentials are stored through the platform Keychain API instead of UserDefaults.
            """
        case .failure(let error):
            console = """
            Failed to save password to Keychain.
            account=\(username)
            error=\(error.message)
            """
        }
    }

    func revealKeychainCredentials(username: String) {
        switch KeychainService.readPassword(account: username) {
        case .success(.some(let password)):
            console = """
            Read password from Keychain.
            account=\(username)
            password=\(password)

            Lab note: the app can retrieve the secret, but it is not stored in plain UserDefaults.
            """
        case .success(.none):
            console = """
            No Keychain password found for account:
            \(username)
            """
        case .failure(let error):
            console = """
            Failed to read password from Keychain.
            account=\(username)
            error=\(error.message)
            """
        }
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

    func performRedactedDebugLogin(account: String) {
        let token = "lab-token-\(UUID().uuidString)"
        let event = RedactingLogger.loginSucceeded(account: account, token: token)
        console = """
        Login succeeded with redacted logging.
        The token was generated but not written to the log.

        Safe log event:
        \(event)
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

    private func persistProgress() {
        defaults.set(Array(completedChallengeIDs).sorted(), forKey: progressKey)
    }

    private func persistNotes() {
        defaults.set(notes, forKey: notesKey)
    }
}
