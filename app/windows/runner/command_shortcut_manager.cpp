#include "command_shortcut_manager.h"
#include "windows_accessibility_service.h"
#include "windows_text_replacement_service.h"

#include <iostream>

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

void CommandShortcutManager::Start(HWND message_hwnd) {
  if (is_started_) {
    return;
  }

  message_hwnd_ = message_hwnd;

  // Register Ctrl + Alt + Space (VK_SPACE = 0x20)
  BOOL success = ::RegisterHotKey(message_hwnd_, kAtFixHotKeyId,
                                  MOD_CONTROL | MOD_ALT | MOD_NOREPEAT, VK_SPACE);
  if (success) {
    is_started_ = true;
    std::wcout << L"[CommandShortcutManager] Registered global shortcut: Ctrl + Alt + Space" << std::endl;
  } else {
    // If MOD_NOREPEAT fails on older systems, retry without it
    success = ::RegisterHotKey(message_hwnd_, kAtFixHotKeyId,
                               MOD_CONTROL | MOD_ALT, VK_SPACE);
    if (success) {
      is_started_ = true;
      std::wcout << L"[CommandShortcutManager] Registered global shortcut: Ctrl + Alt + Space (fallback)" << std::endl;
    } else {
      std::wcerr << L"[CommandShortcutManager] Failed to register global shortcut. Error: " << ::GetLastError() << std::endl;
    }
  }
}

void CommandShortcutManager::Stop() {
  if (!is_started_) {
    return;
  }

  if (message_hwnd_) {
    ::UnregisterHotKey(message_hwnd_, kAtFixHotKeyId);
    message_hwnd_ = nullptr;
  }

  is_started_ = false;
  prompt_window_.Close();
  std::wcout << L"[CommandShortcutManager] Stopped and unregistered hotkey" << std::endl;
}

bool CommandShortcutManager::HandleHotKey(WPARAM wparam, LPARAM lparam) {
  if (static_cast<int>(wparam) == kAtFixHotKeyId) {
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

