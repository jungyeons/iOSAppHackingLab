import Foundation

struct SelfCheckResult {
    let didPass: Bool
    let output: String
}

enum SelfCheck {
    static func run() -> SelfCheckResult {
        var failures: [String] = []

        checkRedaction(failures: &failures)
        checkObservationProbe(failures: &failures)
        checkServerEntitlement(failures: &failures)
        checkSignedEntitlementAPIClient(failures: &failures)
        checkReportGeneration(failures: &failures)
        checkSanitizedReportExport(failures: &failures)

        if failures.isEmpty {
            return SelfCheckResult(
                didPass: true,
                output: "Self-check passed: redaction, signed entitlement authority, signed entitlement API client, observation probe, report generation, and sanitized export are working."
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

    private static func checkObservationProbe(failures: inout [String]) {
        let account = "student@example.com"
        let token = "lab-token-super-secret"
        let probe = LabObservationProbe.shared
        let startEvent = probe.startObservation(account: account, token: token)
        let checkpointEvent = probe.recordCheckpoint(label: "self-check", secret: token)
        let finishEvent = probe.finishObservation(result: "ok")

        expect(startEvent.contains("LabObservationProbe") == false, "Probe event should stay compact and event-focused.", failures: &failures)
        expect(startEvent.contains("accountHash="), "Probe start event is missing the account fingerprint.", failures: &failures)
        expect(startEvent.contains("<redacted:22-chars>"), "Probe start event is missing the redacted token length.", failures: &failures)
        expect(!startEvent.contains(account), "Probe start event contains the raw account.", failures: &failures)
        expect(!startEvent.contains(token), "Probe start event contains the raw token.", failures: &failures)
        expect(checkpointEvent.contains("label=self-check"), "Probe checkpoint event is missing its label.", failures: &failures)
        expect(!checkpointEvent.contains(token), "Probe checkpoint event contains the raw token.", failures: &failures)
        expect(finishEvent.contains("result=ok"), "Probe finish event is missing its result.", failures: &failures)
    }

    private static func checkSanitizedReportExport(failures: inout [String]) {
        let suiteName = "iOSAppHackingLab.sanitized-report.self-check.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            failures.append("Could not create isolated defaults suite for sanitized report.")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = LabStore(defaults: defaults)
        let note = "account=student@example.com password=passw0rd token=lab-token-super-secret path=/Users/jungyeons/private.txt"
        store.updateNote(note, for: LabChallenge.seed[0].id)
        store.generateSanitizedReport(challenges: [LabChallenge.seed[0]])

        expect(store.sanitizedReport.contains("# iOSAppHackingLab Sanitized Study Report"), "Sanitized report is missing its title.", failures: &failures)
        expect(store.sanitizedReport.contains("<redacted:email>"), "Sanitized report did not redact email-like text.", failures: &failures)
        expect(store.sanitizedReport.contains("<redacted:password>"), "Sanitized report did not redact password-like text.", failures: &failures)
        expect(store.sanitizedReport.contains("<redacted:token>"), "Sanitized report did not redact lab token text.", failures: &failures)
        expect(store.sanitizedReport.contains("/Users/<redacted:path>"), "Sanitized report did not redact local user path.", failures: &failures)
        expect(!store.sanitizedReport.contains("student@example.com"), "Sanitized report contains a raw email.", failures: &failures)
        expect(!store.sanitizedReport.contains("passw0rd"), "Sanitized report contains a raw password sample.", failures: &failures)
        expect(!store.sanitizedReport.contains("lab-token-super-secret"), "Sanitized report contains a raw token.", failures: &failures)
    }

    private static func checkServerEntitlement(failures: inout [String]) {
        let authority = SimulatedEntitlementAuthority()
        let freeClaim = authority.fetchEntitlement(account: "student@example.com")
        let paidClaim = authority.fetchEntitlement(account: "paid@example.com")
        let freeVerification = authority.verifyCachedClaim(freeClaim.cacheValue)
        let paidVerification = authority.verifyCachedClaim(paidClaim.cacheValue)
        let tamperedPaidClaim = paidClaim.cacheValue.replacingOccurrences(of: "premium=true", with: "premium=false")
        let tamperedVerification = authority.verifyCachedClaim(tamperedPaidClaim)

        expect(!freeClaim.isPremium, "Student account should not be premium in the simulated authority.", failures: &failures)
        expect(paidClaim.isPremium, "Paid account should be premium in the simulated authority.", failures: &failures)
        expect(freeClaim.cacheValue.contains("simulated-server-authority"), "Entitlement cache is missing its decision source.", failures: &failures)
        expect(freeClaim.cacheValue.contains("signature="), "Entitlement cache is missing its signature.", failures: &failures)
        expect(freeClaim.cacheValue.contains("keyID=lab-simulated-issuer-1"), "Entitlement cache is missing its issuer key ID.", failures: &failures)
        expect(!paidClaim.cacheValue.contains("paid@example.com"), "Entitlement cache contains the raw account.", failures: &failures)
        expect(freeVerification.isTrusted, "Free signed entitlement should be trusted.", failures: &failures)
        expect(paidVerification.isTrusted, "Paid signed entitlement should be trusted.", failures: &failures)
        expect(freeVerification.isSignatureValid, "Free signed entitlement signature should be valid.", failures: &failures)
        expect(paidVerification.isSignatureValid, "Paid signed entitlement signature should be valid.", failures: &failures)
        expect(authority.cachedPremium(from: freeClaim.cacheValue) == false, "Free cached entitlement parsed incorrectly.", failures: &failures)
        expect(authority.cachedPremium(from: paidClaim.cacheValue) == true, "Paid cached entitlement parsed incorrectly.", failures: &failures)
        expect(!tamperedVerification.isTrusted, "Tampered signed entitlement should not be trusted.", failures: &failures)
        expect(!tamperedVerification.isSignatureValid, "Tampered signed entitlement signature should be invalid.", failures: &failures)
        expect(authority.cachedPremium(from: tamperedPaidClaim) == nil, "Tampered cached entitlement should not return a premium decision.", failures: &failures)
    }

    private static func checkSignedEntitlementAPIClient(failures: inout [String]) {
        guard let baseURL = URL(string: "https://api.example.test") else {
            failures.append("Could not create signed entitlement API base URL.")
            return
        }

        let client = SignedEntitlementAPIClient(baseURL: baseURL)
        let keyRequest = client.keyDiscoveryRequest()
        expect(keyRequest.httpMethod == "GET", "Key discovery request should use GET.", failures: &failures)
        expect(
            keyRequest.url?.path == "/.well-known/iosapphackinglab-entitlement-keys.json",
            "Key discovery request path is incorrect.",
            failures: &failures
        )
        expect(
            keyRequest.value(forHTTPHeaderField: "Accept") == "application/json",
            "Key discovery request should accept JSON.",
            failures: &failures
        )

        let idempotencyKey = UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
        let claimRequest: URLRequest
        do {
            claimRequest = try client.claimRequest(
                sessionToken: "session-token-placeholder",
                clientVersion: "1.0.0",
                idempotencyKey: idempotencyKey
            )
        } catch {
            failures.append("Could not build signed entitlement claim request: \(error)")
            return
        }

        expect(claimRequest.httpMethod == "POST", "Claim request should use POST.", failures: &failures)
        expect(
            claimRequest.url?.path == "/v1/entitlements/claims",
            "Claim request path is incorrect.",
            failures: &failures
        )
        expect(
            claimRequest.value(forHTTPHeaderField: "Authorization") == "Bearer session-token-placeholder",
            "Claim request authorization header is incorrect.",
            failures: &failures
        )
        expect(
            claimRequest.value(forHTTPHeaderField: "Idempotency-Key") == idempotencyKey.uuidString,
            "Claim request idempotency key is incorrect.",
            failures: &failures
        )

        if let body = claimRequest.httpBody,
           let decodedBody = try? JSONDecoder().decode(SignedEntitlementClaimRequest.self, from: body) {
            expect(
                decodedBody.audience == SignedEntitlementAPIClient.defaultAudience,
                "Claim request body has an unexpected audience.",
                failures: &failures
            )
            expect(decodedBody.deviceClass == "ios-simulator", "Claim request body has an unexpected device class.", failures: &failures)
            expect(decodedBody.clientVersion == "1.0.0", "Claim request body has an unexpected client version.", failures: &failures)
        } else {
            failures.append("Claim request body could not be decoded.")
        }

        let keySetJSON = """
        {
          "issuer": "https://api.example.test",
          "keys": [
            {
              "kid": "entitlement-p256-2026-04",
              "alg": "ES256",
              "kty": "EC",
              "crv": "P-256",
              "use": "sig",
              "x": "base64url-public-x",
              "y": "base64url-public-y",
              "expiresAt": "2026-07-01T00:00:00Z"
            }
          ]
        }
        """
        let claimJSON = """
        {
          "claim": {
            "iss": "https://api.example.test",
            "aud": "com.jungyeons.iosapphackinglab",
            "sub": "acct_hash_2f7a3e4a",
            "plan": "premium",
            "premium": true,
            "scope": ["lab.read", "premium.demo"],
            "iat": "2026-04-27T12:00:00Z",
            "exp": "2026-04-28T12:00:00Z",
            "jti": "claim_01JZLABDEMO0001"
          },
          "signature": {
            "alg": "ES256",
            "kid": "entitlement-p256-2026-04",
            "value": "base64url-es256-signature"
          }
        }
        """

        do {
            let keySet = try client.decodeKeySet(from: Data(keySetJSON.utf8))
            let response = try client.decodeClaimResponse(from: Data(claimJSON.utf8))

            expect(keySet.issuer == "https://api.example.test", "Decoded key set issuer is incorrect.", failures: &failures)
            expect(keySet.keys.first?.kid == "entitlement-p256-2026-04", "Decoded key ID is incorrect.", failures: &failures)
            expect(response.claim.aud == SignedEntitlementAPIClient.defaultAudience, "Decoded claim audience is incorrect.", failures: &failures)
            expect(response.claim.premium, "Decoded claim should be premium.", failures: &failures)
            expect(response.signature.alg == "ES256", "Decoded signature algorithm is incorrect.", failures: &failures)
        } catch {
            failures.append("Could not decode signed entitlement API example JSON: \(error)")
        }
    }

    private static func expect(_ condition: Bool, _ message: String, failures: inout [String]) {
        if !condition {
            failures.append(message)
        }
    }
}
