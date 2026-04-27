import Foundation
import CryptoKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

final class LabStore: ObservableObject {
    @Published var console = ""
    @Published var isPremiumEnabled = false
    @Published var serverAuthorizedPremium = false
    @Published var completedChallengeIDs: Set<String> = []
    @Published var notes: [String: String] = [:]
    @Published var report = ""
    @Published var sanitizedReport = ""
    @Published var reportExportStatus = ""

    private let defaults: UserDefaults
    private let weakKey: UInt8 = 0x42
    private let progressKey = "lab.progress.completedChallengeIDs"
    private let notesKey = "lab.progress.notes"
    private let serverClaimKey = "lab.premium.serverClaim"
    private let observationProbe = LabObservationProbe.shared
    private let entitlementAuthority = SimulatedEntitlementAuthority()
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

    func generateSanitizedReport(challenges: [LabChallenge]) {
        let completed = completedCount(in: challenges)
        let generatedAt = ISO8601DateFormatter().string(from: Date())
        let labSections = challenges.map { challenge in
            let mark = isCompleted(challenge) ? "x" : " "
            let note = sanitizedFreeformText(note(for: challenge.id).trimmingCharacters(in: .whitespacesAndNewlines))
            let noteBlock = note.isEmpty ? "No sanitized notes yet." : note
            let evidence = challenge.evidencePrompts
                .map { "- [ ] \(sanitizedFreeformText($0))" }
                .joined(separator: "\n")

            return """
            ## \(challenge.title)

            - Status: [\(mark)] Complete
            - Category: \(challenge.category)
            - Attack surface: \(challenge.attackSurface)
            - Sanitized objective: \(sanitizedFreeformText(challenge.objective))
            - Public takeaway: \(sanitizedFreeformText(challenge.portfolioTakeaway))

            Sanitized evidence checklist:
            \(evidence)

            Sanitized notes:
            \(noteBlock)
            """
        }
        .joined(separator: "\n\n")

        sanitizedReport = """
        # iOSAppHackingLab Sanitized Study Report

        Generated: \(generatedAt)

        ## Public Sharing Guardrails

        This export is intended for a public portfolio. It removes common token, password, account, and local filesystem patterns from freeform notes before writing the Markdown file.

        Progress: \(completed)/\(challenges.count) labs complete

        ## Scope

        - Target: `com.jungyeons.iosapphackinglab`
        - Environment: local SwiftUI app and iOS Simulator builds
        - Allowed activity: inspect this intentionally vulnerable lab app and document defensive findings
        - Out of scope: third-party apps, production services, real accounts, real user data, and unauthorized bypass work

        \(labSections)
        """

        reportExportStatus = "Sanitized report ready for Markdown export."
    }

