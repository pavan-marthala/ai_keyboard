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

  /// Struct containing key and modifiers info.
  struct ShortcutInfo {
    std::string key;
    std::vector<std::string> modifiers;
  };

  /// Dynamically registers a global shortcut.
  /// If registration fails, previous shortcut remains active and unchanged.
  bool RegisterShortcut(const std::string& key, const std::vector<std::string>& modifiers, bool persist = true);

  /// Retrieves the active shortcut information.
  ShortcutInfo GetRegisteredShortcutInfo() const;

  static UINT KeyNameToVk(const std::string& key_name);
  static UINT ModifiersToFlags(const std::vector<std::string>& modifiers);

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
  static constexpr int kCandidateHotKeyId = 9002;

  bool is_started_ = false;
  bool is_registered_ = false;
  int active_hotkey_id_ = kAtFixHotKeyId;
  HWND message_hwnd_ = nullptr;
  CommandPromptWindow prompt_window_;

  std::string current_key_ = "space";
  std::vector<std::string> current_modifiers_ = {"control", "alt"};
  UINT current_vk_ = VK_SPACE;
  UINT current_mod_flags_ = MOD_CONTROL | MOD_ALT;

  CommandSelectedCallback on_command_selected_;
  CancelledCallback on_cancelled_;
};

#endif  // RUNNER_COMMAND_SHORTCUT_MANAGER_H_

