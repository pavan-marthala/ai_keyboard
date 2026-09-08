import Foundation

public typealias CommandDefinition = GeneratedCommandDefinition

/// Repository responsible for loading and resolving canonical AI commands and prompts
/// from generated command definitions.
public final class PromptRepository {

    public static let shared = PromptRepository()

    public static let supportedLanguages: [String: String] = [
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

    public enum PromptError: LocalizedError {
        case unknownKey(String)

        public var errorDescription: String? {
            switch self {
            case .unknownKey(let key):
                return "Unknown prompt key: '\(key)'"
            }
        }
    }

    private var prompts: [String: String] = [:]
    private var commandDefinitions: [CommandDefinition] = []
    private var commandsById: [String: CommandDefinition] = [:]
    private var commandsByTrigger: [String: CommandDefinition] = [:]

    public init(commands: [GeneratedCommandDefinition] = GeneratedCommandDefinitions.commands) {
        load(commands: commands)
    }

    public convenience init(bundle: Bundle) {
        self.init(commands: GeneratedCommandDefinitions.commands)
    }

    private func load(commands: [GeneratedCommandDefinition]) {
        let sorted = commands.sorted { $0.order < $1.order }
        self.commandDefinitions = sorted
        self.commandsById.removeAll()
        self.commandsByTrigger.removeAll()
        self.prompts.removeAll()

        for def in sorted {
            commandsById[def.id.lowercased()] = def
            commandsByTrigger[def.command.lowercased()] = def
            prompts[def.id.lowercased()] = def.system
        }
    }

    public func getCommands() -> [CommandDefinition] {
        return commandDefinitions
    }

    public func command(for triggerOrId: String) -> CommandDefinition? {
        let clean = triggerOrId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = clean.contains(":") ? String(clean.split(separator: ":")[0]) : clean
        if base == "@pro" || base == "pro" { return nil }
        return commandsByTrigger[base] ?? commandsById[base]
    }

    public func actionLabel(for triggerOrId: String) -> String {
        return command(for: triggerOrId)?.actionLabel ?? "Transforming..."
    }

    /// Resolves the prompt for [key], interpolating variables like `{{variable}}`.
    ///
    /// - Parameters:
    ///   - key: The prompt key or command trigger (e.g. "fix", "@rewrite", "translate").
    ///   - variables: Key-value pairs to interpolate into placeholders.
    /// - Returns: The resolved system prompt.
    /// - Throws: `PromptError.unknownKey` if key is not found.
    public func getPrompt(_ key: String, variables: [String: String] = [:]) throws -> String {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = clean.contains(":") ? String(clean.split(separator: ":")[0]) : clean
        if base == "@pro" || base == "pro" {
            throw PromptError.unknownKey(key)
        }

        let template: String
        if let direct = prompts[base] {
            template = direct
        } else if let cmd = command(for: base) {
            template = cmd.system
        } else {
            throw PromptError.unknownKey(key)
        }

        var result = template
        for (varName, varVal) in variables {
            result = result.replacingOccurrences(of: "{{\(varName)}}", with: varVal)
        }
        return result
    }

    public func hasPrompt(_ key: String) -> Bool {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = clean.contains(":") ? String(clean.split(separator: ":")[0]) : clean
        if base == "@pro" || base == "pro" { return false }
        return prompts[base] != nil || command(for: base) != nil
    }
}

