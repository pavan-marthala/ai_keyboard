import 'package:atfix/core/di/injection.dart';
import 'package:atfix/core/theme/app_theme.dart';
import 'package:atfix/features/desktop_onboarding/domain/entities/desktop_capability.dart';
import 'package:atfix/features/desktop_onboarding/domain/repositories/desktop_capability_repository.dart';
import 'package:atfix/features/desktop_onboarding/presentation/bloc/desktop_onboarding_bloc.dart';
import 'package:atfix/features/desktop_onboarding/presentation/pages/desktop_onboarding_page.dart';
import 'package:atfix/features/shortcuts/domain/entities/desktop_shortcut.dart';
import 'package:atfix/features/shortcuts/domain/repositories/desktop_shortcut_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

class TestDesktopCapabilityRepository implements DesktopCapabilityRepository {
  bool completed = false;
  List<DesktopCapability> capabilities = const [
    DesktopCapability(
      type: DesktopCapabilityType.accessibility,
      title: 'Accessibility',
      description: 'Test accessibility description',
      status: DesktopCapabilityStatus.required,
    ),
    DesktopCapability(
      type: DesktopCapabilityType.inputMonitoring,
      title: 'Keyboard Input Monitoring',
      description: 'Test input monitoring description',
      status: DesktopCapabilityStatus.required,
    ),
  ];
  DesktopCapabilityType? openedSettingsType;

  @override
  Future<List<DesktopCapability>> getCapabilities() async => capabilities;

  @override
  Future<bool> requestCapability(DesktopCapabilityType type) async => true;

  @override
  Future<void> openSystemSettings(DesktopCapabilityType type) async {
    openedSettingsType = type;
  }

  @override
  bool isOnboardingCompleted() => completed;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    this.completed = completed;
  }
}

class TestDesktopShortcutRepository implements DesktopShortcutRepository {
  DesktopShortcut shortcut = DesktopShortcut.macOsDefault;
  bool shouldSucceed = true;

  @override
  Future<DesktopShortcut> getShortcut() async => shortcut;

  @override
  Future<bool> registerAndSaveShortcut(DesktopShortcut s) async {
    if (shouldSucceed) {
      shortcut = s;
      return true;
    }
    return false;
  }

  @override
  Future<bool> registerShortcut(DesktopShortcut s) async => shouldSucceed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestDesktopCapabilityRepository repo;
  late TestDesktopShortcutRepository shortcutRepo;

  setUp(() {
    if (getIt.isRegistered<DesktopCapabilityRepository>()) {
      getIt.unregister<DesktopCapabilityRepository>();
    }
    if (getIt.isRegistered<DesktopShortcutRepository>()) {
      getIt.unregister<DesktopShortcutRepository>();
    }
    if (getIt.isRegistered<DesktopOnboardingBloc>()) {
      getIt.unregister<DesktopOnboardingBloc>();
    }

    repo = TestDesktopCapabilityRepository();
    shortcutRepo = TestDesktopShortcutRepository();
    getIt.registerSingleton<DesktopCapabilityRepository>(repo);
    getIt.registerSingleton<DesktopShortcutRepository>(shortcutRepo);
    getIt.registerFactory<DesktopOnboardingBloc>(
      () => DesktopOnboardingBloc(repo),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<DesktopCapabilityRepository>()) {
      getIt.unregister<DesktopCapabilityRepository>();
    }
    if (getIt.isRegistered<DesktopShortcutRepository>()) {
      getIt.unregister<DesktopShortcutRepository>();
    }
    if (getIt.isRegistered<DesktopOnboardingBloc>()) {
      getIt.unregister<DesktopOnboardingBloc>();
    }
  });

  testWidgets('DesktopOnboardingPage renders 3-page flow with shortcut page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const DesktopOnboardingPage()),
    );

    await tester.pumpAndSettle();

    // Verify Page 0 (Intro)
    expect(find.text('AtFix'), findsOneWidget);
    expect(find.text('AI assistance wherever you type'), findsOneWidget);
    expect(find.text('Supported Commands'), findsOneWidget);
    expect(find.text('@fix'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue to navigate to Page 1 (Hotkey)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Page 1 elements (Hotkey)
    expect(find.text('Set Global Shortcut'), findsOneWidget);
    expect(find.text('Reset to default'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // Tap Continue on Page 1 to navigate to Page 2 (Permissions)
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Page 2 elements (Permissions)
    expect(find.text('Enable Desktop Access'), findsOneWidget);
    expect(find.text('Accessibility'), findsOneWidget);
    expect(find.text('Keyboard Input Monitoring'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // Verify redundant Enable Access button is NOT present
    expect(find.text('Enable Access'), findsNothing);

    // Verify Open Settings buttons are present
    expect(find.text('Open Settings'), findsNWidgets(2));

    // Tap Open Settings for the first capability
    await tester.tap(find.text('Open Settings').first);
    await tester.pumpAndSettle();
    expect(
      repo.openedSettingsType,
      equals(DesktopCapabilityType.accessibility),
    );

    // Tap Back to return to Page 1 (Hotkey)
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Set Global Shortcut'), findsOneWidget);

    // Tap Back to return to Page 0 (Intro)
    await tester.ensureVisible(find.text('Back'));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('AtFix'), findsOneWidget);
    expect(find.text('Supported Commands'), findsOneWidget);
  });

  testWidgets(
    'DesktopOnboardingPage handles unknown Input Monitoring status correctly',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      repo.capabilities = const [
        DesktopCapability(
          type: DesktopCapabilityType.accessibility,
          title: 'Accessibility',
          description: 'Test accessibility description',
          status: DesktopCapabilityStatus.enabled,
        ),
        DesktopCapability(
          type: DesktopCapabilityType.inputMonitoring,
          title: 'Keyboard Input Monitoring',
          description: 'Test input monitoring description',
          status: DesktopCapabilityStatus.unknown,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const DesktopOnboardingPage()),
      );
      await tester.pumpAndSettle();

      // Navigate from Page 0 to Page 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Navigate from Page 1 to Page 2
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Accessibility is enabled
      expect(find.text('Enabled'), findsOneWidget);

      // Input Monitoring is unknown: shows badge and explanatory text
      expect(find.text('Verify in Settings'), findsOneWidget);
      expect(
        find.text(
          'Status cannot be verified automatically. Verify or enable this permission in System Settings.',
        ),
        findsOneWidget,
      );

      // Only 1 Open Settings button should appear (for Input Monitoring)
      expect(find.text('Open Settings'), findsOneWidget);

      // No Enable Access button
      expect(find.text('Enable Access'), findsNothing);
    },
  );
}

