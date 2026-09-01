import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    setupMethodChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func setupMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: SharedConstants.channelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "saveApiKey":
        guard let args = call.arguments as? [String: Any],
              let provider = args["provider"] as? String,
              let apiKey = args["apiKey"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing provider or apiKey", details: nil))
          return
        }
        let success = KeychainCredentialStore.shared.saveApiKey(provider: provider, apiKey: apiKey)
        result(success)

      case "getApiKey":
        guard let args = call.arguments as? [String: Any],
              let provider = args["provider"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing provider", details: nil))
          return
        }
        let key = KeychainCredentialStore.shared.readApiKey(provider: provider)
        result(key)

      case "deleteApiKey":
        guard let args = call.arguments as? [String: Any],
              let provider = args["provider"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing provider", details: nil))
          return
        }
        let success = KeychainCredentialStore.shared.deleteApiKey(provider: provider)
        result(success)

      case "hasApiKey":
        guard let args = call.arguments as? [String: Any],
              let provider = args["provider"] as? String else {
          result(false)
          return
        }
        let hasKey = KeychainCredentialStore.shared.hasApiKey(provider: provider)
        result(hasKey)

      case "saveConfig":
        guard let args = call.arguments as? [String: Any],
              let provider = args["provider"] as? String,
              let modelId = args["modelId"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing provider or modelId", details: nil))
          return
        }
        let baseUrl = args["baseUrl"] as? String
        SharedConfigurationStore.shared.saveConfig(provider: provider, modelId: modelId, baseUrl: baseUrl)
        result(true)

      case "saveDisabledCommands":
        guard let args = call.arguments as? [String: Any],
              let list = args["disabledTriggers"] as? [String] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing disabledTriggers", details: nil))
          return
        }
        SharedConfigurationStore.shared.saveDisabledCommands(Set(list))
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
