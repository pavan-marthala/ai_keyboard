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
    DesktopCommandPrototype.shared.start()
    let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
    let bundlePath = Bundle.main.bundlePath
    let processName = ProcessInfo.processInfo.processName
    let pid = ProcessInfo.processInfo.processIdentifier
    debugLog("[NATIVE IDENTITY] bundleId=\(bundleId), bundlePath=\(bundlePath), processName=\(processName), pid=\(pid)")

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
