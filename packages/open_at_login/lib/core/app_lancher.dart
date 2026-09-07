class AppLauncher {
  AppLauncher({
    required this.appName,
    required this.appPath,
    this.args = const [],
  });

  final String appName;
  final String appPath;
  final List<String> args;

  Future<bool> isEnabled() {
    throw UnimplementedError();
  }

  Future<void> setEnabled(bool enabled) {
    throw UnimplementedError();
  }
}
