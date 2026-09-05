import 'package:atfix/features/desktop_onboarding/data/datasources/desktop_platform_channel_datasource.dart';
import 'package:atfix/features/desktop_onboarding/data/repositories/desktop_capability_repository_impl.dart';
import 'package:atfix/features/desktop_onboarding/domain/entities/desktop_capability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDesktopPlatformChannelDataSource
    extends DesktopPlatformChannelDataSource {
  bool mockAccessibility = false;
  DesktopCapabilityStatus mockInputMonitoringStatus =
      DesktopCapabilityStatus.required;
  bool requestedAccessibility = false;
  bool openedAccessibilitySettings = false;
  bool openedInputMonitoringSettings = false;

  @override
  Future<bool> isAccessibilityGranted() async => mockAccessibility;

  @override
  Future<DesktopCapabilityStatus> getInputMonitoringStatus() async =>
      mockInputMonitoringStatus;

  @override
  Future<bool> isInputMonitoringGranted() async =>
      mockInputMonitoringStatus == DesktopCapabilityStatus.enabled;

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

    test('getCapabilities returns decoupled independent statuses', () async {
      // Scenario A: Accessibility enabled only
      dataSource.mockAccessibility = true;
      dataSource.mockInputMonitoringStatus = DesktopCapabilityStatus.required;

      var capabilities = await repository.getCapabilities();
      var accessibility = capabilities.firstWhere(
        (c) => c.type == DesktopCapabilityType.accessibility,
      );
      var inputMonitoring = capabilities.firstWhere(
        (c) => c.type == DesktopCapabilityType.inputMonitoring,
      );

      expect(accessibility.status, equals(DesktopCapabilityStatus.enabled));
      expect(inputMonitoring.status, equals(DesktopCapabilityStatus.required));

      // Scenario B: Input Monitoring enabled only
      dataSource.mockAccessibility = false;
      dataSource.mockInputMonitoringStatus = DesktopCapabilityStatus.enabled;

      capabilities = await repository.getCapabilities();
      accessibility = capabilities.firstWhere(
        (c) => c.type == DesktopCapabilityType.accessibility,
      );
      inputMonitoring = capabilities.firstWhere(
        (c) => c.type == DesktopCapabilityType.inputMonitoring,
      );

      expect(accessibility.status, equals(DesktopCapabilityStatus.required));
      expect(inputMonitoring.status, equals(DesktopCapabilityStatus.enabled));

      // Scenario C: Both enabled
      dataSource.mockAccessibility = true;
      dataSource.mockInputMonitoringStatus = DesktopCapabilityStatus.enabled;

      capabilities = await repository.getCapabilities();
      accessibility = capabilities.firstWhere(
        (c) => c.type == DesktopCapabilityType.accessibility,
      );
      inputMonitoring = capabilities.firstWhere(
        (c) => c.type == DesktopCapabilityType.inputMonitoring,
      );

      expect(accessibility.status, equals(DesktopCapabilityStatus.enabled));
      expect(inputMonitoring.status, equals(DesktopCapabilityStatus.enabled));

      // Scenario D: Input Monitoring unknown
      dataSource.mockAccessibility = true;
      dataSource.mockInputMonitoringStatus = DesktopCapabilityStatus.unknown;

      capabilities = await repository.getCapabilities();
      accessibility = capabilities.firstWhere(
        (c) => c.type == DesktopCapabilityType.accessibility,
      );
      inputMonitoring = capabilities.firstWhere(
        (c) => c.type == DesktopCapabilityType.inputMonitoring,
      );

      expect(accessibility.status, equals(DesktopCapabilityStatus.enabled));
      expect(inputMonitoring.status, equals(DesktopCapabilityStatus.unknown));
    });

    test('state separation: onboarding completed does not override capability status', () async {
      // Case 1: isOnboardingCompleted = false, but capabilities are enabled
      await repository.setOnboardingCompleted(false);
      dataSource.mockAccessibility = true;
      dataSource.mockInputMonitoringStatus = DesktopCapabilityStatus.enabled;

      expect(repository.isOnboardingCompleted(), isFalse);
      var capabilities = await repository.getCapabilities();
      expect(
        capabilities
            .firstWhere((c) => c.type == DesktopCapabilityType.accessibility)
            .status,
        equals(DesktopCapabilityStatus.enabled),
      );
      expect(
        capabilities
            .firstWhere((c) => c.type == DesktopCapabilityType.inputMonitoring)
            .status,
        equals(DesktopCapabilityStatus.enabled),
      );

      // Case 2: isOnboardingCompleted = true, but accessibility revoked
      await repository.setOnboardingCompleted(true);
      dataSource.mockAccessibility = false;
      dataSource.mockInputMonitoringStatus = DesktopCapabilityStatus.enabled;

      expect(repository.isOnboardingCompleted(), isTrue);
      capabilities = await repository.getCapabilities();
      expect(
        capabilities
            .firstWhere((c) => c.type == DesktopCapabilityType.accessibility)
            .status,
        equals(DesktopCapabilityStatus.required),
      );
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
