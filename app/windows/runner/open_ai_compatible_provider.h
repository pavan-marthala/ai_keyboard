#ifndef RUNNER_OPEN_AI_COMPATIBLE_PROVIDER_H_
#define RUNNER_OPEN_AI_COMPATIBLE_PROVIDER_H_

#include "ai_provider.h"

namespace atfix {

/// Native C++ OpenAI-compatible Chat Completions Provider using WinHTTP.
/// Supports OpenAI, OpenRouter, and Groq REST APIs, with deterministic mock fallback
/// when testing without an API key. Strictly mirrors OpenAiCompatibleProvider.swift.
class OpenAiCompatibleProvider : public AiProvider {
 public:
  OpenAiCompatibleProvider(
      const std::string& provider_type = "openai",
      const std::string& default_endpoint = "https://api.openai.com/v1/chat/completions",
      const std::string& default_model = "gpt-4o-mini");

  ~OpenAiCompatibleProvider() override = default;

  std::string GetProviderType() const override { return provider_type_; }

  std::string Transform(
      const std::string& text,
      const std::string& prompt,
      const std::string& model,
      const std::string& api_key,
      const std::string& base_url) override;

 private:
  std::string ExecuteHttpRequest(
      const std::string& endpoint,
      const std::string& model,
      const std::string& prompt,
      const std::string& text,
      const std::string& api_key);

  std::string ExecuteMockTransform(
      const std::string& text,
      const std::string& prompt);

  std::string provider_type_;
  std::string default_endpoint_;
  std::string default_model_;
};

}  // namespace atfix

#endif  // RUNNER_OPEN_AI_COMPATIBLE_PROVIDER_H_

