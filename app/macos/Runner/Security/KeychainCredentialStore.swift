import Foundation
import Security

/// macOS Keychain storage for AI provider API credentials.
///
/// Uses Apple's Security framework (`kSecClassGenericPassword`) to securely
/// persist and retrieve API keys under service `"com.pk.ai_keyboard"`.
///
/// Follows strict security requirements:
/// - Never writes keys to disk files
/// - Never logs API keys or authorization headers
/// - Access is keyed by lowercased provider identifier (e.g. "openai", "gemini")
final class KeychainCredentialStore {

    static let shared = KeychainCredentialStore()

    private let service = "com.pk.ai_keyboard"

    private init() {}

    /// Saves or updates the API key for `provider`.
    @discardableResult
    func saveApiKey(provider: String, apiKey: String) -> Bool {
        let p = provider.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !p.isEmpty, !key.isEmpty else { return false }
        guard let data = key.data(using: .utf8) else { return false }

        let searchQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: p
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(searchQuery as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        if updateStatus == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: p,
                kSecValueData as String: data
            ]
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            return addStatus == errSecSuccess
        }

        return false
    }

    /// Reads the API key for `provider` from Keychain.
    func readApiKey(provider: String) -> String? {
        let p = provider.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty else { return nil }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
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

    /// Deletes the API key for `provider` from Keychain.
    @discardableResult
    func deleteApiKey(provider: String) -> Bool {
        let p = provider.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: p
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Checks if a non-empty API key exists for `provider`.
    func hasApiKey(provider: String) -> Bool {
        guard let key = readApiKey(provider: provider) else { return false }
        return !key.isEmpty
    }
}

