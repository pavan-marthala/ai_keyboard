import Foundation

struct ParsedCommand {
    let baseTrigger: String
    let cleanText: String
    let fullMatchLength: Int
    let prompt: String
    let statusMessage: String
    let arguments: [String: String]
}

class CommandParser {

    static let supportedLanguages: [String: String] = [
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "pt": "Portuguese",
        "hi": "Hindi",
        "te": "Telugu",
        "kn": "Kannada",
        "ta": "Tamil"
    ]

    static func parse(inputText: String) -> ParsedCommand? {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        let pattern = #"(?i)\s+(@[a-zA-Z0-9_:-]+)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }

        let range = NSRange(location: 0, length: trimmed.utf16.count)
        guard let match = regex.firstMatch(in: trimmed, options: [], range: range) else { return nil }

        guard let tokenRange = Range(match.range(at: 1), in: trimmed) else { return nil }
        let fullMatchLength = match.range(at: 0).length

        let commandToken = String(trimmed[tokenRange])
        let cleanText = String(trimmed.prefix(match.range(at: 0).location)).trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.isEmpty { return nil }

        let tokenLower = commandToken.lowercased()

        if tokenLower.hasPrefix("@translate:") {
            let parts = tokenLower.components(separatedBy: ":")
            if parts.count >= 2 {
                let langCode = parts[1]
                guard let langName = supportedLanguages[langCode] else { return nil }

                let prompt = "Translate the user's text into \(langName). Return ONLY the translated text."
                let statusMessage = "✨ Translating to \(langName)..."

                return ParsedCommand(
                    baseTrigger: "@translate",
                    cleanText: cleanText,
                    fullMatchLength: fullMatchLength,
                    prompt: prompt,
                    statusMessage: statusMessage,
                    arguments: ["language": langCode]
                )
            }
            return nil
        }

        switch tokenLower {
        case "@fix":
            return ParsedCommand(
                baseTrigger: "@fix",
                cleanText: cleanText,
                fullMatchLength: fullMatchLength,
                prompt: "Correct the user's text. Return ONLY the corrected text.",
                statusMessage: "✨ Fixing...",
                arguments: [:]
            )
        case "@rewrite":
            return ParsedCommand(
                baseTrigger: "@rewrite",
                cleanText: cleanText,
                fullMatchLength: fullMatchLength,
                prompt: "Rewrite the user's text while preserving its original meaning. Return ONLY the rewritten text.",
                statusMessage: "✨ Rewriting...",
                arguments: [:]
            )
        case "@pro":
            return ParsedCommand(
                baseTrigger: "@pro",
                cleanText: cleanText,
                fullMatchLength: fullMatchLength,
                prompt: "Rewrite the user's text in a clear, professional tone. Return ONLY the transformed text.",
                statusMessage: "✨ Making professional...",
                arguments: [:]
            )
        case "@casual":
            return ParsedCommand(
                baseTrigger: "@casual",
                cleanText: cleanText,
                fullMatchLength: fullMatchLength,
                prompt: "Rewrite the user's text in a natural, friendly tone. Return ONLY the transformed text.",
                statusMessage: "✨ Making casual...",
                arguments: [:]
            )
        case "@short":
            return ParsedCommand(
                baseTrigger: "@short",
                cleanText: cleanText,
                fullMatchLength: fullMatchLength,
                prompt: "Make the user's text shorter and more concise while preserving its meaning. Return ONLY the shortened text.",
                statusMessage: "✨ Shortening...",
                arguments: [:]
            )
        case "@expand":
            return ParsedCommand(
                baseTrigger: "@expand",
                cleanText: cleanText,
                fullMatchLength: fullMatchLength,
                prompt: "Expand the user's text to make it clearer and more complete. Return ONLY the expanded text.",
                statusMessage: "✨ Expanding...",
                arguments: [:]
            )
        default:
            return nil
        }
    }
}

