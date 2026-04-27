import Foundation
import Security

enum KeychainService {
    private static let service = "iOSAppHackingLab.local-lab"

    static func savePassword(_ password: String, account: String) -> Result<Void, KeychainError> {
        guard let data = password.data(using: .utf8) else {
            return .failure(.invalidData)
        }

        let query = baseQuery(account: account)
        let attributes = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return .success(())
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return .success(())
        }

        return .failure(.securityFramework(status: addStatus))
    }

    static func readPassword(account: String) -> Result<String?, KeychainError> {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return .success(nil)
        }

        guard status == errSecSuccess else {
            return .failure(.securityFramework(status: status))
        }

        guard let data = item as? Data, let password = String(data: data, encoding: .utf8) else {
            return .failure(.invalidData)
        }

        return .success(password)
    }

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum KeychainError: Error {
    case invalidData
    case securityFramework(status: OSStatus)

    var message: String {
        switch self {
        case .invalidData:
            return "The password could not be encoded as UTF-8 data."
        case .securityFramework(let status):
            let message = SecCopyErrorMessageString(status, nil) as String?
            return message ?? "Security framework returned OSStatus \(status)."
        }
    }
}
