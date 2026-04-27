# iOSAppHackingLab Sanitized Study Report

Generated: 2026-04-27

## Executive Summary

This sample report documents defensive testing against the intentionally vulnerable `iOSAppHackingLab` simulator app. It is sanitized for a public portfolio: no real accounts, passwords, tokens, customer data, or third-party app details are included.

Progress: 5/5 labs complete

## Scope

- Target: `com.jungyeons.iosapphackinglab`
- Environment: iPhone 17 Pro Simulator, iOS 26.4.1
- Allowed activity: run this lab app, inspect its local simulator container, observe its lab-only runtime probe, and document safer designs
- Out of scope: third-party apps, production systems, real user data, and bypassing authorization on systems not owned for this lab

## Evidence Summary

| Lab | Evidence | Sanitization |
| --- | --- | --- |
| Insecure Local Storage | `lab.username` and `lab.password` appeared in the app defaults plist | Password value replaced with `<redacted>` |
| Weak Static Secret | Static `weakKey` source reference and reversible payload round trip | Payload replaced with a sample lab string |
| Sensitive Debug Logging | `NSLog` token flow and redacted event logger comparison | Raw token replaced with `<redacted:token>` |
| Tamperable Entitlement | `lab.premium.enabled` changed locally while signed server claim stayed authoritative | Account represented by hash only |
| Runtime Observation Drill | `LabObservationProbe` selector events observed in app output | Token and account values redacted |

## Insecure Local Storage

Finding: credentials written to `UserDefaults` are visible in the simulator app container.

Evidence command:

```bash
APP_DATA="$(xcrun simctl get_app_container booted com.jungyeons.iosapphackinglab data)"
plutil -p "$APP_DATA/Library/Preferences/com.jungyeons.iosapphackinglab.plist"
```

Sanitized evidence:

```text
lab.username = "student"
lab.password = "<redacted>"
```

Safer pattern: store credentials in Keychain and keep only non-sensitive preferences in `UserDefaults`.

## Weak Static Secret

Finding: a static XOR byte is embedded in the client and can be found by source or binary inspection.

Sanitized evidence:

```text
source symbol: weakKey
encoded payload: <sample-base64>
decoded payload: transfer=<sample>&to=lab-admin
```

Safer pattern: do not place authoritative secrets in the client. Use platform cryptography for local protection and server-side authorization for trusted decisions.

## Sensitive Debug Logging

Finding: the debug login path writes a generated session token to `NSLog`.

Sanitized evidence:

```text
DEBUG LOGIN token=<redacted:token>
event=login_succeeded account=<redacted:19-chars> token=<redacted:22-chars> eventID=<uuid>
```

Safer pattern: use event-style logs with redaction by default and avoid raw secrets in development or production logging.

## Tamperable Entitlement

Finding: `lab.premium.enabled` is a mutable local boolean and should not be treated as an authorization decision.

Sanitized evidence:

```text
lab.premium.enabled=true
lab.premium.serverClaim=source=simulated-server-authority;accountHash=<hash>;plan=free;premium=false;claimID=<claim-id>;issuedAt=<iso8601>;expiresAt=<iso8601>;keyID=lab-simulated-issuer-1;signature=<redacted:signature>
signatureValid=true
trusted=true
```

Observed result: changing the local boolean did not change the safer model's `serverAuthorizedPremium` decision.

Safer pattern: treat local state as cache only. A trusted service, signed receipt, or verifiable claim should be authoritative for premium access.

## Runtime Observation Drill

Finding: LLDB/Frida can observe lab-only runtime probe calls and map them back to source without changing app behavior.

Sanitized evidence:

```text
probe=start selector=startObservationWithAccount:token: accountHash=<hash> token=<redacted:48-chars>
probe=checkpoint selector=recordCheckpointWithLabel:secret: label=premium-evaluation secret=<redacted:48-chars>
probe=finish selector=finishObservationWithResult: result=standard-visible
```

Scope control: observation was limited to `com.jungyeons.iosapphackinglab` and `LabObservationProbe`.

## Takeaways

- Local app storage is easy to inspect in the simulator and should not hold secrets in plaintext.
- Client-side constants and local booleans are not trust boundaries.
- Runtime instrumentation is useful for authorized diagnostics, but evidence should be redacted before publication.
- Portfolio reports should show scope, method, evidence, risk, and safer design without exposing real secrets.
