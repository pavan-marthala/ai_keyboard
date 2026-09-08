#include "prompt_repository.h"
 
#include <algorithm>
#include <cctype>

namespace atfix {

namespace {

std::string ToLowerAndTrim(const std::string& str) {
  std::string result = str;
  std::transform(result.begin(), result.end(), result.begin(),
                 [](unsigned char c) { return static_cast<char>(::tolower(c)); });
  size_t start = result.find_first_not_of(" \t\r\n");
  size_t end = result.find_last_not_of(" \t\r\n");
  if (start != std::string::npos && end != std::string::npos) {
    return result.substr(start, end - start + 1);
  }
  return "";
}

}  // namespace

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

  const auto& generated_commands = atfix::generated::GetCommands();
  commands_ = generated_commands;

  std::sort(commands_.begin(), commands_.end(),
            [](const CommandDefinition& a, const CommandDefinition& b) {
              return a.order < b.order;
            });

  command_by_id_.clear();
  command_by_trigger_.clear();
  prompts_.clear();

  for (size_t i = 0; i < commands_.size(); ++i) {
    command_by_id_[ToLowerAndTrim(commands_[i].id)] = i;
    command_by_trigger_[ToLowerAndTrim(commands_[i].command)] = i;
    prompts_[ToLowerAndTrim(commands_[i].id)] = commands_[i].system;
  }
}

const std::vector<CommandDefinition>& PromptRepository::GetCommands() const {
  return commands_;
}

const CommandDefinition* PromptRepository::FindCommand(const std::string& trigger_or_id) const {
  std::string clean = ToLowerAndTrim(trigger_or_id);
  size_t colon_pos = clean.find(':');
  std::string base = (colon_pos != std::string::npos) ? clean.substr(0, colon_pos) : clean;

  if (base == "@pro" || base == "pro") {
    return nullptr;
  }

  auto it_trig = command_by_trigger_.find(base);
  if (it_trig != command_by_trigger_.end()) {
    return &commands_[it_trig->second];
  }

  auto it_id = command_by_id_.find(base);
  if (it_id != command_by_id_.end()) {
    return &commands_[it_id->second];
  }

  return nullptr;
}

std::string PromptRepository::GetActionLabel(const std::string& trigger_or_id) const {
  const auto* def = FindCommand(trigger_or_id);
  if (def) {
    return def->action_label;
  }
  return "Transforming with " + trigger_or_id + "...";
}

std::string PromptRepository::GetLanguageName(const std::string& lang_code) {
  std::string clean = ToLowerAndTrim(lang_code);
  auto it = supported_languages_.find(clean);
  if (it != supported_languages_.end()) {
    return it->second;
  }
  return lang_code;
}

std::string PromptRepository::GetPrompt(
    const std::string& key,
    const std::unordered_map<std::string, std::string>& variables) {
  std::string clean = ToLowerAndTrim(key);
  size_t colon_pos = clean.find(':');
  std::string base = (colon_pos != std::string::npos) ? clean.substr(0, colon_pos) : clean;

  if (base == "@pro" || base == "pro") {
    return "";
  }

  std::string template_str;
  auto it = prompts_.find(base);
  if (it != prompts_.end()) {
    template_str = it->second;
  } else {
    const auto* def = FindCommand(base);
    if (def) {
      template_str = def->system;
    } else {
      auto def_it = prompts_.find("fix");
      template_str = (def_it != prompts_.end()) ? def_it->second : "";
    }
  }

  std::string result = template_str;
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

bool PromptRepository::HasPrompt(const std::string& key) const {
  std::string clean = ToLowerAndTrim(key);
  size_t colon_pos = clean.find(':');
  std::string base = (colon_pos != std::string::npos) ? clean.substr(0, colon_pos) : clean;

  if (base == "@pro" || base == "pro") {
    return false;
  }

  return prompts_.find(base) != prompts_.end() || FindCommand(base) != nullptr;
}

}  // namespace atfix

