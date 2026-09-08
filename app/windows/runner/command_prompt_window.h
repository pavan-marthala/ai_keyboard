#ifndef RUNNER_COMMAND_PROMPT_WINDOW_H_
#define RUNNER_COMMAND_PROMPT_WINDOW_H_

#include <windows.h>
#include <string>
#include <vector>
#include <memory>
#include <functional>
#include <cmath>

namespace atfix {

// Custom Win32 window messages for thread-safe UI communication
constexpr UINT WM_ATFIX_PROMPT_CLOSE = WM_APP + 201;
constexpr UINT WM_ATFIX_PROMPT_ERROR = WM_APP + 202;

/// Payload for asynchronous error dispatch to prompt UI thread.
struct PromptErrorPayload {
  std::wstring command;
  std::wstring message;
};

}  // namespace atfix

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

  /// Dismisses and hides the prompt window (must run on owning UI thread).
  void Close();

  /// Thread-safe close: posts WM_ATFIX_PROMPT_CLOSE to the prompt HWND owning thread.
  void PostClose();

  /// Updates loading spinner and status text for running commands.
  void UpdateLoadingState(const std::vector<std::wstring>& running_commands);

  /// Displays an error message inside the status area (must run on owning UI thread).
  void ShowError(const std::wstring& command, const std::wstring& message);

  /// Thread-safe error dispatch: posts WM_ATFIX_PROMPT_ERROR with payload to owning thread.
  void PostError(const std::wstring& command, const std::wstring& message);

  bool IsVisible() const;

  HWND GetHwnd() const { return hwnd_; }
  HWND GetTargetHwnd() const { return target_hwnd_; }
  DWORD GetTargetPid() const { return target_pid_; }
  const std::wstring& GetOriginalSelectedText() const { return selected_text_; }

  // Centralized metric/scaling mechanism
  int Scale(int logicalPixels) const {
    return static_cast<int>(std::round(logicalPixels * scale_));
  }
  float Scale(float logicalPixels) const {
    return logicalPixels * scale_;
  }
  float ScaleFont(float logicalPoints) const {
    return logicalPoints * scale_;
  }

  UINT GetDpi() const { return dpi_; }
  float GetScale() const { return scale_; }
  void UpdateDpi(UINT dpi);

 private:
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam);
  LRESULT HandleMessage(UINT msg, WPARAM wparam, LPARAM lparam);

  void RegisterWindowClass();
  void UpdateLayout();
  void UpdateWindowRegion();
  void RepositionNearCursor(int width, int height);
  void OnPaint();
  void OnMouseMove(int x, int y);
  void OnLButtonDown(int x, int y);
  void OnKeyDown(WPARAM key);
  void TriggerSelectedCommand();
  void AnimateSpinner();
  void UpdateDpiFromMonitorOrWindow(HMONITOR monitor);

  static std::wstring ActionLabelForCommand(const std::wstring& command);

  HWND hwnd_ = nullptr;
  CommandPromptDelegate* delegate_ = nullptr;

  HWND target_hwnd_ = nullptr;
  DWORD target_pid_ = 0;
  std::wstring selected_text_;
  std::wstring truncated_preview_;

  // DPI state
  UINT dpi_ = 96;
  float scale_ = 1.0f;

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

  // Logical layout metrics (matching macOS CommandPrompt.swift)
  static constexpr int kHorizontalPadding = 20;
  static constexpr int kVerticalPadding = 18;
  static constexpr int kHeaderHeight = 22;
  static constexpr int kGapAfterHeader = 4;
  static constexpr int kPreviewHeight = 18;
  static constexpr int kGapPreviewToChipsCompact = 16;
  static constexpr int kGapAfterPreviewExpanded = 12;
  static constexpr int kStatusAreaHeight = 22;
  static constexpr int kGapAfterStatusExpanded = 14;
  static constexpr int kChipHeight = 32;
  static constexpr int kChipSpacing = 8;
  static constexpr int kChipHorizontalPadding = 16;
  static constexpr int kCornerRadius = 18;
  static constexpr int kCloseButtonSize = 22;
  static constexpr int kMinPanelWidth = 380;

  // Logical font sizes
  static constexpr float kTitleFontSize = 10.5f;
  static constexpr float kPreviewFontSize = 9.0f;
  static constexpr float kChipFontSize = 9.5f;
  static constexpr float kStatusFontSize = 9.0f;

  // Scaled physical pixel dimensions
  int panel_width_ = kMinPanelWidth;
  int panel_height_ = 128;
  int title_y_ = kVerticalPadding;
  int preview_y_ = kVerticalPadding + kHeaderHeight + kGapAfterHeader;
  int status_y_ = 0;
  int chip_y_ = 0;

  static bool gdiplus_initialized_;
  static ULONG_PTR gdiplus_token_;
  static void EnsureGdiplus();
};

#endif  // RUNNER_COMMAND_PROMPT_WINDOW_H_

