#include "command_shortcut_manager.h"
#include "windows_accessibility_service.h"
#include "windows_text_replacement_service.h"
#include "configuration_store.h"

#include <iostream>
#include <algorithm>

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

CommandShortcutManager& CommandShortcutManager::GetInstance() {
  static CommandShortcutManager instance;
  return instance;
}

CommandShortcutManager::CommandShortcutManager() {
  prompt_window_.SetDelegate(this);
}

CommandShortcutManager::~CommandShortcutManager() {
  Stop();
}

UINT CommandShortcutManager::KeyNameToVk(const std::string& key_name) {
  std::string k = ToLower(key_name);
  if (k == "space") return VK_SPACE;
  if (k == "return" || k == "enter") return VK_RETURN;
  if (k == "tab") return VK_TAB;
  if (k == "backspace") return VK_BACK;
  if (k == "escape") return VK_ESCAPE;

  if (k.length() == 1) {
    char c = k[0];
    if (c >= 'a' && c <= 'z') {
      return static_cast<UINT>(c - 'a' + 'A');
    }
    if (c >= '0' && c <= '9') {
      return static_cast<UINT>(c);
    }
  }

  // Function keys F1 to F12
  if (k.length() >= 2 && k[0] == 'f') {
    int num = std::atoi(k.c_str() + 1);
    if (num >= 1 && num <= 12) {
      return VK_F1 + (num - 1);
    }
  }

  return 0;
}

UINT CommandShortcutManager::ModifiersToFlags(const std::vector<std::string>& modifiers) {
  UINT flags = 0;
  for (const auto& mod : modifiers) {
    std::string m = ToLower(mod);
    if (m == "control" || m == "ctrl") {
      flags |= MOD_CONTROL;
    } else if (m == "alt" || m == "option") {
      flags |= MOD_ALT;
    } else if (m == "shift") {
      flags |= MOD_SHIFT;
    } else if (m == "windows" || m == "win" || m == "meta" || m == "command" || m == "cmd") {
      flags |= MOD_WIN;
    }
  }
  return flags;
}

bool CommandShortcutManager::RegisterShortcut(
    const std::string& key,
    const std::vector<std::string>& modifiers,
    bool persist) {
  std::string clean_key = ToLower(key);
  UINT vk = KeyNameToVk(clean_key);
  if (vk == 0) {
    std::wcerr << L"[CommandShortcutManager] Unsupported key name: " << clean_key.c_str() << std::endl;
    return false;
  }

  std::vector<std::string> clean_mods;
  for (const auto& m : modifiers) {
    std::string cm = ToLower(m);
    if (!cm.empty()) clean_mods.push_back(cm);
  }
  if (clean_mods.empty()) {
    std::wcerr << L"[CommandShortcutManager] Modifiers cannot be empty" << std::endl;
    return false;
  }

  UINT mod_flags = ModifiersToFlags(clean_mods);
  if (mod_flags == 0) {
    return false;
  }

  if (!message_hwnd_) {
    current_key_ = clean_key;
    current_modifiers_ = clean_mods;
    current_vk_ = vk;
    current_mod_flags_ = mod_flags;
    if (persist) {
      atfix::ConfigurationStore::GetInstance().SaveShortcut(clean_key, clean_mods);
    }
    return true;
  }

  int candidate_id = (active_hotkey_id_ == kAtFixHotKeyId) ? kCandidateHotKeyId : kAtFixHotKeyId;
  BOOL success = ::RegisterHotKey(message_hwnd_, candidate_id, mod_flags | MOD_NOREPEAT, vk);
  if (!success) {
    success = ::RegisterHotKey(message_hwnd_, candidate_id, mod_flags, vk);
  }

  if (!success) {
    DWORD err = ::GetLastError();
    std::wcerr << L"[CommandShortcutManager] RegisterHotKey failed with error: " << err << std::endl;
    return false;
  }

  // Registration succeeded! Safely unregister previous hotkey
  if (is_registered_) {
    ::UnregisterHotKey(message_hwnd_, active_hotkey_id_);
  }

  active_hotkey_id_ = candidate_id;
  is_registered_ = true;
  current_key_ = clean_key;
  current_modifiers_ = clean_mods;
  current_vk_ = vk;
  current_mod_flags_ = mod_flags;

  std::wcout << L"[CommandShortcutManager] Successfully registered shortcut: "
             << clean_key.c_str() << L" (VK: " << vk << L")" << std::endl;

  if (persist) {
    atfix::ConfigurationStore::GetInstance().SaveShortcut(clean_key, clean_mods);
  }

  return true;
}

