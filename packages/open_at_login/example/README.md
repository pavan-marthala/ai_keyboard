# open_at_login_example

Demonstration application for the [`open_at_login`](../) Flutter plugin on macOS and Windows.

This example app demonstrates how to:
1. Initialize the `OpenAtLogin` singleton with the application's name and executable path.
2. Query the current launch-at-login status (`isEnabled()`).
3. Toggle the launch-at-login status (`setEnabled(bool)`).

---

## Running the Example

### macOS

1. Navigate to the example directory:
   ```bash
   cd packages/open_at_login/example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Ensure `LaunchAtLogin-Modern` is linked to the Xcode project:
   - Open `macos/Runner.xcworkspace` in Xcode.
   - Verify that `https://github.com/sindresorhus/LaunchAtLogin-Modern` is added under **Package Dependencies** and linked to the **Runner** target.

4. Run the application:
   ```bash
   flutter run -d macos
   ```

### Windows (Unpackaged / Standalone EXE)

1. Navigate to the example directory:
   ```bash
   cd packages/open_at_login/example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application directly:
   ```bash
   flutter run -d windows
   ```

   When toggled on, the application creates a registry entry under:
   ```text
   HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
   ```

### Windows (MSIX Packaged App)

To test MSIX packaged launch-at-login behavior using `Windows.ApplicationModel.StartupTask`:

1. Configure the `msix` tool or configure your `AppxManifest.xml` to include the `windows.startupTask` extension.
2. Build and package the MSIX:
   ```bash
   dart run msix:create
   ```
3. Install the generated `.msix` package on Windows 10/11.
4. Launch the application from Start Menu. The plugin automatically detects the MSIX package identity and manages the startup task state via the Windows Runtime APIs.

---

## Code Overview

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_at_login/open_at_login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final OpenAtLogin openAtLogin = OpenAtLogin.instance;
  openAtLogin.initialize(
    appName: 'OpenAtLogin Example',
    appPath: Platform.resolvedExecutable,
  );
  
  runApp(const MyApp());
}
```
