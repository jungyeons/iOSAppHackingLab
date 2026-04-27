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
    let risk: String
    let practice: String
    let inspectHints: [String]
    let saferPattern: String
    let completionCriteria: [String]
    let kind: Kind

    static let seed: [LabChallenge] = [
        LabChallenge(
            id: "insecure-storage",
            title: "Insecure Local Storage",
            category: "Storage",
            difficulty: "Beginner",
            summary: "Credentials are saved in UserDefaults as plaintext.",
            risk: "Client-side preference stores are easy to inspect and modify. Secrets stored here can leak through backups, local filesystem access, or careless debugging.",
            practice: "Save a username and password, then inspect the app container or defaults domain to find the stored values. The goal is to understand why secrets do not belong in simple preference storage.",
            inspectHints: [
                "Search the source for lab.username and lab.password.",
                "Inspect the app defaults after saving credentials.",
                "Compare this with Keychain-backed storage."
            ],
            saferPattern: "Use Keychain for credentials, store only non-sensitive preferences in UserDefaults, and keep authentication decisions server-side when possible.",
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
            risk: "Static client-side secrets can be recovered from the app binary. Toy encoding schemes provide obfuscation, not meaningful confidentiality.",
            practice: "Encode a payload and inspect the implementation. The goal is not to learn real encryption, but to spot static secrets and reversible toy schemes in client apps.",
            inspectHints: [
                "Search for weakKey in the source.",
                "Try changing the message and decoding it.",
                "Notice that anyone with the binary can recover the key."
            ],
            saferPattern: "Avoid embedding secrets in client apps. Use platform cryptography APIs for local protection and keep authoritative signing or authorization on a trusted backend.",
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
            risk: "Logs are often collected, shared, indexed, and retained longer than expected. Tokens or personal data in logs can become accidental data exposure.",
            practice: "Trigger the login and inspect the app output. The goal is to recognize sensitive data exposure through logs during development and testing.",
            inspectHints: [
                "Search for NSLog in the source.",
                "Run the app from Terminal to see stdout and stderr behavior.",
                "Think about production log redaction rules."
            ],
            saferPattern: "Log events, states, and opaque correlation IDs instead of raw secrets. Centralize logging helpers so sensitive fields are redacted by default.",
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
            risk: "Local-only entitlement state can be changed by the user. When the app trusts it directly, business logic can be bypassed without attacking a server.",
            practice: "Toggle premium, save it, reload it, then inspect where that state lives. The goal is to understand why authorization decisions need server-side validation or signed local state.",
            inspectHints: [
                "Search for lab.premium.enabled in the source.",
                "Inspect and modify the saved defaults value.",
                "Design a safer trust boundary for the entitlement."
            ],
            saferPattern: "Validate entitlements with a trusted service, signed receipt, or cryptographically verifiable local claim. Treat local UI state as a cache, not authority.",
            completionCriteria: [
                "Saved both false and true entitlement states.",
                "Identified the local key that controls the feature.",
                "Explained what component should be authoritative for premium access."
            ],
            kind: .tamperableState
        )
    ]
}
