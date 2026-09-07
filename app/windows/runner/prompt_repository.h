#ifndef RUNNER_PROMPT_REPOSITORY_H_
#define RUNNER_PROMPT_REPOSITORY_H_

#include <string>
#include <unordered_map>

namespace atfix {

/// Repository responsible for loading and resolving canonical AI prompts.
/// Strictly mirrors macOS PromptRepository.swift.
class PromptRepository {
 public:
  static PromptRepository& GetInstance();

  PromptRepository(const PromptRepository&) = delete;
  PromptRepository& operator=(const PromptRepository&) = delete;

  /// Resolves the prompt for [key], interpolating variables like `{{variable}}`.
  std::string GetPrompt(const std::string& key, const std::unordered_map<std::string, std::string>& variables = {});

  /// Returns the canonical language display name for a language code.
  std::string GetLanguageName(const std::string& lang_code);

 private:
  PromptRepository();
  ~PromptRepository() = default;

  void LoadFromFile();
  void InitializeFallbacks();

  std::unordered_map<std::string, std::string> prompts_;
  std::unordered_map<std::string, std::string> supported_languages_;
};

}  // namespace atfix

#endif  // RUNNER_PROMPT_REPOSITORY_H_

