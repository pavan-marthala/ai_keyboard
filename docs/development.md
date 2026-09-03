# Development & Setup Guide

This document outlines environment prerequisites, local setup instructions, build configurations, testing procedures, and troubleshooting guidelines for the AI Keyboard project.

---

## 1. Prerequisites

Ensure your development environment meets the following toolchain requirements:

| Tool | Version Requirement | Purpose |
| :--- | :--- | :--- |
| **Flutter SDK** | 3.13.2+ (Dart SDK `^3.13.2`) | App shell UI, dependency injection, and state management. |
| **Android SDK** | API level 37 (`compileSdk 37`, `targetSdk 37`, `minSdk 21`) | Android native keyboard compilation. |
| **Android NDK** | Compatible NDK configured in Android Studio / SDK Manager | AOSP LatinIME C++ native compilation. |
| **CMake** | 3.22.1 | Native C++ build orchestration (`app/android/app/src/main/cpp/CMakeLists.txt`). |
| **JDK** | Java 17 | Required for Gradle 8+ and Android build tools. |
| **Xcode** | 15+ (macOS only) | Required for iOS app shell and Keyboard Extension compilation. |

---

## 2. Local Environment Setup

### 1. Clone the Repository
```bash
git clone https://github.com/pavan-marthala/ai_keyboard.git
cd ai_keyboard
```

### 2. Install Flutter Dependencies
All Flutter and Dart source code resides in the `app/` subdirectory:
```bash
cd app
flutter pub get
```

### 3. Run Code Generation
The project relies on code generation for dependency injection (`injectable`), immutable state and entities (`freezed`), and JSON serialization (`json_serializable`):
```bash
# Execute from inside the app/ directory:
dart run build_runner build --delete-conflicting-outputs
```
This updates:
- `lib/core/di/injection.config.dart`
- `*.freezed.dart`
- `*.g.dart`

---

## 3. Running the Application

### Running the Flutter App Shell
From the `app/` directory:
```bash
flutter run
```

### Enabling the Keyboard on Device

#### Android
1. Build and install the debug APK on an emulator or connected device (`flutter run` or `flutter install`).
2. Open system **Settings** > **System** > **Languages & Input** (or **General Management** > **Keyboard list and default** on Samsung devices).
3. Select **On-screen keyboard** > **Manage on-screen keyboards**.
4. Enable **AI Keyboard**.
5. Switch to AI Keyboard in any text field using the input method selector.

#### iOS
1. Open `app/ios/Runner.xcworkspace` in Xcode.
2. Ensure both the `Runner` and `KeyboardExtension` targets have valid development signing team and matching App Group (`group.com.pk.ai_keyboard.shared`) configurations.
3. Deploy to an iOS device or simulator.
4. In iOS **Settings**, navigate to **General** > **Keyboard** > **Keyboards** > **Add New Keyboard...** and select **AI Keyboard**.
5. Tap the added keyboard and toggle **Allow Full Access** (required for network access to call AI provider APIs).

---

## 4. Testing

### Flutter Unit & Contract Tests
Run all Flutter unit and widget tests from the `app/` directory:
```bash
cd app
flutter test
```

### Android Native Tests
Run unit tests for native Android components (including `AospSuggestionEngineTest`):
```bash
cd app/android
./gradlew test
```

To run a specific Android test class:
```bash
./gradlew testDebugUnitTest --tests "com.pk.ai_keyboard.suggestion.aosp.AospSuggestionEngineTest"
```

---

## 5. Building Binaries

### Android Debug APK
```bash
cd app
flutter build apk --debug
```

### Android Release APK
> [!IMPORTANT]
> The current release build configuration in `app/android/app/build.gradle.kts` uses debug signing keys for local testing. A production release requires creating a keystore, configuring `key.properties`, and updating the `release` signing block.

```bash
cd app
flutter build apk --release
```

### iOS Application
```bash
cd app
flutter build ios --no-codesign
```

---

## 6. Common Issues & Troubleshooting

### 1. CMake or NDK Not Found
- **Symptom:** Gradle build fails with `CMake '3.22.1' was not found in SDK` or `NDK not configured`.
- **Solution:**
  1. Open Android Studio > **Tools** > **SDK Manager** > **SDK Tools**.
  2. Check **Show Package Details**.
  3. Ensure **CMake 3.22.1** and an NDK package are installed.
  4. Optionally define `ndk.dir` in `app/android/local.properties`:
     ```properties
     ndk.dir=/path/to/your/android/sdk/ndk/<version>
     ```

### 2. Code Generation Mismatches
- **Symptom:** Build errors referencing missing `_$*` classes or `injection.config.dart`.
- **Solution:** Clear the build runner cache and re-run:
  ```bash
  cd app
  flutter clean
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  ```

### 3. iOS Podfile or Plugin Inconsistencies
- **Symptom:** CocoaPods fails to resolve or links missing symbols during `flutter build ios`.
- **Solution:**
  ```bash
  cd app/ios
  rm -rf Pods Podfile.lock .symlinks
  pod repo update
  pod install
  ```

### 4. GIF Search Fails
- **Symptom:** The GIF keyboard mode displays an error or remains blank.
- **Solution:** Ensure a valid Giphy API key is provided via `GIPHY_API_KEY` in `app/android/local.properties` or as an environment variable:
  ```properties
  GIPHY_API_KEY=your_giphy_api_key_here
  ```
