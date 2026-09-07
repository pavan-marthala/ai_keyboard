#include "open_at_login_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>
#include <string>
#include <vector>

namespace open_at_login {

// static
void OpenAtLoginPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "open_at_login",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<OpenAtLoginPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

OpenAtLoginPlugin::OpenAtLoginPlugin() {}

OpenAtLoginPlugin::~OpenAtLoginPlugin() {}

void OpenAtLoginPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("isOpenAtLoginEnabled") == 0) {
    const auto* arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    IsOpenAtLoginEnabled(arguments, std::move(result));
  } else if (method_call.method_name().compare("setOpenAtLoginEnabled") == 0) {
    const auto* arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    SetOpenAtLoginEnabled(arguments, std::move(result));
  } else {
    result->NotImplemented();
  }
}

std::wstring OpenAtLoginPlugin::QuoteArgument(const std::wstring& argument) {
  if (argument.empty()) {
    return L"\"\"";
  }

  // If no spaces, tabs, newlines, or quotes are present, quoting is not strictly needed.
  if (argument.find_first_of(L" \t\n\v\"") == std::wstring::npos) {
    return argument;
  }

  std::wstring quoted = L"\"";
  int backslash_count = 0;

  for (size_t i = 0; i < argument.length(); ++i) {
    wchar_t c = argument[i];
    if (c == L'\\') {
      ++backslash_count;
    } else if (c == L'"') {
      // Escape each backslash before a quote, plus one more to escape the quote itself
      quoted.append(2 * backslash_count + 1, L'\\');
      quoted.push_back(L'"');
      backslash_count = 0;
    } else {
      if (backslash_count > 0) {
        quoted.append(backslash_count, L'\\');
        backslash_count = 0;
      }
      quoted.push_back(c);
    }
  }

  // Trailing backslashes before the closing quote must be doubled
  if (backslash_count > 0) {
    quoted.append(2 * backslash_count, L'\\');
  }
  quoted.push_back(L'"');
  return quoted;
}

std::wstring OpenAtLoginPlugin::BuildCommandLine(
    const std::wstring& app_path,
    const std::vector<std::wstring>& args) {
  // Always wrap the executable path in quotes to follow Windows security best practices
  std::wstring quoted_path = QuoteArgument(app_path);
  if (quoted_path.empty() || quoted_path.front() != L'"') {
    quoted_path = L"\"" + quoted_path + L"\"";
  }

  std::wstring cmd = quoted_path;
  for (const auto& arg : args) {
    if (!arg.empty()) {
      cmd.push_back(L' ');
      cmd.append(QuoteArgument(arg));
    }
  }
  return cmd;
}

std::wstring OpenAtLoginPlugin::Utf8ToWide(const std::string& utf8_str) {
  if (utf8_str.empty()) {
    return std::wstring();
  }
  int size_needed = MultiByteToWideChar(
      CP_UTF8, 0, utf8_str.data(), static_cast<int>(utf8_str.size()), NULL, 0);
  if (size_needed <= 0) {
    return std::wstring();
  }
  std::wstring wide_str(size_needed, 0);
  MultiByteToWideChar(
      CP_UTF8, 0, utf8_str.data(), static_cast<int>(utf8_str.size()),
      &wide_str[0], size_needed);
  return wide_str;
}

std::string OpenAtLoginPlugin::WideToUtf8(const std::wstring& wide_str) {
  if (wide_str.empty()) {
    return std::string();
  }
  int size_needed = WideCharToMultiByte(
      CP_UTF8, 0, wide_str.data(), static_cast<int>(wide_str.size()), NULL, 0,
      NULL, NULL);
  if (size_needed <= 0) {
    return std::string();
  }
  std::string utf8_str(size_needed, 0);
  WideCharToMultiByte(
      CP_UTF8, 0, wide_str.data(), static_cast<int>(wide_str.size()),
      &utf8_str[0], size_needed, NULL, NULL);
  return utf8_str;
}

