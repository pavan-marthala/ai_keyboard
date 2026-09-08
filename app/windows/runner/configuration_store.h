#ifndef RUNNER_CONFIGURATION_STORE_H_
#define RUNNER_CONFIGURATION_STORE_H_

#include <string>
#include <vector>
#include <unordered_set>

namespace atfix {

struct AiConfiguration {
  std::string provider = "openai";
  std::string model_id = "gpt-4o-mini";
  std::string base_url = "";
};

/// Native configuration storage for Windows AI commands using Windows Registry (HKCU\Software\AtFix).
/// Strictly mirrors macOS ConfigurationStore.swift.
class ConfigurationStore {
 public:
  static ConfigurationStore& GetInstance();

  ConfigurationStore(const ConfigurationStore&) = delete;
  ConfigurationStore& operator=(const ConfigurationStore&) = delete;

  /// Saves active provider, model, and optional custom base URL configuration.
  void SaveConfig(const std::string& provider, const std::string& model_id, const std::string& base_url = "");

  /// Retrieves the current AI configuration from Windows Registry (defaults to openai / gpt-4o-mini).
  AiConfiguration GetConfig();

  /// Persists the list of disabled command triggers.
  void SaveDisabledCommands(const std::vector<std::string>& disabled_commands);

  /// Returns the set of disabled command triggers.
  std::unordered_set<std::string> GetDisabledCommands();

  /// Checks whether a command trigger is currently enabled.
  bool IsCommandEnabled(const std::string& trigger);

  /// Saves global shortcut key and modifiers.
  void SaveShortcut(const std::string& key, const std::vector<std::string>& modifiers);

  /// Retrieves global shortcut key and modifiers. Returns true if present.
  bool GetShortcut(std::string* key, std::vector<std::string>* modifiers);

 private:
  ConfigurationStore() = default;
  ~ConfigurationStore() = default;

  const wchar_t* kRegistrySubKey = L"Software\\AtFix";
};

}  // namespace atfix

#endif  // RUNNER_CONFIGURATION_STORE_H_

