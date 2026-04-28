import Foundation

protocol EntitlementAPISession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: EntitlementAPISession {}

struct MockSignedEntitlementAPISession: EntitlementAPISession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let path = request.url?.path ?? ""
        let responseURL = request.url ?? URL(string: "https://api.example.test")!

        switch (request.httpMethod, path) {
        case ("GET", "/.well-known/iosapphackinglab-entitlement-keys.json"):
            return try jsonResponse(
                [
                    "issuer": "https://api.example.test",
                    "keys": [
                        [
                            "kid": "entitlement-p256-2026-04",
                            "alg": "ES256",
                            "kty": "EC",
                            "crv": "P-256",
                            "use": "sig",
                            "x": "base64url-public-x",
                            "y": "base64url-public-y",
                            "expiresAt": "2026-07-01T00:00:00Z"
                        ]
                    ]
                ],
                url: responseURL
            )
        case ("POST", "/v1/entitlements/claims"):
            let token = request.value(forHTTPHeaderField: "Authorization") ?? ""
            let isPremium = token.contains("mock-paid-session")
            let plan = isPremium ? "premium" : "free"
            let claimID = isPremium ? "claim_mock_paid_0001" : "claim_mock_free_0001"
            let subject = isPremium ? "acct_hash_paid_mock" : "acct_hash_free_mock"

            return try jsonResponse(
                [
                    "claim": [
                        "iss": "https://api.example.test",
                        "aud": SignedEntitlementAPIClient.defaultAudience,
                        "sub": subject,
                        "plan": plan,
                        "premium": isPremium,
                        "scope": isPremium ? ["lab.read", "premium.demo"] : ["lab.read"],
                        "iat": "2026-04-28T00:00:00Z",
                        "exp": "2026-04-29T00:00:00Z",
                        "jti": claimID
                    ],
                    "signature": [
                        "alg": "ES256",
                        "kid": "entitlement-p256-2026-04",
                        "value": "base64url-es256-signature-\(plan)"
                    ]
                ],
                url: responseURL
            )
        default:
            return try jsonResponse(
                ["error": "not_found"],
                statusCode: 404,
                url: responseURL
            )
        }
    }

    private func jsonResponse(
        _ object: [String: Any],
        statusCode: Int = 200,
        url: URL
    ) throws -> (Data, URLResponse) {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (data, response)
    }
}

struct SignedEntitlementAPIClient {
    static let defaultAudience = "com.jungyeons.iosapphackinglab"

    let baseURL: URL
    let session: any EntitlementAPISession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL, session: any EntitlementAPISession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchKeySet() async throws -> SignedEntitlementKeySet {
        let request = keyDiscoveryRequest()
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decodeKeySet(from: data)
    }

    func requestClaim(
        sessionToken: String,
        audience: String = Self.defaultAudience,
        deviceClass: String = "ios-simulator",
        clientVersion: String,
        idempotencyKey: UUID = UUID()
    ) async throws -> SignedEntitlementAPIResponse {
        let request = try claimRequest(
            sessionToken: sessionToken,
            audience: audience,
            deviceClass: deviceClass,
            clientVersion: clientVersion,
            idempotencyKey: idempotencyKey
        )
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decodeClaimResponse(from: data)
    }

    func keyDiscoveryRequest() -> URLRequest {
        var request = URLRequest(url: endpoint(".well-known/iosapphackinglab-entitlement-keys.json"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    func claimRequest(
        sessionToken: String,
        audience: String = Self.defaultAudience,
        deviceClass: String = "ios-simulator",
        clientVersion: String,
        idempotencyKey: UUID
    ) throws -> URLRequest {
        var request = URLRequest(url: endpoint("v1/entitlements/claims"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        request.setValue(idempotencyKey.uuidString, forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = try encoder.encode(
            SignedEntitlementClaimRequest(
                audience: audience,
                deviceClass: deviceClass,
                clientVersion: clientVersion
            )
        )
        return request
    }

    func decodeKeySet(from data: Data) throws -> SignedEntitlementKeySet {
        try decoder.decode(SignedEntitlementKeySet.self, from: data)
    }

    func decodeClaimResponse(from data: Data) throws -> SignedEntitlementAPIResponse {
        try decoder.decode(SignedEntitlementAPIResponse.self, from: data)
    }

    private func endpoint(_ path: String) -> URL {
        let cleaned = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return baseURL.appendingPathComponent(cleaned)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SignedEntitlementAPIClientError.invalidHTTPResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(decoding: data, as: UTF8.self)
            throw SignedEntitlementAPIClientError.unexpectedStatus(httpResponse.statusCode, body)
        }
    }
}

enum SignedEntitlementAPIClientError: Error, Equatable {
    case invalidHTTPResponse
    case unexpectedStatus(Int, String)
}

struct SignedEntitlementKeySet: Decodable, Equatable {
    let issuer: String
    let keys: [SignedEntitlementPublicKey]
}

struct SignedEntitlementPublicKey: Decodable, Equatable {
    let kid: String
    let alg: String
    let kty: String
    let crv: String
    let use: String
    let x: String
    let y: String
    let expiresAt: String
}

struct SignedEntitlementClaimRequest: Codable, Equatable {
    let audience: String
    let deviceClass: String
    let clientVersion: String
}

struct SignedEntitlementAPIResponse: Decodable, Equatable {
    let claim: SignedEntitlementAPIClaim
    let signature: SignedEntitlementAPISignature
}

struct SignedEntitlementAPIClaim: Decodable, Equatable {
    let iss: String
    let aud: String
    let sub: String
    let plan: String
    let premium: Bool
    let scope: [String]
    let iat: String
    let exp: String
    let jti: String
}

struct SignedEntitlementAPISignature: Decodable, Equatable {
    let alg: String
    let kid: String
    let value: String
}
