# macOS Installation & Setup Guide

This guide covers system requirements, installation steps, Gatekeeper verification, Hardened Runtime details, and required system permissions for running **AtFix** on macOS.

---

## 1. Distribution Model & Open-Source Code Signing Status

> [!IMPORTANT]
> **Open-Source Distribution Status:**  
> AtFix is currently distributed as an unnotarized, open-source macOS application. The project does **not** currently have an active Apple Developer Program subscription. Consequently:
>
> - Binaries are **not signed** with an Apple Developer ID Application certificate.
> - Binaries are **not notarized** by Apple's automated ticket service.
> - The application is **not distributed** via the Mac App Store.

Because the app is not notarized with an Apple Developer ID, macOS Gatekeeper will display a security alert on first launch. This is standard macOS security behavior for independent open-source software built outside the paid Apple Developer Program. You can safely launch the application using the Gatekeeper resolution procedures detailed below.

---

## 2. Understanding macOS Security Concepts

To avoid confusion, AtFix keeps these security layers distinct:

- **Hardened Runtime (`ENABLE_HARDENED_RUNTIME = YES`):** Built into the macOS Runner target to protect the process memory space and prevent dynamic code injection. Hardened Runtime does **not** mean the application is notarized or signed with Developer ID.
- **Code Signing:** Debug builds use local development signatures (`Apple Development` or Ad-Hoc). Release builds require a trusted Developer ID certificate for distribution without Gatekeeper warnings.
- **Developer ID & Notarization:** Requires an active Apple Developer Program membership where binaries are scanned and ticketed by Apple. Currently not attached to this open-source project.
- **Gatekeeper:** The macOS subsystem verifying downloaded binaries against quarantine flags (`com.apple.quarantine`).
- **Accessibility Permission:** A runtime user permission granted in System Settings allowing AtFix to inspect the focused UI element, read selected text, determine selection ranges, and perform synthetic text replacements.
- **Input Monitoring Permission:** A separate runtime user permission granted in System Settings allowing AtFix to detect the global keyboard shortcut (<kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>Space</kbd>).

---

## 3. System Requirements

