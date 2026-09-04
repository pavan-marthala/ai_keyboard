import 'package:freezed_annotation/freezed_annotation.dart';

part 'desktop_capability.freezed.dart';

enum DesktopCapabilityType {
  accessibility,
  inputMonitoring,
  windowsKeyboardIntegration,
  windowsTextAccess,
}

enum DesktopCapabilityStatus { enabled, required, notConfigured, unknown }

@freezed
abstract class DesktopCapability with _$DesktopCapability {
  const factory DesktopCapability({
    required DesktopCapabilityType type,
    required String title,
    required String description,
    required DesktopCapabilityStatus status,
    @Default(true) bool isRequired,
  }) = _DesktopCapability;
}
