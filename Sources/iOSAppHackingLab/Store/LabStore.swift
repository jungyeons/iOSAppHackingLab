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

    private let defaults = UserDefaults.standard
    private let weakKey: UInt8 = 0x42
    private let progressKey = "lab.progress.completedChallengeIDs"
    private let notesKey = "lab.progress.notes"
    private var lastPayload = ""

    init() {
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
        let labSections = challenges.map { challenge in
            let mark = isCompleted(challenge) ? "x" : " "
            let note = note(for: challenge.id).trimmingCharacters(in: .whitespacesAndNewlines)
            let noteBlock = note.isEmpty ? "No notes yet." : note

            return """
            ## \(challenge.title)

            - Status: [\(mark)] Complete
            - Category: \(challenge.category)
            - Difficulty: \(challenge.difficulty)
            - Risk: \(challenge.risk)
            - Safer pattern: \(challenge.saferPattern)

            Notes:
            \(noteBlock)
            """
        }
        .joined(separator: "\n\n")

        report = """
        # iOSAppHackingLab Study Report

        Generated: \(generatedAt)

        Progress: \(completed)/\(challenges.count) labs complete

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

    private func persistProgress() {
        defaults.set(Array(completedChallengeIDs).sorted(), forKey: progressKey)
    }

    private func persistNotes() {
        defaults.set(notes, forKey: notesKey)
    }
}
