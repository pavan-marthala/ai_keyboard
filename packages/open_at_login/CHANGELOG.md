## 0.0.1

* Initial release supporting macOS and Windows launch-at-login.
* macOS: Integrates modern Apple Service Management (`SMAppService.mainApp`) via `LaunchAtLogin-Modern`.
* Windows: Native support for both unpackaged applications (`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`) and MSIX packaged applications (`Windows.ApplicationModel.StartupTask`).
* Windows: Runtime package identity detection via `GetCurrentPackageFamilyName` and automated TaskId candidate matching.
* Standard `CommandLineToArgvW` argument formatting and escaping for Windows unpackaged applications.
* Graceful, safe no-op on unsupported platforms (Linux, Android, iOS, Web).
