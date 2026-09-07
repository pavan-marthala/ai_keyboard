import 'package:atfix/core/utils/check_platforms.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/desktop_capability.dart';
import '../../domain/repositories/desktop_capability_repository.dart';
import '../datasources/desktop_platform_channel_datasource.dart';

@LazySingleton(as: DesktopCapabilityRepository)
class DesktopCapabilityRepositoryImpl implements DesktopCapabilityRepository {
  static const String _onboardingCompletedKey = 'desktop_onboarding_completed';

  final SharedPreferences _prefs;
  final DesktopPlatformChannelDataSource _dataSource;

  DesktopCapabilityRepositoryImpl(this._prefs, this._dataSource);

  @override
  Future<List<DesktopCapability>> getCapabilities() async {
    if (PlatformChecker.isMacOS()) {
      final isAccessibility = await _dataSource.isAccessibilityGranted();
      final inputMonitoringStatus = await _dataSource
          .getInputMonitoringStatus();

      final accessibilityStatus = isAccessibility
          ? DesktopCapabilityStatus.enabled
          : DesktopCapabilityStatus.required;

      return [
        DesktopCapability(
          type: DesktopCapabilityType.accessibility,
          title: 'Accessibility',
          description: 'Allows AtFix to interact with active application text fields and insert transformed text.',
          status: accessibilityStatus,
          isRequired: true,
        ),
        DesktopCapability(
          type: DesktopCapabilityType.inputMonitoring,
          title: 'Keyboard Input Monitoring',
          description: 'Allows AtFix to detect trailing commands (such as @fix) directly as you type.',
          status: inputMonitoringStatus,
          isRequired: true,
        ),
      ];
    } else if (PlatformChecker.isWindows()) {
      // Windows requires zero OS permissions (no Accessibility or Input Monitoring TCC gates)
      return const [];
    }

    return [];
  }

  @override
  Future<bool> requestCapability(DesktopCapabilityType type) async {
    switch (type) {
      case DesktopCapabilityType.accessibility:
        return _dataSource.requestAccessibility();
      case DesktopCapabilityType.inputMonitoring:
        await _dataSource.openInputMonitoringSettings();
        return false;
      case DesktopCapabilityType.windowsKeyboardIntegration:
      case DesktopCapabilityType.windowsTextAccess:
        return false;
    }
  }

  @override
  Future<void> openSystemSettings(DesktopCapabilityType type) async {
    switch (type) {
      case DesktopCapabilityType.accessibility:
        await _dataSource.openAccessibilitySettings();
        break;
      case DesktopCapabilityType.inputMonitoring:
        await _dataSource.openInputMonitoringSettings();
        break;
      case DesktopCapabilityType.windowsKeyboardIntegration:
      case DesktopCapabilityType.windowsTextAccess:
        break;
    }
  }

  @override
  bool isOnboardingCompleted() {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingCompletedKey, completed);
  }
}
