import Foundation

struct SelfCheckResult {
    let didPass: Bool
    let output: String
}

enum SelfCheck {
    static func run() -> SelfCheckResult {
        var failures: [String] = []

        checkRedaction(failures: &failures)
        checkReportGeneration(failures: &failures)

        if failures.isEmpty {
            return SelfCheckResult(
                didPass: true,
                output: "Self-check passed: redaction and report generation are working."
            )
        }

        let details = failures.map { "- \($0)" }.joined(separator: "\n")
        return SelfCheckResult(
            didPass: false,
            output: "Self-check failed:\n\(details)"
        )
    }

    private static func checkRedaction(failures: inout [String]) {
        let account = "student@example.com"
        let token = "lab-token-super-secret"
        let redacted = RedactingLogger.redact(token)
        let event = RedactingLogger.loginSucceeded(account: account, token: token)

        expect(redacted != token, "Redaction returned the original token.", failures: &failures)
        expect(!redacted.contains(token), "Redaction output contains the original token.", failures: &failures)
        expect(redacted == "<redacted:22-chars>", "Redaction output changed unexpectedly.", failures: &failures)
        expect(!event.contains(account), "Safe log event contains the raw account.", failures: &failures)
        expect(!event.contains(token), "Safe log event contains the raw token.", failures: &failures)
        expect(event.contains("event=login_succeeded"), "Safe log event is missing its event name.", failures: &failures)
        expect(event.contains("eventID="), "Safe log event is missing its event ID.", failures: &failures)
    }

    private static func checkReportGeneration(failures: inout [String]) {
        let suiteName = "iOSAppHackingLab.self-check.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            failures.append("Could not create isolated defaults suite.")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = LabStore(defaults: defaults)
        let challenge = LabChallenge.seed[0]

        store.updateNote("Found plaintext UserDefaults keys.", for: challenge.id)
        store.toggleCompletion(for: challenge)
        store.generateReport(challenges: [challenge])

        expect(store.report.contains("# iOSAppHackingLab Study Report"), "Report is missing its title.", failures: &failures)
        expect(store.report.contains("## Executive Summary"), "Report is missing the executive summary.", failures: &failures)
        expect(store.report.contains("## Scope"), "Report is missing scope.", failures: &failures)
        expect(store.report.contains("Progress: 1/1 labs complete"), "Report progress is incorrect.", failures: &failures)
        expect(store.report.contains("- Status: [x] Complete"), "Report completion marker is incorrect.", failures: &failures)
        expect(store.report.contains("Evidence to capture:"), "Report is missing evidence prompts.", failures: &failures)
        expect(store.report.contains("Found plaintext UserDefaults keys."), "Report is missing saved notes.", failures: &failures)
        expect(store.report.contains("Out of scope: real user data"), "Report is missing the safety boundary.", failures: &failures)
    }

    private static func expect(_ condition: Bool, _ message: String, failures: inout [String]) {
        if !condition {
            failures.append(message)
        }
    }
}