CommandShortcutManager::ShortcutInfo CommandShortcutManager::GetRegisteredShortcutInfo() const {
  ShortcutInfo info;
  info.key = current_key_;
  info.modifiers = current_modifiers_;
  return info;
}

void CommandShortcutManager::Start(HWND message_hwnd) {
  if (is_started_) {
    return;
  }

  message_hwnd_ = message_hwnd;
  is_started_ = true;

  std::string saved_key;
  std::vector<std::string> saved_mods;
  if (atfix::ConfigurationStore::GetInstance().GetShortcut(&saved_key, &saved_mods) &&
      RegisterShortcut(saved_key, saved_mods, /*persist=*/false)) {
    std::wcout << L"[CommandShortcutManager] Restored saved shortcut" << std::endl;
  } else {
    RegisterShortcut("space", {"control", "alt"}, /*persist=*/false);
    std::wcout << L"[CommandShortcutManager] Registered default shortcut: Ctrl + Alt + Space" << std::endl;
  }
}

void CommandShortcutManager::Stop() {
  if (!is_started_) {
    return;
  }

  if (message_hwnd_ && is_registered_) {
    ::UnregisterHotKey(message_hwnd_, active_hotkey_id_);
    is_registered_ = false;
    message_hwnd_ = nullptr;
  }

  is_started_ = false;
  prompt_window_.Close();
  std::wcout << L"[CommandShortcutManager] Stopped and unregistered hotkey" << std::endl;
}

bool CommandShortcutManager::HandleHotKey(WPARAM wparam, LPARAM lparam) {
  if (static_cast<int>(wparam) == active_hotkey_id_) {
    TriggerShortcut();
    return true;
  }
  return false;
}

void CommandShortcutManager::TriggerShortcut() {
  std::wcout << L"[CommandShortcutManager] Global shortcut triggered (Ctrl + Alt + Space)" << std::endl;

  auto target = WindowsAccessibilityService::GetInstance().GetForegroundTarget();
  if (!target.hwnd || target.hwnd == prompt_window_.GetHwnd()) {
    return;
  }

  std::wstring selected_text = WindowsAccessibilityService::GetInstance().GetSelectedText(target.hwnd);
  if (selected_text.empty()) {
    // If nothing selected, prompt can still display with placeholder or info
    selected_text = L"No text selected";
  }

  std::wcout << L"[CommandShortcutManager] Target app: " << target.process_name
             << L", PID: " << target.pid
             << L", Selected text: '" << selected_text << L"'" << std::endl;

  prompt_window_.Show(selected_text, target.hwnd, target.pid);
}

void CommandShortcutManager::OnCommandSelected(const std::wstring& command) {
  std::wcout << L"[CommandShortcutManager] Command selected: " << command << std::endl;
  prompt_window_.UpdateLoadingState({command});

  if (on_command_selected_) {
    on_command_selected_(command, prompt_window_.GetOriginalSelectedText(),
                         prompt_window_.GetTargetHwnd(), prompt_window_.GetTargetPid());
  }
}

void CommandShortcutManager::OnPromptCancelled() {
  std::wcout << L"[CommandShortcutManager] Prompt cancelled by user" << std::endl;
  if (on_cancelled_) {
    on_cancelled_();
  }
}

void CommandShortcutManager::OnPromptClosed() {
  std::wcout << L"[CommandShortcutManager] Prompt window closed" << std::endl;
  if (on_cancelled_) {
    on_cancelled_();
  }
}

