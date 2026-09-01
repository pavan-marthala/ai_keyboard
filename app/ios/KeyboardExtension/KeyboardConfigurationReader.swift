import Foundation

class KeyboardConfigurationReader {

    static let shared = KeyboardConfigurationReader()

    private init() {}

    func getConfiguration() -> SharedAIConfiguration? {
        return SharedConfigurationStore.shared.getConfig()
    }

    func hasConfiguredApiKey() -> Bool {
        guard let config = getConfiguration() else { return false }
        return KeychainCredentialStore.shared.hasApiKey(provider: config.activeProvider)
    }

    func getApiKeyForActiveProvider() -> String? {
        guard let config = getConfiguration() else { return nil }
        return KeychainCredentialStore.shared.readApiKey(provider: config.activeProvider)
    }

    func isCommandEnabled(_ trigger: String) -> Bool {
        return SharedConfigurationStore.shared.isCommandEnabled(trigger)
    }
}

