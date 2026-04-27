import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
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
    private let observationProbe = LabObservationProbe.shared
    private var lastPayload = ""

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completedChallengeIDs = Set(defaults.stringArray(forKey: progressKey) ?? [])
        notes = defaults.dictionary(forKey: notesKey) as? [String: String] ?? [:]
        applyLaunchDemoIfNeeded()
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
        #elseif os(iOS)
        UIPasteboard.general.string = report
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
        A sensitive token was also written to the system log via NSLog.
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

    func runRuntimeObservation(account: String) {
        let normalizedAccount = account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "student@example.com"
            : account
        let token = "lab-observe-\(UUID().uuidString)"
        let startEvent = observationProbe.startObservation(account: normalizedAccount, token: token)
        let checkpointEvent = observationProbe.recordCheckpoint(label: "premium-evaluation", secret: token)
        let finishEvent = observationProbe.finishObservation(result: isPremiumEnabled ? "premium-visible" : "standard-visible")

        console = """
        Runtime observation scenario completed.
        Target bundle: com.jungyeons.iosapphackinglab
        Probe class: LabObservationProbe

        Events:
        \(startEvent)
        \(checkpointEvent)
        \(finishEvent)

        Lab note: a raw token existed in process memory for this local scenario. Capture redacted metadata, source location, and breakpoint evidence instead of publishing raw secrets.
        """
    }

    func showLLDBObservationGuide() {
        console = """
        LLDB observation guide for this lab binary only.

        1. Build and launch the iOS Simulator target.
        2. Attach to this simulator app:
           lldb
           (lldb) process attach --name iOSAppHackingLab
        3. Explore the lab-only symbols:
           (lldb) image lookup -rn 'LabObservationProbe|runRuntimeObservation'
        4. Set observation breakpoints:
           (lldb) breakpoint set --func-regex 'LabObservationProbe.*startObservation'
           (lldb) breakpoint set --func-regex 'LabObservationProbe.*recordCheckpoint'
           (lldb) breakpoint set --func-regex 'LabObservationProbe.*finishObservation'
        5. Return to the app and press Run Observation Scenario.
        6. Capture breakpoint hits and redacted app output.

        Scope rule: use this against com.jungyeons.iosapphackinglab only.
        """
    }

    func showFridaObservationGuide() {
        console = """
        Frida observer for this lab binary only.

        Script:
        tools/frida/observe-lab-state.js

        Simulator flow, after installing Frida separately:
        frida-ps | rg iOSAppHackingLab
        frida -n iOSAppHackingLab -l tools/frida/observe-lab-state.js

        Then press Run Observation Scenario in the app.

        The script observes LabObservationProbe selectors and logs method names plus redacted metadata. It does not change return values, bypass checks, or target any third-party app.
        """
    }

    private func persistProgress() {
        defaults.set(Array(completedChallengeIDs).sorted(), forKey: progressKey)
    }

    private func persistNotes() {
        defaults.set(notes, forKey: notesKey)
    }

    private func applyLaunchDemoIfNeeded() {
        guard let mode = AppLaunchOptions.demoMode else {
            return
        }

        switch mode {
        case "runtime-run":
            runRuntimeObservation(account: "demo@example.com")
        case "runtime-lldb":
            showLLDBObservationGuide()
        case "runtime-frida":
            showFridaObservationGuide()
        default:
            break
        }
    }
}

@objc(LabObservationProbe)
@objcMembers
final class LabObservationProbe: NSObject {
    static let shared = LabObservationProbe()

    private override init() {}

    @objc(startObservationWithAccount:token:)
    dynamic func startObservation(account: String, token: String) -> String {
        "probe=start selector=startObservationWithAccount:token: accountHash=\(fingerprint(account)) token=\(redact(token))"
    }

    @objc(recordCheckpointWithLabel:secret:)
    dynamic func recordCheckpoint(label: String, secret: String) -> String {
        "probe=checkpoint selector=recordCheckpointWithLabel:secret: label=\(label) secret=\(redact(secret))"
    }

    @objc(finishObservationWithResult:)
    dynamic func finishObservation(result: String) -> String {
        "probe=finish selector=finishObservationWithResult: result=\(result)"
    }

    private func redact(_ value: String) -> String {
        "<redacted:\(value.count)-chars>"
    }

    private func fingerprint(_ value: String) -> String {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }
}
