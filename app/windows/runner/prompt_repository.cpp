#include "prompt_repository.h"

#include <windows.h>
#include <algorithm>
#include <cctype>
#include <fstream>
#include <sstream>

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

// Lightweight JSON DOM representation
enum class JsonType { kNull, kBool, kNumber, kString, kArray, kObject };

struct JsonVal {
  JsonType type = JsonType::kNull;
  bool bool_val = false;
  double num_val = 0;
  std::string str_val;
  std::vector<JsonVal> arr_val;
  std::unordered_map<std::string, JsonVal> obj_val;

  bool IsObject() const { return type == JsonType::kObject; }
  bool IsString() const { return type == JsonType::kString; }
  bool IsNumber() const { return type == JsonType::kNumber; }
  bool IsBool() const { return type == JsonType::kBool; }

  const JsonVal* Get(const std::string& k) const {
    if (type != JsonType::kObject) return nullptr;
    auto it = obj_val.find(k);
    return (it != obj_val.end()) ? &it->second : nullptr;
  }

  std::string GetString(const std::string& k, const std::string& def = "") const {
    const auto* v = Get(k);
    return (v && v->IsString()) ? v->str_val : def;
  }

  int GetInt(const std::string& k, int def = 0) const {
    const auto* v = Get(k);
    return (v && v->IsNumber()) ? static_cast<int>(v->num_val) : def;
  }

  bool GetBool(const std::string& k, bool def = false) const {
    const auto* v = Get(k);
    return (v && v->IsBool()) ? v->bool_val : def;
  }
};

class MiniJsonParser {
 public:
  explicit MiniJsonParser(const std::string& src) : src_(src), pos_(0) {}

  bool Parse(JsonVal* out_val) {
    SkipWhitespace();
    if (pos_ >= src_.size()) return false;
    return ParseValue(out_val);
  }

 private:
  void SkipWhitespace() {
    while (pos_ < src_.size() && (src_[pos_] == ' ' || src_[pos_] == '\t' ||
                                  src_[pos_] == '\r' || src_[pos_] == '\n')) {
      pos_++;
    }
  }

  bool ParseValue(JsonVal* val) {
    SkipWhitespace();
    if (pos_ >= src_.size()) return false;
    char c = src_[pos_];
    if (c == '{') return ParseObject(val);
    if (c == '[') return ParseArray(val);
    if (c == '"') return ParseString(&val->str_val) && ((val->type = JsonType::kString), true);
    if (c == 't' || c == 'f') return ParseBool(val);
    if (c == 'n') return ParseNull(val);
    if (c == '-' || (c >= '0' && c <= '9')) return ParseNumber(val);
    return false;
  }

  bool ParseObject(JsonVal* val) {
    pos_++; // skip '{'
    val->type = JsonType::kObject;
    val->obj_val.clear();
    SkipWhitespace();
    if (pos_ < src_.size() && src_[pos_] == '}') {
      pos_++;
      return true;
    }

    while (pos_ < src_.size()) {
      SkipWhitespace();
      if (pos_ >= src_.size() || src_[pos_] != '"') return false;
      std::string key;
      if (!ParseString(&key)) return false;

      SkipWhitespace();
      if (pos_ >= src_.size() || src_[pos_] != ':') return false;
      pos_++; // skip ':'

      JsonVal child;
      if (!ParseValue(&child)) return false;
      val->obj_val[key] = child;

      SkipWhitespace();
      if (pos_ < src_.size() && src_[pos_] == '}') {
        pos_++;
        return true;
      }
      if (pos_ < src_.size() && src_[pos_] == ',') {
        pos_++;
      } else {
        return false;
      }
    }
    return false;
  }

  bool ParseArray(JsonVal* val) {
    pos_++; // skip '['
    val->type = JsonType::kArray;
    val->arr_val.clear();
    SkipWhitespace();
    if (pos_ < src_.size() && src_[pos_] == ']') {
      pos_++;
      return true;
    }

    while (pos_ < src_.size()) {
      JsonVal item;
      if (!ParseValue(&item)) return false;
      val->arr_val.push_back(item);

      SkipWhitespace();
      if (pos_ < src_.size() && src_[pos_] == ']') {
        pos_++;
        return true;
      }
      if (pos_ < src_.size() && src_[pos_] == ',') {
        pos_++;
      } else {
        return false;
      }
    }
    return false;
  }

