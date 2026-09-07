import 'dart:io' show Platform;

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) {
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
  return "$twoDigitMinutes:$twoDigitSeconds";
}

/// Dynamically resolves the running application bundle path (`.app` on macOS).
///
/// Uses the actual running `.app` bundle from [Platform.resolvedExecutable],
/// or falls back to `/Applications/<appName>.app`.
String resolveApplicationPath({String? appName}) {
  try {
    final executablePath = Platform.resolvedExecutable;
    final appIndex = executablePath.indexOf('.app');
    if (appIndex != -1) {
      return executablePath.substring(0, appIndex + 4);
    }
  } catch (_) {}

  if (appName != null && appName.isNotEmpty) {
    return '/Applications/$appName.app';
  }
  return Platform.resolvedExecutable;
}