std::string OpenAtLoginPlugin::GetErrorMessage(DWORD error_code) {
  LPWSTR message_buffer = nullptr;
  size_t size = FormatMessageW(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS,
      NULL, error_code, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<LPWSTR>(&message_buffer), 0, NULL);
  if (size == 0 || !message_buffer) {
    return "Error code: " + std::to_string(error_code);
  }
  std::wstring message(message_buffer, size);
  LocalFree(message_buffer);
  while (!message.empty() &&
         (message.back() == L'\r' || message.back() == L'\n')) {
    message.pop_back();
  }
  return WideToUtf8(message);
}

void OpenAtLoginPlugin::IsOpenAtLoginEnabled(
    const flutter::EncodableMap* arguments,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!arguments) {
    result->Error("INVALID_ARGUMENTS", "Arguments map is null");
    return;
  }

  auto app_name_it = arguments->find(flutter::EncodableValue("appName"));
  if (app_name_it == arguments->end() ||
      !std::holds_alternative<std::string>(app_name_it->second)) {
    result->Error("INVALID_ARGUMENTS", "appName is required");
    return;
  }

  std::string app_name = std::get<std::string>(app_name_it->second);
  if (app_name.empty()) {
    result->Success(flutter::EncodableValue(false));
    return;
  }

  std::string app_path;
  auto app_path_it = arguments->find(flutter::EncodableValue("appPath"));
  if (app_path_it != arguments->end() &&
      std::holds_alternative<std::string>(app_path_it->second)) {
    app_path = std::get<std::string>(app_path_it->second);
  }

  HKEY hKey = nullptr;
  LSTATUS status = RegOpenKeyExW(
      HKEY_CURRENT_USER,
      L"Software\\Microsoft\\Windows\\CurrentVersion\\Run",
      0,
      KEY_READ,
      &hKey);

  if (status != ERROR_SUCCESS) {
    result->Success(flutter::EncodableValue(false));
    return;
  }

  std::wstring wide_app_name = Utf8ToWide(app_name);
  DWORD type = 0;
  DWORD data_size = 0;

  status = RegQueryValueExW(
      hKey,
      wide_app_name.c_str(),
      NULL,
      &type,
      NULL,
      &data_size);

  if (status != ERROR_SUCCESS) {
    RegCloseKey(hKey);
    result->Success(flutter::EncodableValue(false));
    return;
  }

  if (type != REG_SZ && type != REG_EXPAND_SZ) {
    RegCloseKey(hKey);
    result->Success(flutter::EncodableValue(false));
    return;
  }

  std::vector<wchar_t> buffer(data_size / sizeof(wchar_t) + 1, 0);
  status = RegQueryValueExW(
      hKey,
      wide_app_name.c_str(),
      NULL,
      &type,
      reinterpret_cast<LPBYTE>(buffer.data()),
      &data_size);

  RegCloseKey(hKey);

  if (status != ERROR_SUCCESS) {
    result->Success(flutter::EncodableValue(false));
    return;
  }

  std::wstring stored_val(buffer.data());
  if (stored_val.empty()) {
    result->Success(flutter::EncodableValue(false));
    return;
  }

  if (!app_path.empty()) {
    std::wstring wide_app_path = Utf8ToWide(app_path);
    if (!wide_app_path.empty() &&
        stored_val.find(wide_app_path) == std::wstring::npos) {
      result->Success(flutter::EncodableValue(false));
      return;
    }
  }

  result->Success(flutter::EncodableValue(true));
}

