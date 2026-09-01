import Foundation
import Security

class KeychainCredentialStore {

    static let shared = KeychainCredentialStore()

    private init() {}

    @discardableResult
    func saveApiKey(provider: String, apiKey: String) -> Bool {
        let p = provider.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !p.isEmpty, !key.isEmpty else { return false }
        guard SharedConstants.supportedProviders.contains(p) else { return false }
        guard let data = key.data(using: .utf8) else { return false }

        let searchQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SharedConstants.keychainService,
            kSecAttrAccount as String: p
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(searchQuery as CFDictionary, updateAttributes as CFDictionary)
        if status == errSecSuccess {
            return true
        }

        if status == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: SharedConstants.keychainService,
                kSecAttrAccount as String: p,
                kSecValueData as String: data
            ]
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            return addStatus == errSecSuccess
        }

        return false
    }

    func readApiKey(provider: String) -> String? {
        let p = provider.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty else { return nil }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SharedConstants.keychainService,
            kSecAttrAccount as String: p,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    @discardableResult
    func deleteApiKey(provider: String) -> Bool {
        let p = provider.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SharedConstants.keychainService,
            kSecAttrAccount as String: p
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    func hasApiKey(provider: String) -> Bool {
        let key = readApiKey(provider: provider)
        return key != nil && !key!.isEmpty
    }
}

