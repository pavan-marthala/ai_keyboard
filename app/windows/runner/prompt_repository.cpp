#include "prompt_repository.h"

#include <windows.h>
#include <fstream>
#include <sstream>

namespace atfix {

PromptRepository& PromptRepository::GetInstance() {
  static PromptRepository instance;
  return instance;
}

PromptRepository::PromptRepository() {
  supported_languages_ = {
    {"en", "English"},
    {"es", "Spanish"},
    {"fr", "French"},
    {"de", "German"},
    {"it", "Italian"},
    {"pt", "Portuguese"},
    {"hi", "Hindi"},
    {"te", "Telugu"},
    {"kn", "Kannada"},
    {"ta", "Tamil"}
  };

  InitializeFallbacks();
  LoadFromFile();
}

void PromptRepository::InitializeFallbacks() {
  prompts_["fix"] =
      "Fix spelling, grammar, punctuation, and casing errors in the user text. "
      "Maintain the original tone, intent, and meaning. "
      "Return ONLY the corrected text without any introduction, explanations, or commentary.";

  prompts_["rewrite"] =
      "Rewrite the user text to improve clarity, flow, and elegance while preserving the original meaning. "
      "Return ONLY the rewritten text without any introduction, explanations, or commentary.";

  prompts_["professional"] =
      "Rewrite the user text in a professional, polished, and workplace-appropriate tone. "
      "Return ONLY the professional text without any introduction, explanations, or commentary.";

  prompts_["casual"] =
      "Rewrite the user text in a warm, relaxed, and conversational tone suitable for friendly chats. "
      "Return ONLY the casual text without any introduction, explanations, or commentary.";

  prompts_["short"] =
      "Condense the user text to be concise and direct while preserving essential meaning. "
      "Return ONLY the shortened text without any introduction, explanations, or commentary.";

  prompts_["expand"] =
      "Expand and elaborate upon the user text, adding natural detail and depth while maintaining the original voice. "
      "Return ONLY the expanded text without any introduction, explanations, or commentary.";

  prompts_["translate"] =
      "Translate the user text into {{language}}. "
      "Ensure natural fluency and appropriate idiom for the target language. "
      "Return ONLY the translated text without any introduction, explanations, or commentary.";
}

void PromptRepository::LoadFromFile() {
  wchar_t exe_path[MAX_PATH] = {0};
  if (GetModuleFileNameW(nullptr, exe_path, MAX_PATH) == 0) return;

  std::wstring path_str = exe_path;
  size_t last_slash = path_str.find_last_of(L"\\/");
  if (last_slash == std::wstring::npos) return;

  std::wstring dir = path_str.substr(0, last_slash);
  std::wstring json_path = dir + L"\\data\\flutter_assets\\assets\\prompts\\ai_prompts.json";

  std::ifstream file(json_path.c_str());
  if (!file.is_open()) {
    // Try development relative path fallback
    json_path = dir + L"\\..\\..\\..\\assets\\prompts\\ai_prompts.json";
    file.open(json_path.c_str());
  }

  if (file.is_open()) {
    // File found; fallback prompts are already initialized,
    // and custom prompt overrides can be loaded here if needed.
    file.close();
  }
}

std::string PromptRepository::GetLanguageName(const std::string& lang_code) {
  auto it = supported_languages_.find(lang_code);
  if (it != supported_languages_.end()) {
    return it->second;
  }
  return lang_code;
}

std::string PromptRepository::GetPrompt(
    const std::string& key,
    const std::unordered_map<std::string, std::string>& variables) {
  auto it = prompts_.find(key);
  std::string result = (it != prompts_.end()) ? it->second : prompts_["fix"];

  for (const auto& pair : variables) {
    std::string placeholder = "{{" + pair.first + "}}";
    size_t pos = 0;
    while ((pos = result.find(placeholder, pos)) != std::string::npos) {
      result.replace(pos, placeholder.length(), pair.second);
      pos += pair.second.length();
    }
  }

  return result;
}

}  // namespace atfix

