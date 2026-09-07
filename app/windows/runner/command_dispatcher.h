#ifndef RUNNER_COMMAND_DISPATCHER_H_
#define RUNNER_COMMAND_DISPATCHER_H_

#include <windows.h>
#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <atomic>
#include <unordered_map>
#include "command_prompt_window.h"

namespace atfix {

/// Independent execution context for an asynchronous command execution.
/// Guarantees that each command retains its immutable target, HWND,
/// text, and cancellation status across async boundaries.
/// Strictly mirrors macOS CommandExecutionContext in CommandDispatcher.swift.
struct CommandExecutionContext {
  std::string id;
  std::wstring command;
  HWND target_hwnd = nullptr;
  DWORD target_pid = 0;
  std::wstring selected_text;
  std::atomic<bool> is_cancelled{false};
};

/// Dispatches selected desktop commands (@fix, @rewrite, @short, @expand) to
/// the native AI transformer, coordinates asynchronous execution and cancellation,
/// updates prompt feedback, and triggers text replacement on success.
/// Strictly mirrors macOS CommandDispatcher.swift.
class CommandDispatcher : public CommandPromptDelegate {
 public:
  static CommandDispatcher& GetInstance();

  CommandDispatcher(const CommandDispatcher&) = delete;
  CommandDispatcher& operator=(const CommandDispatcher&) = delete;

  // CommandPromptDelegate overrides
  void OnCommandSelected(const std::wstring& command) override;
  void OnPromptCancelled() override;
  void OnPromptClosed() override;

  void SetPromptWindow(CommandPromptWindow* prompt_window) {
    prompt_window_ = prompt_window;
    if (prompt_window_) {
      prompt_window_->SetDelegate(this);
    }
  }

  void Dispatch(
      const std::wstring& command,
      HWND target_hwnd,
      DWORD target_pid,
      const std::wstring& selected_text,
      CommandPromptWindow* prompt);

  void CancelAll();

  std::vector<std::wstring> GetRunningCommands();

 private:
  CommandDispatcher() = default;
  ~CommandDispatcher() = default;

  void CleanupExecution(const std::string& execution_id);

  std::mutex mutex_;
  std::unordered_map<std::string, std::shared_ptr<CommandExecutionContext>> active_executions_;
  CommandPromptWindow* prompt_window_ = nullptr;
};

}  // namespace atfix

#endif  // RUNNER_COMMAND_DISPATCHER_H_

