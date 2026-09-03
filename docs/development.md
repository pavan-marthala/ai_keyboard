# Development Setup and Workflow

This guide covers how to set up the development environment, build, and test the AI Keyboard project.

## 1. Prerequisites

Before you begin, ensure you have the following installed:

*   **Flutter SDK**: Dart SDK `^3.13.2` or higher.
*   **Android SDK**: Must include `compileSdk 37` and the Android NDK.
*   **CMake**: Version `3.22.1`.
*   **Xcode**: Required for building and running on iOS/macOS.
*   **IDE**: Visual Studio Code or Android Studio is recommended.

## 2. Getting Started

Clone the repository and fetch dependencies:

```bash
git clone https://github.com/pavan-marthala/ai_keyboard.git
cd ai_keyboard/app
flutter pub get
```

## 3. Code Generation

The Flutter app relies heavily on code generation for immutable models and dependency injection. Run the following command whenever you modify models or DI configuration:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This will generate `*.freezed.dart`, `*.g.dart`, and `injection.config.dart` files.

## 4. Running the App and Keyboard

### Running the App Shell
To run the main Flutter configuration app:
```bash
flutter run
```

### Enabling the Keyboard
After installation, you must manually enable the keyboard in your device settings.

*   **Android**: Go to Settings > System > Languages & Input > On-screen keyboard.
*   **iOS**: Go to Settings > General > Keyboard > Keyboards > Add New Keyboard.

## 5. Testing

### Flutter Tests
To run unit and widget tests for the Flutter shell:
```bash
cd app
flutter test
```

### Android Native Tests
To run tests for the Android native keyboard (requires Android SDK):
```bash
cd app/android
./gradlew test
```

## 6. Building

### Android Debug APK
```bash
cd app
flutter build apk --debug
```

### Android Release APK
*Note: Building a release APK requires a valid signing config.*
```bash
cd app
flutter build apk --release
```

### iOS Build
*Note: Requires Xcode and valid provisioning profiles.*
```bash
cd app
flutter build ios
```

## 7. Project Structure (`app/`)

The core application code is located in the `app/` directory:
*   `lib/`: Flutter app shell source code (Dart).
*   `android/`: Android native keyboard source code (Kotlin/C++).
*   `ios/`: iOS native keyboard extension source code (Swift).

## 8. Common Issues and Troubleshooting

*   **NDK not found**: If building Android fails due to a missing NDK, specify the `ndk.dir` path in your `local.properties` file.
*   **CMake errors**: Ensure you have exactly CMake version `3.22.1` installed via the Android SDK Manager.
*   **iOS build issues**: If iOS builds fail, try updating CocoaPods dependencies:
    ```bash
    cd app/ios
    pod install
    ```
*   **Code generation issues**: If you encounter errors related to generated files, clear the build cache and run the generator again:
    ```bash
    flutter clean
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    ```
