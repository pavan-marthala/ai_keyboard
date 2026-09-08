#ifndef RUNNER_PROMPT_REPOSITORY_H_
#define RUNNER_PROMPT_REPOSITORY_H_

#include <string>
#include <unordered_map>
#include <vector>

#include "generated/generated_command_definitions.h"

namespace atfix {

using CommandDefinition = atfix::generated::GeneratedCommandDefinition;

/// Repository responsible for loading and resolving canonical AI commands and prompts.
/// Mirrors macOS PromptRepository.swift and Android NativeCommandRegistry.kt.
class PromptRepository {
 public:
  static PromptRepository& GetInstance();

  PromptRepository(const PromptRepository&) = delete;
  PromptRepository& operator=(const PromptRepository&) = delete;

  /// Returns all registered command definitions sorted by order.
  const std::vector<CommandDefinition>& GetCommands() const;

  /// Looks up a command by trigger (e.g. "@fix", "@professional") or by id ("fix", "professional").
  /// Returns nullptr if not found or if deprecated (e.g. "@pro").
  const CommandDefinition* FindCommand(const std::string& trigger_or_id) const;

  /// Returns the action label for a command trigger or id, or a default fallback.
  std::string GetActionLabel(const std::string& trigger_or_id) const;

  /// Resolves the prompt for [key], interpolating variables like `{{variable}}`.
  std::string GetPrompt(const std::string& key,
                        const std::unordered_map<std::string, std::string>& variables = {});

  /// Returns whether a prompt or command exists for [key].
  bool HasPrompt(const std::string& key) const;

  /// Returns the canonical language display name for a language code.
  std::string GetLanguageName(const std::string& lang_code);

 private:
  PromptRepository();
  ~PromptRepository() = default;

  std::vector<CommandDefinition> commands_;
  std::unordered_map<std::string, size_t> command_by_id_;
  std::unordered_map<std::string, size_t> command_by_trigger_;
  std::unordered_map<std::string, std::string> prompts_;
  std::unordered_map<std::string, std::string> supported_languages_;
};

}  // namespace atfix

#endif  // RUNNER_PROMPT_REPOSITORY_H_