| Requirement | Specification |
| :--- | :--- |
| **Operating System** | macOS 12.0 (Monterey) or newer (`MACOSX_DEPLOYMENT_TARGET = 12.0`) |
| **Architecture** | Apple Silicon (M1/M2/M3/M4) or Intel (x86_64) |
| **Hardware Permissions** | Accessibility and Input Monitoring (see [Permissions](#6-required-system-permissions)) |
| **AI Credentials** | An API key from at least one supported AI provider (OpenAI, OpenRouter, or Groq) |

---

## 4. Obtaining the Application

### Option A: Official Release Build (Recommended)

1. Download the latest `AtFix-macos.zip` or `.app` bundle from the official [GitHub Releases](https://github.com/pavan-marthala/atfix/releases) page.
2. If downloaded as a ZIP archive, extract it.
3. Drag `AtFix.app` into your `/Applications` directory:

   ```bash
   mv ~/Downloads/AtFix.app /Applications/
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

# 4. Copy the built app to /Applications as AtFix.app
cp -R build/macos/Build/Products/Release/atfix.app /Applications/AtFix.app
```

---

## 5. First Launch & Gatekeeper Resolution

When you attempt to open an unnotarized application downloaded from the web, macOS Gatekeeper blocks launch and shows an alert:

> *"Apple could not verify 'AtFix' is free of malware that may harm your Mac or compromise your privacy."*  
> or  
> *"'AtFix' cannot be opened because it is from an unidentified developer."*

This occurs because web browsers automatically attach a quarantine flag (`com.apple.quarantine`) to downloaded archives and applications.

> [!WARNING]
> Only bypass Gatekeeper if you obtained `AtFix` directly from the official [GitHub repository](https://github.com/pavan-marthala/atfix) or compiled it yourself from source.  
> **Never disable Gatekeeper globally** (e.g. do not run `spctl --master-disable`). Always remove quarantine on an individual application basis for software you explicitly trust.

### Method 1: Terminal (Recommended One-Time Command)

After moving `AtFix.app` to `/Applications`, open Terminal (`/Applications/Utilities/Terminal.app`) and run:

```bash
xattr -dr com.apple.quarantine /Applications/AtFix.app
```

**What this command does:**

- `xattr`: Inspects or modifies macOS extended file attributes.
- `-d`: Deletes the specified attribute.
- `-r`: Recursively removes the attribute through all subfiles in the app bundle.
- `com.apple.quarantine`: The specific security flag set by web downloaders that triggers Gatekeeper alerts.

Once executed, you can launch `AtFix` normally from Launchpad, Spotlight, or `/Applications`.

### Method 2: Finder / System Settings (GUI Alternative)

If you prefer using the graphical interface:

1. Open **Finder** and navigate to your **Applications** folder (`/Applications`).
2. Locate **AtFix.app**.
3. **Right-click** (or hold <kbd>Control</kbd> and click) on **AtFix.app** and select **Open**.
4. If a dialog appears asking if you want to open it, click **Open**.
5. *If blocked by System Settings:* Open **System Settings > Privacy & Security**, scroll down to the **Security** section where you will see:
   > *"AtFix was blocked from use because it is not from an identified developer."*
6. Click **Open Anyway**, then confirm by entering your Mac user password or Touch ID.

This is a one-time approval procedure for users who trust the application. macOS remembers your choice for future launches.

---

## 6. Required System Permissions

To provide system-wide text transformation across external applications, AtFix requires two distinct macOS permissions. The app includes a built-in onboarding screen on first launch that checks these statuses and provides direct shortcut buttons to the respective System Settings panes.

### 1. Accessibility (`AXIsProcessTrusted`)

- **Used for:**
  - Identifying the active, focused UI element across external applications.
  - Reading selected text.
  - Reading text selection ranges.
  - Interacting with the target application to replace the selected text with transformed output.
- **How to grant manually:**
  1. Open **System Settings > Privacy & Security > Accessibility**.
  2. Locate **AtFix** in the list and toggle the switch **ON**.
  3. If prompted, authenticate with your Mac user password or Touch ID.
  4. If `AtFix` is not listed, click the **+** (Add) button, navigate to `/Applications`, and select `AtFix.app`.

### 2. Input Monitoring (`IOHIDRequestAccess`)

- **Used for:**
  - Detecting the global keyboard shortcut (<kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>Space</kbd>) via `CGEvent` session taps without requiring focus on the AtFix window.
- **How to grant manually:**
  1. Open **System Settings > Privacy & Security > Input Monitoring**.
  2. Locate **AtFix** in the list and toggle the switch **ON**.
  3. When macOS prompts that the application must be restarted to apply changes, select **Quit & Reopen**.

> [!NOTE]
> Accessibility and Input Monitoring are separate macOS permissions governed by distinct security entitlements. Enabling Hardened Runtime does **not** grant or bypass either permission.

---

## 7. Using the Desktop Shortcut Workflow

Once permissions are configured:

1. In any macOS application, **select the text** you want to fix or transform (e.g. in TextEdit, Mail, Safari, Slack, or Notes).
2. Press the global shortcut:

   ```text
   Control + Option + Space
   ```

3. A native floating prompt panel appears directly over your active application with the selected text captured.
4. Choose an AI transformation command:
   - **`@fix`**: Corrects spelling, punctuation, and grammar while preserving meaning.
   - **`@rewrite`**: Paraphrases and polishes the text cleanly.
   - **`@short`**: Condenses the text into a concise phrasing.
   - **`@expand`**: Elaborates with clarity and helpful detail.
5. While the AI model processes your request, a loading indicator displays progress.
6. Once complete, AtFix smoothly refocuses the target application and inserts the AI-transformed replacement directly into the original text field.
