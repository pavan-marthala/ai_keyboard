import Cocoa
import FlutterMacOS
import ApplicationServices
import LaunchAtLogin

// kIOHIDRequestTypePostEvent = 0, kIOHIDRequestTypeListenEvent = 1
// kIOHIDAccessTypeGranted = 0, kIOHIDAccessTypeDenied = 1, kIOHIDAccessTypeUnknown = 2
@_silgen_name("IOHIDCheckAccess")
func IOHIDCheckAccess(_ type: UInt32) -> UInt32

@_silgen_name("IOHIDRequestAccess")
func IOHIDRequestAccess(_ type: UInt32) -> Bool

#if DEBUG
func debugLog(_ message: String) {
  print(message)
}
#else
func debugLog(_ message: String) {}
#endif

@main
class AppDelegate: FlutterAppDelegate {
  private var isRealQuitRequested = false

  override func applicationDidFinishLaunching(_ notification: Notification) {

    NSLog("[AppDelegate] applicationDidFinishLaunching CALLED")
    NSLog("[AppDelegate] Starting CommandShortcutManager")
    CommandShortcutManager.shared.start()
    let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    if let messenger = controller?.engine.binaryMessenger {
      for desktopChannelName in ["com.pk.atfix/desktop", "com.pk.ai_keyboard/desktop"] {
        let channel = FlutterMethodChannel(
          name: desktopChannelName,
          binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
          guard let self = self else { return }
          switch call.method {
          case "quitAtFixCompletely":
            debugLog("[NATIVE] quitAtFixCompletely requested from Flutter UI")
            self.isRealQuitRequested = true
            NSApp.terminate(nil)
            result(true)
          case "isAccessibilityGranted":
          let trusted = AXIsProcessTrusted()
          debugLog("[NATIVE] Accessibility (AXIsProcessTrusted) = \(trusted)")
          result(trusted)
        case "requestAccessibility":
          let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
          let trusted = AXIsProcessTrustedWithOptions(options)
          debugLog("[NATIVE] requestAccessibility (AXIsProcessTrustedWithOptions) = \(trusted)")
          result(trusted)
        case "openAccessibilitySettings":
          debugLog("[NATIVE] Prompting Accessibility & Opening Settings")
          let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
          _ = AXIsProcessTrustedWithOptions(options)
          if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"),
             NSWorkspace.shared.open(url) {
            result(true)
          } else if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            result(NSWorkspace.shared.open(fallback))
          } else {
            result(false)
          }
        case "getInputMonitoringStatus":
          let status = IOHIDCheckAccess(1) // kIOHIDRequestTypeListenEvent
          let statusString: String
          switch status {
          case 0:
            statusString = "granted"
          case 1:
            statusString = "denied"
          default:
            statusString = "unknown"
          }
          debugLog("[NATIVE] Input Monitoring (IOHIDCheckAccess) = \(status) -> \(statusString)")
          result(statusString)
        case "isInputMonitoringGranted":
          let status = IOHIDCheckAccess(1)
          let granted = (status == 0)
          debugLog("[NATIVE] isInputMonitoringGranted = \(granted)")
          result(granted)
        case "requestInputMonitoring":
          let granted = IOHIDRequestAccess(1)
          debugLog("[NATIVE] requestInputMonitoring (IOHIDRequestAccess) = \(granted)")
          result(granted)
        case "openInputMonitoringSettings":
          debugLog("[NATIVE] Requesting Input Monitoring Access & Opening Settings")
          _ = IOHIDRequestAccess(1)
          if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"),
             NSWorkspace.shared.open(url) {
            result(true)
          } else if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            result(NSWorkspace.shared.open(fallback))
          } else {
            result(false)
          }
        case "registerHotkey":
          guard let args = call.arguments as? [String: Any],
                let key = args["key"] as? String,
                let modifiers = args["modifiers"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing key or modifiers", details: nil))
            return
          }
          let success = CommandShortcutManager.shared.registerShortcut(key: key, modifiers: modifiers)
          debugLog("[NATIVE] registerHotkey key=\(key) modifiers=\(modifiers) success=\(success)")
          result(success)
        case "getRegisteredHotkey":
          let info = CommandShortcutManager.shared.currentShortcutInfo()
          result(info)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    let credentialsChannel = FlutterMethodChannel(
        name: "com.pk.atfix/credentials",
        binaryMessenger: messenger
      )
      credentialsChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "saveApiKey":
          guard let args = call.arguments as? [String: Any],
                let provider = args["provider"] as? String,
                let apiKey = args["apiKey"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing provider or apiKey", details: nil))
            return
          }
          let success = KeychainCredentialStore.shared.saveApiKey(provider: provider, apiKey: apiKey)
          NSLog("[CredentialsChannel] saveApiKey provider=\(provider) success=\(success)")
          result(success)

        case "getApiKey":
          guard let args = call.arguments as? [String: Any],
                let provider = args["provider"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing provider", details: nil))
            return
          }
          let key = KeychainCredentialStore.shared.readApiKey(provider: provider)
          NSLog("[CredentialsChannel] getApiKey provider=\(provider) found=\(key != nil)")
          result(key)

        case "deleteApiKey":
          guard let args = call.arguments as? [String: Any],
                let provider = args["provider"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing provider", details: nil))
            return
          }
          let success = KeychainCredentialStore.shared.deleteApiKey(provider: provider)
          NSLog("[CredentialsChannel] deleteApiKey provider=\(provider) success=\(success)")
          result(success)

        case "hasApiKey":
          guard let args = call.arguments as? [String: Any],
                let provider = args["provider"] as? String else {
            result(false)
            return
          }
          let hasKey = KeychainCredentialStore.shared.hasApiKey(provider: provider)
          NSLog("[CredentialsChannel] hasApiKey provider=\(provider) hasKey=\(hasKey)")
          result(hasKey)

        case "saveConfig":
          guard let args = call.arguments as? [String: Any],
                let provider = args["provider"] as? String,
                let modelId = args["modelId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing provider or modelId", details: nil))
            return
          }
          let baseUrl = args["baseUrl"] as? String
          ConfigurationStore.shared.saveConfig(provider: provider, modelId: modelId, baseUrl: baseUrl)
          NSLog("[CredentialsChannel] saveConfig provider=\(provider) modelId=\(modelId) customBaseUrl=\(baseUrl ?? "nil")")
          result(true)

        case "saveDisabledCommands":
          guard let args = call.arguments as? [String: Any],
                let list = args["disabledTriggers"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing disabledTriggers", details: nil))
            return
          }
          ConfigurationStore.shared.saveDisabledCommands(Set(list))
          NSLog("[CredentialsChannel] saveDisabledCommands count=\(list.count)")
          result(true)

        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let openAtLoginChannel = FlutterMethodChannel(
        name: "open_at_login",
        binaryMessenger: messenger
      )
      openAtLoginChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "isOpenAtLoginEnabled":
          let isEnabled = LaunchAtLogin.isEnabled
          NSLog("[AppDelegate] isOpenAtLoginEnabled: \(isEnabled)")
          result(isEnabled)

        case "setOpenAtLoginEnabled":
          guard let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool else {
            result(
              FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Expected 'enabled' as a Boolean.",
                details: nil
              )
            )
            return
          }
          LaunchAtLogin.isEnabled = enabled
          NSLog("[AppDelegate] setOpenAtLoginEnabled: \(enabled), verified isEnabled=\(LaunchAtLogin.isEnabled)")
          result(nil)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: mainFlutterWindow,
      queue: .main
    ) { [weak self] _ in
      NSLog("[AppDelegate] mainFlutterWindow willCloseNotification -> setDockIconVisible(false)")
      self?.setDockIconVisible(false)
    }

    let isBackground = CommandLine.arguments.contains("--background")
    if isBackground {
      NSLog("[AppDelegate] Starting in background mode (--background) — keeping main window hidden")
      mainFlutterWindow?.orderOut(nil)
      setDockIconVisible(false)
    } else {
      NSLog("[AppDelegate] Starting in normal UI mode — presenting main window")
      setDockIconVisible(true)
      mainFlutterWindow?.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      DispatchQueue.main.async { [weak self] in
        self?.setDockIconVisible(true)
        self?.mainFlutterWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  private func setDockIconVisible(_ visible: Bool) {
    NSLog("[AppDelegate] setDockIconVisible(\(visible))")
    NSApp.setActivationPolicy(visible ? .regular : .accessory)
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    NSLog("[AppDelegate] applicationShouldHandleReopen CALLED, hasVisibleWindows=\(flag)")
    setDockIconVisible(true)
    if !flag {
      mainFlutterWindow?.makeKeyAndOrderFront(nil)
    }
    NSApp.activate(ignoringOtherApps: true)
    return true
  }

  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    NSLog("[AppDelegate] applicationShouldTerminate CALLED, isRealQuitRequested=\(isRealQuitRequested)")
    if isRealQuitRequested {
      return .terminateNow
    }
    mainFlutterWindow?.orderOut(nil)
    setDockIconVisible(false)
    return .terminateCancel
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationWillTerminate(_ notification: Notification) {
    NSLog("[AppDelegate] applicationWillTerminate CALLED")
    CommandShortcutManager.shared.stop()
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    if CommandLine.arguments.contains("--background") {
      return false
    }
    return true
  }
}