  bool ParseString(std::string* str) {
    pos_++; // skip opening '"'
    str->clear();
    while (pos_ < src_.size()) {
      char c = src_[pos_++];
      if (c == '"') return true;
      if (c == '\\') {
        if (pos_ >= src_.size()) return false;
        char esc = src_[pos_++];
        switch (esc) {
          case '"': *str += '"'; break;
          case '\\': *str += '\\'; break;
          case '/': *str += '/'; break;
          case 'b': *str += '\b'; break;
          case 'f': *str += '\f'; break;
          case 'n': *str += '\n'; break;
          case 'r': *str += '\r'; break;
          case 't': *str += '\t'; break;
          case 'u': {
            if (pos_ + 4 > src_.size()) return false;
            // Simple hex decode
            std::string hex = src_.substr(pos_, 4);
            pos_ += 4;
            unsigned int cp = 0;
            std::stringstream ss;
            ss << std::hex << hex;
            ss >> cp;
            if (cp < 0x80) {
              *str += static_cast<char>(cp);
            } else if (cp < 0x800) {
              *str += static_cast<char>(0xC0 | (cp >> 6));
              *str += static_cast<char>(0x80 | (cp & 0x3F));
            } else {
              *str += static_cast<char>(0xE0 | (cp >> 12));
              *str += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
              *str += static_cast<char>(0x80 | (cp & 0x3F));
            }
            break;
          }
          default: *str += esc; break;
        }
      } else {
        *str += c;
      }
    }
    return false;
  }

  bool ParseBool(JsonVal* val) {
    if (src_.substr(pos_, 4) == "true") {
      val->type = JsonType::kBool;
      val->bool_val = true;
      pos_ += 4;
      return true;
    }
    if (src_.substr(pos_, 5) == "false") {
      val->type = JsonType::kBool;
      val->bool_val = false;
      pos_ += 5;
      return true;
    }
    return false;
  }

  bool ParseNull(JsonVal* val) {
    if (src_.substr(pos_, 4) == "null") {
      val->type = JsonType::kNull;
      pos_ += 4;
      return true;
    }
    return false;
  }

  bool ParseNumber(JsonVal* val) {
    size_t start = pos_;
    if (src_[pos_] == '-') pos_++;
    while (pos_ < src_.size() && ((src_[pos_] >= '0' && src_[pos_] <= '9') || src_[pos_] == '.' ||
                                  src_[pos_] == 'e' || src_[pos_] == 'E' ||
                                  src_[pos_] == '+' || src_[pos_] == '-')) {
      pos_++;
    }
    std::string num_str = src_.substr(start, pos_ - start);
    val->type = JsonType::kNumber;
    val->num_val = std::stod(num_str);
    return true;
  }

  const std::string& src_;
  size_t pos_;
};

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

  InitializeFallbacks();
  LoadFromFile();
}

void PromptRepository::InitializeFallbacks() {
  commands_ = {
    {"fix", "@fix", "Fix", "Fixing...", 10, false, "",
     "Fix spelling, grammar, punctuation, and casing errors in the user text. Maintain the original tone, intent, and meaning. Return ONLY the corrected text without any introduction, explanations, or commentary."},
    {"rewrite", "@rewrite", "Rewrite", "Rewriting...", 20, false, "",
     "Rewrite the user text to improve clarity, flow, and elegance while preserving the original meaning. Return ONLY the rewritten text without any introduction, explanations, or commentary."},
    {"professional", "@professional", "Professional", "Making professional...", 30, false, "",
     "Rewrite the user text in a professional, polished, and workplace-appropriate tone. Return ONLY the professional text without any introduction, explanations, or commentary."},
    {"casual", "@casual", "Casual", "Making casual...", 40, false, "",
     "Rewrite the user text in a warm, relaxed, and conversational tone suitable for friendly chats. Return ONLY the casual text without any introduction, explanations, or commentary."},
    {"short", "@short", "Short", "Shortening...", 50, false, "",
     "Condense the user text to be concise and direct while preserving essential meaning. Return ONLY the shortened text without any introduction, explanations, or commentary."},
    {"expand", "@expand", "Expand", "Expanding...", 60, false, "",
     "Expand and elaborate upon the user text, adding natural detail and depth while maintaining the original voice. Return ONLY the expanded text without any introduction, explanations, or commentary."},
    {"translate", "@translate", "Translate", "Translating...", 70, true, "language",
     "Translate the user text into {{language}}. Ensure natural fluency and appropriate idiom for the target language. Return ONLY the translated text without any introduction, explanations, or commentary."}
  };

  command_by_id_.clear();
  command_by_trigger_.clear();
  prompts_.clear();

  for (size_t i = 0; i < commands_.size(); ++i) {
    command_by_id_[commands_[i].id] = i;
    command_by_trigger_[commands_[i].command] = i;
    prompts_[commands_[i].id] = commands_[i].system;
  }
}

