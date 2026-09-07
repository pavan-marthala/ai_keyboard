#include "configuration_store.h"

#include <windows.h>
#include <algorithm>
#include <sstream>

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

std::wstring Utf8ToWide(const std::string& str) {
  if (str.empty()) return L"";
  int size = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, nullptr, 0);
  if (size <= 0) return L"";
  std::wstring wide(size - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, &wide[0], size);
  return wide;
}

std::string WideToUtf8(const std::wstring& wstr) {
  if (wstr.empty()) return "";
  int size = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, nullptr, 0, nullptr, nullptr);
  if (size <= 0) return "";
  std::string str(size - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, &str[0], size, nullptr, nullptr);
  return str;
}

}  // namespace

ConfigurationStore& ConfigurationStore::GetInstance() {
  static ConfigurationStore instance;
  return instance;
}

void ConfigurationStore::SaveConfig(
    const std::string& provider,
    const std::string& model_id,
    const std::string& base_url) {
  std::string p = ToLower(provider);
  std::string m = model_id.empty() ? "gpt-4o-mini" : model_id;
  std::string b = base_url;

  HKEY hKey = nullptr;
  if (RegCreateKeyExW(
          HKEY_CURRENT_USER, kRegistrySubKey, 0, nullptr,
          REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    std::wstring wp = Utf8ToWide(p);
    std::wstring wm = Utf8ToWide(m);
    std::wstring wb = Utf8ToWide(b);

    RegSetValueExW(hKey, L"active_provider", 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(wp.c_str()),
                   static_cast<DWORD>((wp.size() + 1) * sizeof(wchar_t)));
    RegSetValueExW(hKey, L"active_model", 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(wm.c_str()),
                   static_cast<DWORD>((wm.size() + 1) * sizeof(wchar_t)));
    if (!b.empty()) {
      RegSetValueExW(hKey, L"custom_base_url", 0, REG_SZ,
                     reinterpret_cast<const BYTE*>(wb.c_str()),
                     static_cast<DWORD>((wb.size() + 1) * sizeof(wchar_t)));
    } else {
      RegDeleteValueW(hKey, L"custom_base_url");
    }
    RegCloseKey(hKey);
  }
}

AiConfiguration ConfigurationStore::GetConfig() {
  AiConfiguration config;
  config.provider = "openai";
  config.model_id = "gpt-4o-mini";
  config.base_url = "";

  wchar_t buffer[1024] = {0};
  DWORD size = sizeof(buffer);

  if (RegGetValueW(HKEY_CURRENT_USER, kRegistrySubKey, L"active_provider",
                   RRF_RT_REG_SZ, nullptr, buffer, &size) == ERROR_SUCCESS) {
    config.provider = WideToUtf8(buffer);
  }

  size = sizeof(buffer);
  if (RegGetValueW(HKEY_CURRENT_USER, kRegistrySubKey, L"active_model",
                   RRF_RT_REG_SZ, nullptr, buffer, &size) == ERROR_SUCCESS) {
    config.model_id = WideToUtf8(buffer);
  }

  size = sizeof(buffer);
  if (RegGetValueW(HKEY_CURRENT_USER, kRegistrySubKey, L"custom_base_url",
                   RRF_RT_REG_SZ, nullptr, buffer, &size) == ERROR_SUCCESS) {
    config.base_url = WideToUtf8(buffer);
  }

  return config;
}

void ConfigurationStore::SaveDisabledCommands(
    const std::vector<std::string>& disabled_commands) {
  std::ostringstream oss;
  for (size_t i = 0; i < disabled_commands.size(); ++i) {
    if (i > 0) oss << ";";
    oss << ToLower(disabled_commands[i]);
  }

  HKEY hKey = nullptr;
  if (RegCreateKeyExW(
          HKEY_CURRENT_USER, kRegistrySubKey, 0, nullptr,
          REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    std::wstring val = Utf8ToWide(oss.str());
    RegSetValueExW(hKey, L"disabled_commands", 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(val.c_str()),
                   static_cast<DWORD>((val.size() + 1) * sizeof(wchar_t)));
    RegCloseKey(hKey);
  }
}

std::unordered_set<std::string> ConfigurationStore::GetDisabledCommands() {
  std::unordered_set<std::string> disabled_set;
  wchar_t buffer[2048] = {0};
  DWORD size = sizeof(buffer);

  if (RegGetValueW(HKEY_CURRENT_USER, kRegistrySubKey, L"disabled_commands",
                   RRF_RT_REG_SZ, nullptr, buffer, &size) == ERROR_SUCCESS) {
    std::string val = WideToUtf8(buffer);
    std::stringstream ss(val);
    std::string item;
    while (std::getline(ss, item, ';')) {
      if (!item.empty()) {
        disabled_set.insert(ToLower(item));
      }
    }
  }

  return disabled_set;
}

bool ConfigurationStore::IsCommandEnabled(const std::string& trigger) {
  std::string t = ToLower(trigger);
  auto disabled = GetDisabledCommands();
  return disabled.find(t) == disabled.end();
}

}  // namespace atfix

