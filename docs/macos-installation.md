# macOS Installation & Setup Guide

This guide covers system requirements, installation steps, Gatekeeper verification, and required system permissions for running **AtFIx** on macOS.

---

## 1. Distribution Model & Code Signing Notice

> [!IMPORTANT]
> **Open-Source Distribution Status:**  
> AtFIx is currently distributed as an unnotarized, open-source macOS application. The project does **not** currently have an active Apple Developer Program subscription. Consequently:
>
> - Binaries are **not signed** with an Apple Developer ID Application certificate.
> - Binaries are **not notarized** by Apple's automated notarization service.
> - The application is **not distributed** via the Mac App Store.

Because the app is not notarized, macOS Gatekeeper will display a security prompt on first launch. This is standard macOS behavior for independent open-source software. You can safely launch the app by following the Gatekeeper instructions below.

---

## 2. System Requirements

| Requirement | Specification |
| :--- | :--- |
| **Operating System** | macOS 12.0 (Monterey) or newer (`MACOSX_DEPLOYMENT_TARGET = 12.0`) |
| **Architecture** | Apple Silicon (M1/M2/M3/M4) or Intel (x86_64) |
| **Hardware Permissions** | Accessibility and Input Monitoring (see [Permissions](#5-required-system-permissions)) |
| **AI Credentials** | An API key from at least one supported AI provider (OpenAI, OpenRouter, or Groq) |

---

## 3. Obtaining the Application

### Option A: Official Release Build (Recommended)

1. Download the latest `atfix-macos.zip` or `.app` bundle from the official [GitHub Releases](https://github.com/pavan-marthala/atfix/releases) page.
2. If downloaded as a ZIP archive, extract it.
3. Drag `atfix.app` into your `/Applications` directory:

   ```bash
   mv ~/Downloads/atfix.app /Applications/
   ```

### Option B: Build from Source

If you prefer building directly from source:

```bash
# 1. Clone the repository
git clone https://github.com/pavan-marthala/atfix.git
cd atfix/app

# 2. Fetch dependencies & generate code
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 3. Build the macOS release binary
flutter build macos --release

# 4. Copy the built app to /Applications
cp -R build/macos/Build/Products/Release/atfix.app /Applications/
```

---

## 4. First Launch & Gatekeeper Resolution

When you attempt to open an unnotarized application downloaded from the web, macOS Gatekeeper may block launch and show an alert:

> *"Apple could not verify 'atfix' is free of malware that may harm your Mac or compromise your privacy."*  
> or  
> *"'atfix' cannot be opened because it is from an unidentified developer."*

This occurs because the browser marks the downloaded file with a macOS quarantine attribute (`com.apple.quarantine`).

> [!WARNING]
> Only bypass Gatekeeper if you obtained `atfix` directly from the official [GitHub repository](https://github.com/pavan-marthala/atfix) or compiled it yourself from source.  
> **Never disable Gatekeeper globally** (e.g. do not run `spctl --master-disable`). Always remove quarantine on an individual application basis.

### Method 1: Terminal (Recommended One-Time Command)

After moving `atfix.app` to `/Applications`, open Terminal (`/Applications/Utilities/Terminal.app`) and run:

```bash
xattr -dr com.apple.quarantine /Applications/atfix.app
```

**What this command does:**

- `xattr`: Inspects or modifies macOS extended file attributes.
- `-d`: Deletes the specified attribute.
- `-r`: Recursively removes the attribute through all subfiles in the app bundle.
- `com.apple.quarantine`: The specific security flag set by web downloaders that triggers Gatekeeper alerts.

Once executed, you can launch `atfix` normally from Launchpad, Spotlight, or `/Applications`.

### Method 2: Finder Context Menu (GUI Alternative)

If you prefer using the graphical interface:

1. Open **Finder** and navigate to your **Applications** folder (`/Applications`).
2. Locate **atfix.app**.
3. **Right-click** (or hold <kbd>Control</kbd> and click) on **atfix.app** and select **Open**.
4. A dialog will appear asking if you are sure you want to open it. Click **Open**.
5. *Note for macOS Ventura, Sonoma, and Sequoia:* If the dialog only offers "Move to Trash" or "Cancel", open **System Settings > Privacy & Security**, scroll down to the **Security** section where you will see:
   > *"atfix was blocked from use because it is not from an identified developer."*
6. Click **Open Anyway**, then confirm by entering your Mac password or Touch ID.

After this initial approval, macOS remembers your choice and subsequent launches will open immediately.

---

## 5. Required System Permissions

To provide system-wide text transformation across external applications, `atfix` requires two macOS permissions. The app includes a built-in onboarding screen on first launch that checks these statuses and provides direct shortcut buttons to the respective System Settings panes.

### 1. Accessibility (`AXIsProcessTrusted`)

- **Why it is needed:** Enables `atfix` to inspect the focused text area in external apps (such as TextEdit, Safari, Mail, Slack, Chrome, or Notes), determine the active selected text, and execute the text replacement via simulated keystrokes.
- **How to grant manually:**
  1. Open **System Settings > Privacy & Security > Accessibility**.
  2. Locate **atfix** in the list and toggle the switch **ON**.
  3. If prompted, authenticate with your Mac user password or Touch ID.
  4. If `atfix` is not listed, click the **+** (Add) button, navigate to `/Applications`, and select `atfix.app`.

### 2. Input Monitoring (`IOHIDRequestAccess`)

- **Why it is needed:** Enables `atfix` to register the global shortcut (<kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>Space</kbd>) via `CGEvent` session taps, allowing you to invoke the AI transformation prompt from any application without switching windows.
- **How to grant manually:**
  1. Open **System Settings > Privacy & Security > Input Monitoring**.
  2. Locate **atfix** in the list and toggle the switch **ON**.
  3. When macOS prompts that the application must be restarted to apply changes, select **Quit & Reopen**.

---

## 6. Using the Desktop Shortcut Feature

Once permissions are enabled:

1. In any macOS application, **select the text** you want to fix or transform (for example, in TextEdit or Slack).
2. Press the global shortcut:

   ```text
   Control + Option + Space
   ```

3. A lightweight native prompt panel will appear over your application with the selected text captured.
4. Choose an AI command:
   - **`@fix`**: Corrects spelling, punctuation, and grammar.
   - **`@rewrite`**: Paraphrases and polishes the text while preserving meaning.
   - **`@short`**: Condenses the text into a concise phrasing.
   - **`@expand`**: Elaborates with clarity and helpful detail.
5. While the AI model processes your request, a loading indicator displays progress.
6. Once complete, `atfix` smoothly refocuses the target app and replaces the selected text with the AI-transformed result.
