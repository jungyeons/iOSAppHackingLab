import Foundation

struct LabChallenge: Identifiable, Hashable {
    enum Kind: String, Hashable {
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
    let objective: String
    let attackSurface: String
    let risk: String
    let practice: String
    let inspectHints: [String]
    let evidencePrompts: [String]
    let saferPattern: String
    let portfolioTakeaway: String
    let completionCriteria: [String]
    let kind: Kind

    static let seed: [LabChallenge] = [
        LabChallenge(
            id: "insecure-storage",
            title: "Insecure Local Storage",
            category: "Storage",
            difficulty: "Beginner",
            summary: "Credentials are saved in UserDefaults as plaintext.",
            objective: "Compare preference storage with Keychain-backed storage and explain the trust boundary in plain language.",
            attackSurface: "Local app container",
            risk: "Client-side preference stores are easy to inspect and modify. Secrets stored here can leak through backups, local filesystem access, or careless debugging.",
            practice: "Save a username and password, then inspect the app container or defaults domain to find the stored values. The goal is to understand why secrets do not belong in simple preference storage.",
            inspectHints: [
                "Search the source for lab.username and lab.password.",
                "Inspect the app defaults after saving credentials.",
                "Compare this with Keychain-backed storage."
            ],
            evidencePrompts: [
                "Screenshot or paste the console output that shows the plaintext defaults keys.",
                "Record which code path stores the password in UserDefaults.",
                "Record the Keychain API calls used for the safer comparison."
            ],
            saferPattern: "Use Keychain for credentials, store only non-sensitive preferences in UserDefaults, and keep authentication decisions server-side when possible.",
            portfolioTakeaway: "Shows practical understanding of iOS/macOS local storage risks and how to explain a safer platform-native alternative.",
            completionCriteria: [
                "Created a plaintext credential entry from the lab UI.",
                "Identified the exact keys used to store the values.",
                "Wrote a short note explaining why Keychain is the safer default."
            ],
            kind: .insecureStorage
        ),
        LabChallenge(
            id: "weak-secret",
            title: "Weak Static Secret",
            category: "Crypto",
            difficulty: "Beginner",
            summary: "A message is protected with a hardcoded XOR byte.",
            objective: "Identify why client-side static secrets and reversible toy encoding are not security controls.",
            attackSurface: "Static analysis",
            risk: "Static client-side secrets can be recovered from the app binary. Toy encoding schemes provide obfuscation, not meaningful confidentiality.",
            practice: "Encode a payload and inspect the implementation. The goal is not to learn real encryption, but to spot static secrets and reversible toy schemes in client apps.",
            inspectHints: [
                "Search for weakKey in the source.",
                "Try changing the message and decoding it.",
                "Notice that anyone with the binary can recover the key."
            ],
            evidencePrompts: [
                "Capture one encoded payload and its decoded plaintext.",
                "Record the source location of the static key.",
                "Write one sentence distinguishing obfuscation from encryption."
            ],
            saferPattern: "Avoid embedding secrets in client apps. Use platform cryptography APIs for local protection and keep authoritative signing or authorization on a trusted backend.",
            portfolioTakeaway: "Demonstrates the ability to reason about reverse engineering findings without overstating client-side controls.",
            completionCriteria: [
                "Encoded at least one payload.",
                "Decoded the payload without additional server input.",
                "Documented why static client secrets are not a trust boundary."
            ],
            kind: .weakSecret
        ),
        LabChallenge(
            id: "verbose-logging",
            title: "Sensitive Debug Logging",
            category: "Logging",
            difficulty: "Beginner",
            summary: "A debug login writes a session token to NSLog.",
            objective: "Trace accidental sensitive-data exposure through development logs and propose a redacted alternative.",
            attackSurface: "Runtime output",
            risk: "Logs are often collected, shared, indexed, and retained longer than expected. Tokens or personal data in logs can become accidental data exposure.",
            practice: "Trigger the login and inspect the app output. The goal is to recognize sensitive data exposure through logs during development and testing.",
            inspectHints: [
                "Search for NSLog in the source.",
                "Search for RedactingLogger in the source.",
                "Run the app from Terminal to see stdout and stderr behavior.",
                "Think about production log redaction rules."
            ],
            evidencePrompts: [
                "Capture the generated token appearing in app output.",
                "Record the exact log statement that caused the exposure.",
                "Capture the redacted event log and confirm the raw token is absent.",
                "Draft a safer event-style log message with no raw secret."
            ],
            saferPattern: "Log events, states, and opaque correlation IDs instead of raw secrets. Centralize logging helpers so sensitive fields are redacted by default.",
            portfolioTakeaway: "Shows attention to operational security details that are easy to miss in ordinary app development.",
            completionCriteria: [
                "Triggered the debug login flow.",
                "Found the sensitive token in the app output path.",
                "Proposed a safer log message that preserves debugging value."
            ],
            kind: .verboseLogging
        ),
        LabChallenge(
            id: "tamperable-state",
            title: "Tamperable Entitlement",
            category: "Business Logic",
            difficulty: "Beginner",
            summary: "Premium state is trusted from a local boolean.",
            objective: "Show why authorization cannot rely on mutable local UI state or unsigned cached preferences.",
            attackSurface: "Local state tampering",
            risk: "Local-only entitlement state can be changed by the user. When the app trusts it directly, business logic can be bypassed without attacking a server.",
            practice: "Toggle premium, save it, reload it, then inspect where that state lives. The goal is to understand why authorization decisions need server-side validation or signed local state.",
            inspectHints: [
                "Search for lab.premium.enabled in the source.",
                "Inspect and modify the saved defaults value.",
                "Design a safer trust boundary for the entitlement."
            ],
            evidencePrompts: [
                "Capture both false and true entitlement values.",
                "Record where the entitlement state is persisted.",
                "Describe which component should make the authorization decision."
            ],
            saferPattern: "Validate entitlements with a trusted service, signed receipt, or cryptographically verifiable local claim. Treat local UI state as a cache, not authority.",
            portfolioTakeaway: "Connects local reverse engineering observations to product-level authorization design.",
            completionCriteria: [
                "Saved both false and true entitlement states.",
                "Identified the local key that controls the feature.",
                "Explained what component should be authoritative for premium access."
            ],
            kind: .tamperableState
        )
    ]
}