bool PromptRepository::ParseJson(const std::string& json_str) {
  MiniJsonParser parser(json_str);
  JsonVal root;
  if (!parser.Parse(&root) || !root.IsObject()) {
    return false;
  }

  const JsonVal* commands_obj = root.Get("commands");
  if (commands_obj && commands_obj->IsObject()) {
    std::vector<CommandDefinition> parsed_commands;
    std::unordered_map<std::string, size_t> parsed_by_id;
    std::unordered_map<std::string, size_t> parsed_by_trigger;
    std::unordered_map<std::string, std::string> parsed_prompts;

    for (const auto& pair : commands_obj->obj_val) {
      std::string id = ToLowerAndTrim(pair.first);
      if (id.empty() || id == "pro" || id == "@pro") {
        continue; // Strictly reject deprecated @pro
      }

      const JsonVal& cmd_val = pair.second;
      if (!cmd_val.IsObject()) continue;

      std::string cmd = cmd_val.GetString("command");
      std::string label = cmd_val.GetString("label");
      std::string action_label = cmd_val.GetString("actionLabel");
      int order = cmd_val.GetInt("order", 0);
      bool requires_input = cmd_val.GetBool("requiresInput", false);
      std::string input_type = cmd_val.GetString("inputType");
      std::string system = cmd_val.GetString("system");

      // Validate constraints
      if (cmd.rfind("@", 0) != 0 || cmd == "@pro") continue;
      if (label.empty() || action_label.empty() || order <= 0 || system.empty()) continue;
      if (requires_input && input_type.empty()) continue;

      CommandDefinition def;
      def.id = id;
      def.command = cmd;
      def.label = label;
      def.action_label = action_label;
      def.order = order;
      def.requires_input = requires_input;
      def.input_type = input_type;
      def.system = system;

      parsed_commands.push_back(def);
    }

    // Ensure canonical command @professional is present
    bool has_professional = false;
    for (const auto& def : parsed_commands) {
      if (def.id == "professional" && def.command == "@professional") {
        has_professional = true;
        break;
      }
    }
    if (!has_professional) {
      return false;
    }

    // Sort by order ascending
    std::sort(parsed_commands.begin(), parsed_commands.end(),
              [](const CommandDefinition& a, const CommandDefinition& b) {
                return a.order < b.order;
              });

    commands_ = parsed_commands;
    command_by_id_.clear();
    command_by_trigger_.clear();
    prompts_.clear();

    for (size_t i = 0; i < commands_.size(); ++i) {
      command_by_id_[commands_[i].id] = i;
      command_by_trigger_[ToLowerAndTrim(commands_[i].command)] = i;
      prompts_[commands_[i].id] = commands_[i].system;
    }

    return true;
  }

  // Schema v1 fallback
  const JsonVal* prompts_obj = root.Get("prompts");
  if (prompts_obj && prompts_obj->IsObject()) {
    for (const auto& pair : prompts_obj->obj_val) {
      if (pair.second.IsObject()) {
        std::string sys = pair.second.GetString("system");
        if (!sys.empty()) {
          prompts_[pair.first] = sys;
        }
      }
    }
    return true;
  }

  return false;
}

void PromptRepository::LoadFromFile() {
  wchar_t exe_path[MAX_PATH] = {0};
  if (GetModuleFileNameW(nullptr, exe_path, MAX_PATH) == 0) return;

  std::wstring path_str = exe_path;
  size_t last_slash = path_str.find_last_of(L"\\/");
  if (last_slash == std::wstring::npos) return;

  std::wstring dir = path_str.substr(0, last_slash);
  std::vector<std::wstring> candidate_paths = {
    dir + L"\\data\\flutter_assets\\assets\\prompts\\ai_prompts.json",
    dir + L"\\..\\..\\..\\assets\\prompts\\ai_prompts.json",
    dir + L"\\..\\..\\..\\..\\shared\\prompts\\ai_prompts.json"
  };

  for (const auto& json_path : candidate_paths) {
    std::ifstream file(json_path.c_str());
    if (file.is_open()) {
      std::stringstream buffer;
      buffer << file.rdbuf();
      std::string content = buffer.str();
      file.close();
      if (!content.empty() && ParseJson(content)) {
        break;
      }
    }
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
