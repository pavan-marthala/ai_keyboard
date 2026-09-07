import Cocoa
import FlutterMacOS
import LaunchAtLogin

@main
class AppDelegate: FlutterAppDelegate {

  override func applicationDidFinishLaunching(_ notification: Notification) {
  guard let controller = mainFlutterWindow?.contentViewController
            as? FlutterViewController else {
            return
        }
  let channel = FlutterMethodChannel(
            name: "open_at_login",
            binaryMessenger: controller.engine.binaryMessenger
        )

        channel.setMethodCallHandler { call, result in

            switch call.method {

            case "isOpenAtLoginEnabled":
                result(LaunchAtLogin.isEnabled)

            case "setOpenAtLoginEnabled":

                guard let arguments = call.arguments as? [String: Any],
                      let enabled = arguments["enabled"] as? Bool else {

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

                result(nil)

            default:
                result(FlutterMethodNotImplemented)
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
