/// Abstract base class for platform-specific launch-at-login implementations.
///
/// Subclasses implement the platform-specific mechanisms (e.g. macOS
/// `LaunchAtLogin-Modern` / `SMAppService`, Windows Registry, etc.).
abstract class AppLauncher {
  /// Creates an [AppLauncher] instance.
  ///
  /// - [appName]: The display or executable name of the application.
  /// - [appPath]: The absolute path to the application bundle or binary.
  /// - [args]: Optional command-line arguments passed to the application on startup.
  const AppLauncher({
    required this.appName,
    required this.appPath,
    this.args = const [],
  });

  /// The name of the application.
  final String appName;

  /// The file path to the application executable or bundle.
  final String appPath;

  /// Optional command-line arguments passed when the application starts at login.
  final List<String> args;

  /// Checks whether the application is currently configured to open at login.
  ///
  /// Returns `true` if enabled, `false` otherwise.
  Future<bool> isEnabled();

  /// Enables or disables launching the application at login.
  ///
  /// - [enabled]: `true` to enable launch-at-login, `false` to disable.
  Future<void> setEnabled(bool enabled);
}
