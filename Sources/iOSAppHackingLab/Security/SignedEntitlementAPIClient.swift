import Foundation

protocol EntitlementAPISession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: EntitlementAPISession {}

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
