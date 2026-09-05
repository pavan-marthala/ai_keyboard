import Cocoa
import FlutterMacOS
import ApplicationServices

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
  override func applicationDidFinishLaunching(_ notification: Notification) {

    NSLog("[AppDelegate] applicationDidFinishLaunching CALLED")
    NSLog("[AppDelegate] Starting CommandShortcutManager")
    CommandShortcutManager.shared.start()
    let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    if let messenger = controller?.engine.binaryMessenger {
      let channel = FlutterMethodChannel(
        name: "com.pk.ai_keyboard/desktop",
        binaryMessenger: messenger
      )
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
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
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let credentialsChannel = FlutterMethodChannel(
        name: "com.pk.ai_keyboard/credentials",
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
    }
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
