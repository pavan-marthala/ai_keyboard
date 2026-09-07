#ifndef RUNNER_AI_TRANSFORMER_H_
#define RUNNER_AI_TRANSFORMER_H_

#include <string>
#include <memory>
#include <unordered_map>
#include "ai_provider.h"

namespace atfix {

/// Orchestrator for transforming text using the active AI provider on native Windows.
/// Strictly mirrors macOS AiTransformer.swift.
class AiTransformer {
 public:
  static AiTransformer& GetInstance();

  AiTransformer(const AiTransformer&) = delete;
  AiTransformer& operator=(const AiTransformer&) = delete;

  /// Transforms `text` using the configured AI provider for `command`.
  std::string Transform(const std::string& command, const std::string& text);

 private:
  AiTransformer();
  ~AiTransformer() = default;

  std::string ResolvePromptForCommand(
      const std::string& command,
      std::unordered_map<std::string, std::string>& out_variables);

  static constexpr size_t kMaxChars = 4000;
};

}  // namespace atfix

#endif  // RUNNER_AI_TRANSFORMER_H_

