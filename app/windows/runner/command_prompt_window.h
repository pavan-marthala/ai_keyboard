#ifndef RUNNER_COMMAND_PROMPT_WINDOW_H_
#define RUNNER_COMMAND_PROMPT_WINDOW_H_

#include <windows.h>
#include <string>
#include <vector>
#include <memory>
#include <functional>

/// Delegate interface for CommandPromptWindow events.
class CommandPromptDelegate {
 public:
  virtual ~CommandPromptDelegate() = default;
  virtual void OnCommandSelected(const std::wstring& command) = 0;
  virtual void OnPromptCancelled() = 0;
  virtual void OnPromptClosed() = 0;
};

/// Represents a pill-shaped command button inside the prompt window.
struct CommandChip {
  std::wstring command;
  RECT rect;
  bool is_hovered = false;
  bool is_focused = false;
};

/// Native Win32 floating command prompt window.
/// Replicates macOS CommandPrompt.swift 1:1 in layout, colors, typography, and states.
class CommandPromptWindow {
 public:
  CommandPromptWindow();
  ~CommandPromptWindow();

  // Non-copyable
  CommandPromptWindow(const CommandPromptWindow&) = delete;
  CommandPromptWindow& operator=(const CommandPromptWindow&) = delete;

  void SetDelegate(CommandPromptDelegate* delegate) { delegate_ = delegate; }

  /// Presents the floating prompt card near the cursor with the specified selected text.
  void Show(const std::wstring& selected_text, HWND target_hwnd, DWORD target_pid);

  /// Dismisses and hides the prompt window.
  void Close();

  /// Updates loading spinner and status text for running commands.
  void UpdateLoadingState(const std::vector<std::wstring>& running_commands);

  /// Displays an error message inside the status area.
  void ShowError(const std::wstring& command, const std::wstring& message);

  bool IsVisible() const;

  HWND GetHwnd() const { return hwnd_; }
  HWND GetTargetHwnd() const { return target_hwnd_; }
  DWORD GetTargetPid() const { return target_pid_; }
  const std::wstring& GetOriginalSelectedText() const { return selected_text_; }

 private:
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam);
  LRESULT HandleMessage(UINT msg, WPARAM wparam, LPARAM lparam);

  void RegisterWindowClass();
  void UpdateLayout();
  void RepositionNearCursor(int width, int height);
  void OnPaint();
  void OnMouseMove(int x, int y);
  void OnLButtonDown(int x, int y);
  void OnKeyDown(WPARAM key);
  void TriggerSelectedCommand();
  void AnimateSpinner();

  static std::wstring ActionLabelForCommand(const std::wstring& command);

  HWND hwnd_ = nullptr;
  CommandPromptDelegate* delegate_ = nullptr;

  HWND target_hwnd_ = nullptr;
  DWORD target_pid_ = 0;
  std::wstring selected_text_;
  std::wstring truncated_preview_;

  // Status state
  bool is_expanded_ = false;
  bool is_loading_ = false;
  std::wstring status_text_;
  bool is_error_ = false;
  int spinner_angle_ = 0;
  UINT_PTR spinner_timer_id_ = 0;

  // Buttons & Navigation
  std::vector<CommandChip> chips_;
  int focused_chip_index_ = 0;
  RECT close_button_rect_ = {0, 0, 0, 0};
  bool is_close_hovered_ = false;

  // Layout metrics (matching macOS CommandPrompt.swift)
  static constexpr int kHorizontalPadding = 20;
  static constexpr int kVerticalPadding = 18;
  static constexpr int kChipHeight = 32;
  static constexpr int kChipSpacing = 8;
  static constexpr int kChipHorizontalPadding = 16;
  static constexpr int kCornerRadius = 18;
  static constexpr int kCloseButtonSize = 22;
  static constexpr int kMinPanelWidth = 380;
  static constexpr int kHeaderHeight = 22;
  static constexpr int kPreviewHeight = 18;
  static constexpr int kStatusAreaHeight = 22;

  int panel_width_ = kMinPanelWidth;
  int panel_height_ = 114;
  int compact_panel_height_ = 114;
  int expanded_panel_height_ = 144;

  static bool gdiplus_initialized_;
  static ULONG_PTR gdiplus_token_;
  static void EnsureGdiplus();
};

#endif  // RUNNER_COMMAND_PROMPT_WINDOW_H_

