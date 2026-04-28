# Signed Entitlement API Contract

This document turns the local `SimulatedEntitlementAuthority` into a production-style API contract. It is still a defensive lab example: use it to reason about app authorization boundaries, not to test third-party apps or services.

## Design Goal

The app may cache a claim for offline display, but premium access is granted only when the claim is issued by a trusted server, signed with a server-held private key, scoped to this app, and still inside its validity window.

In production, the private signing key must stay server-side. The app receives only public verification keys.

## Public Key Discovery

```http
GET /.well-known/iosapphackinglab-entitlement-keys.json
Accept: application/json
```

Example response:

```json
{
  "issuer": "https://api.example.test",
  "keys": [
    {
      "kid": "entitlement-p256-2026-04",
      "alg": "ES256",
      "kty": "EC",
      "crv": "P-256",
      "use": "sig",
      "x": "<base64url-public-x>",
      "y": "<base64url-public-y>",
      "expiresAt": "2026-07-01T00:00:00Z"
    }
  ]
}
```

## Claim Request

```http
POST /v1/entitlements/claims
Authorization: Bearer <session-token>
Content-Type: application/json
Idempotency-Key: <uuid>
```

Request body:

```json
{
  "audience": "com.jungyeons.iosapphackinglab",
  "deviceClass": "ios-simulator",
  "clientVersion": "1.0.0"
}
```

The authenticated session identifies the account. The request body does not need to send a raw email address for the entitlement decision.

## Claim Response

```json
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
    "value": "<base64url-es256-signature>"
  }
}
```

The server signs a canonical UTF-8 payload containing the `claim` object. A real implementation should standardize canonicalization, key rotation, and replay protection before release.

## Client Verification Rules

The app should reject the claim unless all checks pass:

- `signature.kid` maps to a trusted public key.
- `signature.alg` is the expected algorithm.
- The signature verifies over the canonical claim payload.
- `claim.iss` matches the trusted issuer.
- `claim.aud` matches the app bundle identifier.
- `claim.exp` is in the future and `claim.iat` is not suspiciously far ahead of device time.
- `claim.jti` has not been revoked when the app can reach the server.
- The app treats the local cache as a hint only; sensitive server actions still require server-side authorization.

## Swift Async Client Stub

The lab includes a compile-checked client stub at `Sources/iOSAppHackingLab/Security/SignedEntitlementAPIClient.swift`.

It models the production contract without calling a real service:

- `fetchKeySet()` builds `GET /.well-known/iosapphackinglab-entitlement-keys.json`.
- `requestClaim(...)` builds `POST /v1/entitlements/claims` with `Authorization`, `Content-Type`, and `Idempotency-Key`.
- `SignedEntitlementClaimRequest` encodes `audience`, `deviceClass`, and `clientVersion`.
- `SignedEntitlementAPIResponse` decodes the signed claim envelope shown above.
- `SelfCheck` validates request construction and JSON decoding so future edits do not silently drift from this contract.

Example use in a real app boundary:

```swift
let client = SignedEntitlementAPIClient(baseURL: URL(string: "https://api.example.test")!)
let keys = try await client.fetchKeySet()
let response = try await client.requestClaim(
    sessionToken: sessionTokenFromSignIn,
    clientVersion: "1.0.0"
)
```

The stub deliberately does not persist raw session tokens or account identifiers. Verification logic should still check the returned signature and claim fields before granting access.

## In-App Mock Action

The Tamperable Entitlement lab connects the client stub to a live SwiftUI action: `Run API Client Mock`.

That button uses `MockSignedEntitlementAPISession` as a local stand-in for the server. It performs the same async client flow as a real integration:

1. Fetch the issuer key set.
2. Request a signed entitlement claim.
3. Decode the claim envelope.
4. Check issuer, audience, key ID, and algorithm.
5. Update the UI premium state from the accepted mock claim.

Use `paid@example.com` or `portfolio-reviewer@example.com` to exercise the premium mock response. Other accounts return a signed free-plan response. The console redacts the mock session token and displays only portfolio-safe metadata.

## Status Codes

| Status | Meaning | Client behavior |
| --- | --- | --- |
| `200` | Signed claim returned | Verify, then cache the verified result |
| `401` | Missing or invalid session | Sign in again |
| `403` | Account is not entitled | Cache a signed non-premium claim if provided |
| `409` | Idempotency conflict | Retry with a new idempotency key |
| `429` | Rate limited | Back off and keep the last verified cache for display only |
| `500` | Server error | Do not grant new access from an unsigned or stale response |

## Mapping To This Lab

`SimulatedEntitlementAuthority` uses a deterministic in-app P-256 key so the lab can run fully offline. That is intentionally not production-safe. The learning target is the verification boundary:

- `lab.premium.enabled` is mutable local UI state.
- `lab.premium.serverClaim` is accepted only after signature, issuer, key ID, and expiration checks.
- A tampered cached claim returns `trusted=false` and does not grant premium access.
