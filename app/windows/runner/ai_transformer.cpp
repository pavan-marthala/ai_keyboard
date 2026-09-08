#include "ai_transformer.h"

#include <algorithm>
#include "configuration_store.h"
#include "credential_store.h"
#include "prompt_repository.h"
#include "open_ai_compatible_provider.h"

namespace atfix {

namespace {

std::string ToLower(const std::string& str) {
  std::string result = str;
  std::transform(result.begin(), result.end(), result.begin(),
                 [](unsigned char c) { return static_cast<char>(::tolower(c)); });
  size_t start = result.find_first_not_of(" \t\r\n");
  size_t end = result.find_last_not_of(" \t\r\n");
  if (start != std::string::npos && end != std::string::npos) {
    return result.substr(start, end - start + 1);
  }
  return result;
}

}  // namespace

AiTransformer& AiTransformer::GetInstance() {
  static AiTransformer instance;
  return instance;
}

AiTransformer::AiTransformer() {}

std::string AiTransformer::ResolvePromptForCommand(
    const std::string& command,
    std::unordered_map<std::string, std::string>& out_variables) {
  std::string normalized = ToLower(command);

  // Strictly reject deprecated @pro
  if (normalized == "@pro" || normalized == "pro") {
    throw AiFailure::Validation("@pro is deprecated and not supported");
  }

  std::string base_trigger = normalized;
  size_t colon_pos = normalized.find(':');
  if (colon_pos != std::string::npos) {
    base_trigger = normalized.substr(0, colon_pos);
    std::string arg = normalized.substr(colon_pos + 1);
    std::string lang_name = PromptRepository::GetInstance().GetLanguageName(arg);
    out_variables["language"] = lang_name;
  }

  const auto* def = PromptRepository::GetInstance().FindCommand(base_trigger);
  if (def) {
    if (def->requires_input && def->input_type == "language" &&
        out_variables.find("language") == out_variables.end()) {
      out_variables["language"] = "English";
    }
    return PromptRepository::GetInstance().GetPrompt(def->id, out_variables);
  }

  // Fallback for generic key
  std::string key = (normalized.rfind("@", 0) == 0) ? normalized.substr(1) : normalized;
  return PromptRepository::GetInstance().GetPrompt(key, out_variables);
}


std::string AiTransformer::Transform(const std::string& command, const std::string& text) {
  std::string trimmed = text;
  size_t start = trimmed.find_first_not_of(" \t\r\n");
  size_t end = trimmed.find_last_not_of(" \t\r\n");
  if (start != std::string::npos && end != std::string::npos) {
    trimmed = trimmed.substr(start, end - start + 1);
  }
  if (trimmed.empty()) return text;

  if (text.length() > kMaxChars) {
    throw AiFailure::TextTooLong();
  }

  // 1. Verify command is enabled in settings
  if (!ConfigurationStore::GetInstance().IsCommandEnabled(command)) {
    throw AiFailure::DisabledCommand(command);
  }

  // 2. Read active configuration
  AiConfiguration config = ConfigurationStore::GetInstance().GetConfig();

  // 3. Read API key from CredentialStore
  std::string api_key = CredentialStore::GetInstance().ReadApiKey(config.provider);

  // 4. Resolve prompt
  std::unordered_map<std::string, std::string> variables;
  std::string prompt = ResolvePromptForCommand(command, variables);

  // 5. Create provider and execute
  std::unique_ptr<AiProvider> provider;
  std::string p_type = ToLower(config.provider);

  if (p_type == "openrouter") {
    provider = std::make_unique<OpenAiCompatibleProvider>(
        "openrouter",
        "https://openrouter.ai/api/v1/chat/completions",
        "openai/gpt-4o-mini");
  } else if (p_type == "groq") {
    provider = std::make_unique<OpenAiCompatibleProvider>(
        "groq",
        "https://api.groq.com/openai/v1/chat/completions",
        "llama-3.3-70b-versatile");
  } else {
    provider = std::make_unique<OpenAiCompatibleProvider>(
        "openai",
        "https://api.openai.com/v1/chat/completions",
        "gpt-4o-mini");
  }

  return provider->Transform(text, prompt, config.model_id, api_key, config.base_url);
}

}  // namespace atfix

