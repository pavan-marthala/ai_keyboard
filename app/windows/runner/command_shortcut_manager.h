#ifndef RUNNER_COMMAND_SHORTCUT_MANAGER_H_
#define RUNNER_COMMAND_SHORTCUT_MANAGER_H_

#include <windows.h>
#include <memory>
#include <functional>
#include <string>

#include "command_prompt_window.h"

class CommandShortcutManager : public CommandPromptDelegate {
 public:
  static CommandShortcutManager& GetInstance();

  /// Starts the global shortcut listener. Idempotent.
  void Start(HWND message_hwnd);

  /// Stops the global shortcut listener and unregisters hotkeys.
  void Stop();

  /// Processes WM_HOTKEY window messages. Returns true if handled.
  bool HandleHotKey(WPARAM wparam, LPARAM lparam);

  /// Manually triggers the shortcut workflow (for testing or menu actions).
  void TriggerShortcut();

  CommandPromptWindow& GetPromptWindow() { return prompt_window_; }

  // CommandPromptDelegate implementation
  void OnCommandSelected(const std::wstring& command) override;
  void OnPromptCancelled() override;
  void OnPromptClosed() override;

  // Callback to notify Flutter MethodChannel
  using CommandSelectedCallback = std::function<void(const std::wstring& command, const std::wstring& text, HWND target_hwnd, DWORD target_pid)>;
  using CancelledCallback = std::function<void()>;

  void SetCommandSelectedCallback(CommandSelectedCallback cb) { on_command_selected_ = cb; }
  void SetCancelledCallback(CancelledCallback cb) { on_cancelled_ = cb; }

 private:
  CommandShortcutManager();
  ~CommandShortcutManager();

  static constexpr int kAtFixHotKeyId = 9001;

  bool is_started_ = false;
  HWND message_hwnd_ = nullptr;
  CommandPromptWindow prompt_window_;

  CommandSelectedCallback on_command_selected_;
  CancelledCallback on_cancelled_;
};

#endif  // RUNNER_COMMAND_SHORTCUT_MANAGER_H_

