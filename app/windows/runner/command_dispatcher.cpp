#include "command_dispatcher.h"

#include <windows.h>
#include <rpc.h>
#include <thread>
#include <sstream>
#include "ai_transformer.h"
#include "windows_text_replacement_service.h"

#pragma comment(lib, "rpcrt4.lib")

namespace atfix {

namespace {

std::string GenerateUuid() {
  UUID uuid;
  UuidCreate(&uuid);
  RPC_CSTR rpc_str = nullptr;
  UuidToStringA(&uuid, &rpc_str);
  std::string result = rpc_str ? reinterpret_cast<char*>(rpc_str) : "exec-id";
  if (rpc_str) RpcStringFreeA(&rpc_str);
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

CommandDispatcher& CommandDispatcher::GetInstance() {
  static CommandDispatcher instance;
  return instance;
}

void CommandDispatcher::OnCommandSelected(const std::wstring& command) {
  if (!prompt_window_) return;
  Dispatch(
      command,
      prompt_window_->GetTargetHwnd(),
      prompt_window_->GetTargetPid(),
      prompt_window_->GetOriginalSelectedText(),
      prompt_window_);
}

void CommandDispatcher::OnPromptCancelled() {
  CancelAll();
}

void CommandDispatcher::OnPromptClosed() {
  CancelAll();
}

std::vector<std::wstring> CommandDispatcher::GetRunningCommands() {
  std::lock_guard<std::mutex> lock(mutex_);
  std::vector<std::wstring> running;
  for (const auto& pair : active_executions_) {
    if (!pair.second->is_cancelled.load()) {
      running.push_back(pair.second->command);
    }
  }
  return running;
}

void CommandDispatcher::CleanupExecution(const std::string& execution_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  active_executions_.erase(execution_id);
}

void CommandDispatcher::CancelAll() {
  std::lock_guard<std::mutex> lock(mutex_);
  for (auto& pair : active_executions_) {
    pair.second->is_cancelled.store(true);
  }
  active_executions_.clear();
}

void CommandDispatcher::Dispatch(
    const std::wstring& command,
    HWND target_hwnd,
    DWORD target_pid,
    const std::wstring& selected_text,
    CommandPromptWindow* prompt) {
  auto execution = std::make_shared<CommandExecutionContext>();
  execution->id = GenerateUuid();
  execution->command = command;
  execution->target_hwnd = target_hwnd;
  execution->target_pid = target_pid;
  execution->selected_text = selected_text;
  execution->is_cancelled.store(false);

  {
    std::lock_guard<std::mutex> lock(mutex_);
    active_executions_[execution->id] = execution;
  }

  if (prompt) {
    prompt->UpdateLoadingState(GetRunningCommands());
  }

  std::thread([this, execution, prompt]() {
    std::string cmd_utf8 = WideToUtf8(execution->command);
    std::string text_utf8 = WideToUtf8(execution->selected_text);

    try {
      std::string transformed_utf8 =
          AiTransformer::GetInstance().Transform(cmd_utf8, text_utf8);

      if (execution->is_cancelled.load()) {
        CleanupExecution(execution->id);
        return;
      }

      std::wstring transformed_wide = Utf8ToWide(transformed_utf8);

      // Close prompt window thread-safely via PostMessage
      if (prompt) {
        prompt->PostClose();
      }

      // Replace text in target window
      WindowsTextReplacementService::GetInstance().ReplaceSelectedText(
          execution->target_hwnd,
          execution->target_pid,
          transformed_wide);

    } catch (const AiFailure& failure) {
      if (!execution->is_cancelled.load() && prompt) {
        prompt->PostError(execution->command, Utf8ToWide(failure.GetUserMessage()));
      }
    } catch (const std::exception& ex) {
      if (!execution->is_cancelled.load() && prompt) {
        prompt->PostError(execution->command, Utf8ToWide(ex.what()));
      }
    } catch (...) {
      if (!execution->is_cancelled.load() && prompt) {
        prompt->PostError(execution->command, L"Unexpected error during transformation.");
      }
    }

    CleanupExecution(execution->id);
  }).detach();
}

}  // namespace atfix