void OpenAtLoginPlugin::SetOpenAtLoginEnabled(
    const flutter::EncodableMap* arguments,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!arguments) {
    result->Error("INVALID_ARGUMENTS", "Arguments map is null");
    return;
  }

  auto enabled_it = arguments->find(flutter::EncodableValue("enabled"));
  if (enabled_it == arguments->end() ||
      !std::holds_alternative<bool>(enabled_it->second)) {
    result->Error("INVALID_ARGUMENTS", "enabled boolean is required");
    return;
  }
  bool enabled = std::get<bool>(enabled_it->second);

  auto app_name_it = arguments->find(flutter::EncodableValue("appName"));
  if (app_name_it == arguments->end() ||
      !std::holds_alternative<std::string>(app_name_it->second)) {
    result->Error("INVALID_ARGUMENTS", "appName is required");
    return;
  }
  std::string app_name = std::get<std::string>(app_name_it->second);
  if (app_name.empty()) {
    result->Error("INVALID_ARGUMENTS", "appName cannot be empty");
    return;
  }

  std::wstring wide_app_name = Utf8ToWide(app_name);

  if (enabled) {
    auto app_path_it = arguments->find(flutter::EncodableValue("appPath"));
    if (app_path_it == arguments->end() ||
        !std::holds_alternative<std::string>(app_path_it->second)) {
      result->Error("INVALID_ARGUMENTS", "appPath is required when enabled is true");
      return;
    }
    std::string app_path = std::get<std::string>(app_path_it->second);
    if (app_path.empty()) {
      result->Error(
          "INVALID_ARGUMENTS",
          "appPath cannot be empty when enabled is true");
      return;
    }

    std::vector<std::wstring> wide_args;
    auto args_it = arguments->find(flutter::EncodableValue("args"));
    if (args_it != arguments->end() &&
        std::holds_alternative<flutter::EncodableList>(args_it->second)) {
      const auto& args_list = std::get<flutter::EncodableList>(args_it->second);
      for (const auto& item : args_list) {
        if (std::holds_alternative<std::string>(item)) {
          wide_args.push_back(Utf8ToWide(std::get<std::string>(item)));
        }
      }
    }

    std::wstring command_line =
        BuildCommandLine(Utf8ToWide(app_path), wide_args);

    HKEY hKey = nullptr;
    LSTATUS status = RegCreateKeyExW(
        HKEY_CURRENT_USER,
        L"Software\\Microsoft\\Windows\\CurrentVersion\\Run",
        0,
        NULL,
        REG_OPTION_NON_VOLATILE,
        KEY_SET_VALUE,
        NULL,
        &hKey,
        NULL);

    if (status != ERROR_SUCCESS) {
      result->Error(
          "REGISTRY_ERROR",
          "Failed to open or create Run registry key: " +
              GetErrorMessage(status));
      return;
    }

    status = RegSetValueExW(
        hKey,
        wide_app_name.c_str(),
        0,
        REG_SZ,
        reinterpret_cast<const BYTE*>(command_line.c_str()),
        static_cast<DWORD>((command_line.length() + 1) * sizeof(wchar_t)));

    RegCloseKey(hKey);

    if (status != ERROR_SUCCESS) {
      result->Error(
          "REGISTRY_ERROR",
          "Failed to write to Run registry key: " +
              GetErrorMessage(status));
      return;
    }

    result->Success(flutter::EncodableValue(true));
  } else {
    HKEY hKey = nullptr;
    LSTATUS status = RegOpenKeyExW(
        HKEY_CURRENT_USER,
        L"Software\\Microsoft\\Windows\\CurrentVersion\\Run",
        0,
        KEY_SET_VALUE,
        &hKey);

    if (status != ERROR_SUCCESS) {
      if (status == ERROR_FILE_NOT_FOUND) {
        result->Success(flutter::EncodableValue(true));
        return;
      }
      result->Error(
          "REGISTRY_ERROR",
          "Failed to open Run registry key: " + GetErrorMessage(status));
      return;
    }

    status = RegDeleteValueW(hKey, wide_app_name.c_str());
    RegCloseKey(hKey);

    if (status != ERROR_SUCCESS && status != ERROR_FILE_NOT_FOUND) {
      result->Error(
          "REGISTRY_ERROR",
          "Failed to delete registry value: " + GetErrorMessage(status));
      return;
    }

    result->Success(flutter::EncodableValue(true));
  }
}

}  // namespace open_at_login

