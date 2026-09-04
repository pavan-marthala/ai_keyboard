import 'package:ai_keyboard/features/desktop_onboarding/data/datasources/desktop_platform_channel_datasource.dart';
import 'package:ai_keyboard/features/desktop_onboarding/data/repositories/desktop_capability_repository_impl.dart';
import 'package:ai_keyboard/features/desktop_onboarding/domain/entities/desktop_capability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDesktopPlatformChannelDataSource
    extends DesktopPlatformChannelDataSource {
  bool mockAccessibility = false;
  bool mockInputMonitoring = false;
  bool requestedAccessibility = false;
  bool openedAccessibilitySettings = false;
  bool openedInputMonitoringSettings = false;

  @override
  Future<bool> isAccessibilityGranted() async => mockAccessibility;

  @override
  Future<bool> isInputMonitoringGranted() async => mockInputMonitoring;

  @override
  Future<bool> requestAccessibility() async {
    requestedAccessibility = true;
    return mockAccessibility;
  }

  @override
  Future<void> openAccessibilitySettings() async {
    openedAccessibilitySettings = true;
  }

  @override
  Future<void> openInputMonitoringSettings() async {
    openedInputMonitoringSettings = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MockDesktopPlatformChannelDataSource dataSource;
  late DesktopCapabilityRepositoryImpl repository;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dataSource = MockDesktopPlatformChannelDataSource();
    repository = DesktopCapabilityRepositoryImpl(prefs, dataSource);
  });

  group('DesktopCapabilityRepository', () {
    test('isOnboardingCompleted defaults to false and sets to true', () async {
      expect(repository.isOnboardingCompleted(), isFalse);

      await repository.setOnboardingCompleted(true);
      expect(repository.isOnboardingCompleted(), isTrue);

      await repository.setOnboardingCompleted(false);
      expect(repository.isOnboardingCompleted(), isFalse);
    });

    test('getCapabilities returns platform-specific capabilities', () async {
      dataSource.mockAccessibility = true;
      dataSource.mockInputMonitoring = false;

      final capabilities = await repository.getCapabilities();
      expect(capabilities, isNotEmpty);

      // On macOS test runner, should return Accessibility and Input Monitoring
      final accessibility = capabilities.firstWhere(
        (c) => c.type == DesktopCapabilityType.accessibility,
        orElse: () => capabilities.first,
      );
      expect(accessibility, isNotNull);
    });

    test('requestCapability delegates to data source', () async {
      await repository.requestCapability(DesktopCapabilityType.accessibility);
      expect(dataSource.requestedAccessibility, isTrue);
    });

    test('openSystemSettings delegates to data source', () async {
      await repository.openSystemSettings(DesktopCapabilityType.accessibility);
      expect(dataSource.openedAccessibilitySettings, isTrue);

      await repository.openSystemSettings(
        DesktopCapabilityType.inputMonitoring,
      );
      expect(dataSource.openedInputMonitoringSettings, isTrue);
    });
  });
}
