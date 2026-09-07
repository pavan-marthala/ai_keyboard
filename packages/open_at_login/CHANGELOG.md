## 0.0.1

* Initial release supporting macOS and Windows launch-at-login.
* macOS: Integrates modern Apple Service Management (`SMAppService.mainApp`) via `LaunchAtLogin-Modern`.
* Windows: Native C++ Flutter plugin managing user startup registration via `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
* Standard `CommandLineToArgvW` argument formatting and escaping for Windows.
* Graceful, safe no-op on unsupported platforms (Linux, Android, iOS, Web).
