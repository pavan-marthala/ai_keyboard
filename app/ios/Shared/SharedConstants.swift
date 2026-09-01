import Foundation

struct SharedConstants {
    static let appGroupIdentifier = "group.com.pk.ai_keyboard.shared"
    static let keychainService = "com.pk.ai_keyboard.apiKey"
    static let channelName = "com.pk.ai_keyboard/credentials"

    static let supportedProviders: Set<String> = [
        "openai",
        "gemini",
        "openrouter",
        "groq"
    ]
}