    func handleSanitizedReportExport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            reportExportStatus = "Exported sanitized Markdown report: \(url.lastPathComponent)"
        case .failure(let error):
            reportExportStatus = "Sanitized report export failed: \(error.localizedDescription)"
        }
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

    func requestServerEntitlement(account: String) {
        let claim = entitlementAuthority.fetchEntitlement(account: account)
        let verification = entitlementAuthority.verifyCachedClaim(claim.cacheValue)
        serverAuthorizedPremium = verification.isTrusted && claim.isPremium
        defaults.set(claim.cacheValue, forKey: serverClaimKey)
        console = """
        Signed server-authoritative entitlement response:
        decisionSource=\(claim.decisionSource)
        accountHash=\(claim.accountHash)
        plan=\(claim.plan)
        premium=\(claim.isPremium)
        claimID=\(claim.claimID)
        keyID=\(claim.keyID)
        alg=\(claim.algorithm)
        expiresAt=\(claim.expiresAt)
        signature=\(claim.signatureFingerprint)
        signatureValid=\(verification.isSignatureValid)

        Cached display claim:
        \(serverClaimKey)=\(displaySignedClaim(claim.cacheValue))

        Safer pattern: local UI state can cache the result, but the authoritative decision comes from a trusted issuer and a verifiable signed claim, not from lab.premium.enabled.
        """
    }

    func reloadServerEntitlementCache() {
        let cached = defaults.string(forKey: serverClaimKey) ?? "<missing>"
        let verification = entitlementAuthority.verifyCachedClaim(cached)
        serverAuthorizedPremium = verification.isTrusted && (verification.isPremium ?? false)

        console = """
        Reloaded signed server entitlement:
        signatureValid=\(verification.isSignatureValid)
        expired=\(verification.isExpired)
        trusted=\(verification.isTrusted)
        cachedPremium=\(verification.isPremium.map(String.init) ?? "<missing>")
        reason=\(verification.reason)

        \(serverClaimKey)=\(displaySignedClaim(cached))

        Lab note: this cache is for display and offline UX. A real app should revalidate with a trusted service or verify a signed platform receipt before granting access.
        """
    }

    func verifyServerEntitlementCache() {
        let cached = defaults.string(forKey: serverClaimKey) ?? "<missing>"
        let verification = entitlementAuthority.verifyCachedClaim(cached)
        serverAuthorizedPremium = verification.isTrusted && (verification.isPremium ?? false)

        console = """
        Signed claim verification:
        signatureValid=\(verification.isSignatureValid)
        expired=\(verification.isExpired)
        trusted=\(verification.isTrusted)
        premium=\(verification.isPremium.map(String.init) ?? "<missing>")
        reason=\(verification.reason)

        Verification boundary: the app can read the cached claim, but access is granted only when the signature is valid and the claim is still inside its validity window.
        """
    }

    func attemptLocalEntitlementOverride() {
        isPremiumEnabled = true
        defaults.set(true, forKey: "lab.premium.enabled")
        let cached = defaults.string(forKey: serverClaimKey) ?? "<missing>"
        let verification = entitlementAuthority.verifyCachedClaim(cached)
        serverAuthorizedPremium = verification.isTrusted && (verification.isPremium ?? false)

        console = """
        Local override attempt:
        lab.premium.enabled=true

        Signed server-authoritative decision:
        signatureValid=\(verification.isSignatureValid)
        trusted=\(verification.isTrusted)
        premium=\(serverAuthorizedPremium)

        \(serverClaimKey)=\(displaySignedClaim(cached))

        Result: changing the local boolean does not grant premium in the safer model. The feature decision follows the verified signed claim instead.
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

    private func displaySignedClaim(_ value: String) -> String {
        replacingMatches(
            in: value,
            pattern: #"signature=[^;\s]+"#,
            template: "signature=<redacted:signature>",
            options: []
        )
    }

    private func sanitizedFreeformText(_ value: String) -> String {
        var sanitized = value
        let replacements: [(pattern: String, template: String, options: NSRegularExpression.Options)] = [
            (#"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#, "<redacted:email>", [.caseInsensitive]),
            (#"\blab-token-[A-Za-z0-9-]+\b"#, "<redacted:token>", []),
            (#"\blab-observe-[A-Za-z0-9-]+\b"#, "<redacted:runtime-token>", []),
            (#"(?i)\b(password|passwd|pwd)\s*[:=]\s*[^,\s;]+"#, "$1=<redacted:password>", []),
            (#"/Users/[^\s`]+"#, "/Users/<redacted:path>", [])
        ]

        for replacement in replacements {
            sanitized = replacingMatches(
                in: sanitized,
                pattern: replacement.pattern,
                template: replacement.template,
                options: replacement.options
            )
        }
        return sanitized
    }

    private func replacingMatches(
        in value: String,
        pattern: String,
        template: String,
        options: NSRegularExpression.Options
    ) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options) else {
            return value
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return expression.stringByReplacingMatches(
            in: value,
            options: [],
            range: range,
            withTemplate: template
        )
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
        case "entitlement-free":
            requestServerEntitlement(account: "student@example.com")
        case "entitlement-paid":
            requestServerEntitlement(account: "paid@example.com")
        case "entitlement-override":
            requestServerEntitlement(account: "student@example.com")
            attemptLocalEntitlementOverride()
        case "entitlement-verify":
            requestServerEntitlement(account: "paid@example.com")
            verifyServerEntitlementCache()
        case "sanitized-report":
            prepareSanitizedReportDemo(exported: false)
        case "sanitized-report-exported":
            prepareSanitizedReportDemo(exported: true)
        default:
            break
        }
    }

    private func prepareSanitizedReportDemo(exported: Bool) {
        completedChallengeIDs = Set(LabChallenge.seed.map(\.id))
        notes[LabChallenge.seed[0].id] = "Demo note: account=student@example.com password=passw0rd token=lab-token-super-secret path=/Users/jungyeons/private.txt"
        persistProgress()
        persistNotes()
        generateSanitizedReport(challenges: LabChallenge.seed)

        if exported {
            reportExportStatus = "Exported sanitized Markdown report: iOSAppHackingLab-Sanitized-Study-Report.md"
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

struct ServerEntitlementClaim: Equatable {
    let accountHash: String
    let plan: String
    let isPremium: Bool
    let claimID: String
    let decisionSource: String
    let issuedAt: String
    let expiresAt: String
    let keyID: String
    let signature: String

    var algorithm: String {
        "P256-SHA256"
    }

    var signedPayload: String {
        Self.canonicalPayload(
            decisionSource: decisionSource,
            accountHash: accountHash,
            plan: plan,
            isPremium: isPremium,
            claimID: claimID,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            keyID: keyID
        )
    }

    var signatureFingerprint: String {
        "\(String(signature.prefix(18)))..."
    }

    var cacheValue: String {
        "\(signedPayload);signature=\(signature)"
    }

    static func canonicalPayload(
        decisionSource: String,
        accountHash: String,
        plan: String,
        isPremium: Bool,
        claimID: String,
        issuedAt: String,
        expiresAt: String,
        keyID: String
    ) -> String {
        [
            "source=\(decisionSource)",
            "accountHash=\(accountHash)",
            "plan=\(plan)",
            "premium=\(isPremium)",
            "claimID=\(claimID)",
            "issuedAt=\(issuedAt)",
            "expiresAt=\(expiresAt)",
            "keyID=\(keyID)"
        ].joined(separator: ";")
    }
}

struct SignedEntitlementVerification: Equatable {
    let isSignatureValid: Bool
    let isExpired: Bool
    let isTrusted: Bool
    let isPremium: Bool?
    let reason: String
}

struct SimulatedEntitlementAuthority {
    private static let signingKey: P256.Signing.PrivateKey = {
        let rawKey = Data(repeating: 0x01, count: 32)
        return try! P256.Signing.PrivateKey(rawRepresentation: rawKey)
    }()

    private let keyID = "lab-simulated-issuer-1"
    private let decisionSource = "simulated-server-authority"
    private let paidAccounts: Set<String> = [
        "paid@example.com",
        "portfolio-reviewer@example.com"
    ]

    func fetchEntitlement(account: String) -> ServerEntitlementClaim {
        let normalized = normalize(account)
        let isPremium = paidAccounts.contains(normalized)
        let plan = isPremium ? "premium" : "free"
        let issuedAt = timestamp()
        let expiresAt = timestamp(adding: 60 * 60 * 24 * 30)
        let accountHash = fingerprint(normalized)
        let claimID = "claim-\(fingerprint("\(normalized)|\(plan)"))"
        let signedPayload = ServerEntitlementClaim.canonicalPayload(
            decisionSource: decisionSource,
            accountHash: accountHash,
            plan: plan,
            isPremium: isPremium,
            claimID: claimID,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            keyID: keyID
        )

        return ServerEntitlementClaim(
            accountHash: accountHash,
            plan: plan,
            isPremium: isPremium,
            claimID: claimID,
            decisionSource: decisionSource,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            keyID: keyID,
            signature: signature(for: signedPayload)
        )
    }

    func cachedPremium(from cacheValue: String) -> Bool? {
        let verification = verifyCachedClaim(cacheValue)
        return verification.isTrusted ? verification.isPremium : nil
    }

    func verifyCachedClaim(_ cacheValue: String) -> SignedEntitlementVerification {
        let fields = parseFields(cacheValue)
        guard
            let source = fields["source"],
            let accountHash = fields["accountHash"],
            let plan = fields["plan"],
            let premiumValue = fields["premium"],
            let isPremium = Bool(premiumValue),
            let claimID = fields["claimID"],
            let issuedAt = fields["issuedAt"],
            let expiresAt = fields["expiresAt"],
            let claimKeyID = fields["keyID"],
            let signature = fields["signature"]
        else {
            return SignedEntitlementVerification(
                isSignatureValid: false,
                isExpired: false,
                isTrusted: false,
                isPremium: nil,
                reason: "missing required signed claim fields"
            )
        }

        let payload = ServerEntitlementClaim.canonicalPayload(
            decisionSource: source,
            accountHash: accountHash,
            plan: plan,
            isPremium: isPremium,
            claimID: claimID,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            keyID: claimKeyID
        )
        let signatureValid = isSignatureValid(signature, for: payload)
        let expired = isExpired(expiresAt)
        let trusted = source == decisionSource
            && claimKeyID == keyID
            && signatureValid
            && !expired
        let reason: String
        if trusted {
            reason = "signed claim accepted"
        } else if source != decisionSource {
            reason = "unexpected decision source"
        } else if claimKeyID != keyID {
            reason = "unexpected issuer key"
        } else if !signatureValid {
            reason = "signature verification failed"
        } else {
            reason = "claim expired"
        }

        return SignedEntitlementVerification(
            isSignatureValid: signatureValid,
            isExpired: expired,
            isTrusted: trusted,
            isPremium: isPremium,
            reason: reason
        )
    }

    private func normalize(_ account: String) -> String {
        let normalized = account
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return normalized.isEmpty ? "student@example.com" : normalized
    }

    private func fingerprint(_ value: String) -> String {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }

    private func timestamp(adding seconds: TimeInterval = 0) -> String {
        ISO8601DateFormatter().string(from: Date().addingTimeInterval(seconds))
    }

    private func signature(for payload: String) -> String {
        let data = Data(payload.utf8)
        let signature = try! Self.signingKey.signature(for: data)
        return signature.derRepresentation.base64EncodedString()
    }

    private func isSignatureValid(_ signature: String, for payload: String) -> Bool {
        guard
            let signatureData = Data(base64Encoded: signature),
            let signature = try? P256.Signing.ECDSASignature(derRepresentation: signatureData)
        else {
            return false
        }

        return Self.signingKey.publicKey.isValidSignature(signature, for: Data(payload.utf8))
    }

    private func isExpired(_ expiresAt: String) -> Bool {
        guard let expiration = ISO8601DateFormatter().date(from: expiresAt) else {
            return true
        }
        return expiration <= Date()
    }

    private func parseFields(_ cacheValue: String) -> [String: String] {
        cacheValue
            .split(separator: ";")
            .reduce(into: [String: String]()) { fields, entry in
                let parts = entry.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard parts.count == 2 else {
                    return
                }
                fields[String(parts[0])] = String(parts[1])
            }
    }
}
