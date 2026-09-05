import 'package:ai_keyboard/core/di/injection.dart';
import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:ai_keyboard/features/desktop_onboarding/domain/entities/desktop_capability.dart';
import 'package:ai_keyboard/features/desktop_onboarding/domain/repositories/desktop_capability_repository.dart';
import 'package:ai_keyboard/features/playground/data/services/keyboard_status_service.dart';
import 'package:ai_keyboard/features/playground/presentation/pages/keyboard_playground_page.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockKeyboardStatusService extends KeyboardStatusService {
  bool active = false;
  bool openedSettings = false;

  @override
  Future<bool> isAtFIxActive() async => active;

  @override
  Future<void> openKeyboardSettings() async {
    openedSettings = true;
  }
}

class MockDesktopCapabilityRepository implements DesktopCapabilityRepository {
  List<DesktopCapability> capabilities = [];
  bool completed = false;
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

Widget createTestWidget() {
  return MaterialApp(
    theme: AppTheme.dark,
    home: BlocProvider(
      create: (_) =>
          getIt<SettingsBloc>()..add(const SettingsEvent.loadSettings()),
      child: const KeyboardPlaygroundPage(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockKeyboardStatusService mockKeyboardService;
  late MockDesktopCapabilityRepository mockDesktopRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();

    mockKeyboardService = MockKeyboardStatusService();
    mockDesktopRepo = MockDesktopCapabilityRepository();

    if (getIt.isRegistered<KeyboardStatusService>()) {
      await getIt.unregister<KeyboardStatusService>();
    }
    if (getIt.isRegistered<DesktopCapabilityRepository>()) {
      await getIt.unregister<DesktopCapabilityRepository>();
    }

    getIt.registerSingleton<KeyboardStatusService>(mockKeyboardService);
    getIt.registerSingleton<DesktopCapabilityRepository>(mockDesktopRepo);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await getIt.reset();
  });

  group('KeyboardPlaygroundPage Desktop Permission Recovery', () {
    testWidgets(
      'Mobile: displays Android settings card when keyboard not active',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          mockKeyboardService.active = false;

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('AtFIx Not Active'), findsOneWidget);
          expect(
            find.text(
              'Enable and select AtFIx in Android System Settings to test transformation.',
            ),
            findsOneWidget,
          );
          expect(find.text('Select AtFIx'), findsOneWidget);

          await tester.tap(find.text('Select AtFIx'));
          await tester.pumpAndSettle();
          expect(mockKeyboardService.openedSettings, isTrue);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Desktop: displays active state when all required permissions are enabled',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          mockDesktopRepo.capabilities = const [
            DesktopCapability(
              type: DesktopCapabilityType.accessibility,
              title: 'Accessibility',
              description: 'Allows AtFIx to interact with text fields.',
              status: DesktopCapabilityStatus.enabled,
            ),
            DesktopCapability(
              type: DesktopCapabilityType.inputMonitoring,
              title: 'Keyboard Input Monitoring',
              description: 'Allows AtFIx to detect trailing commands.',
              status: DesktopCapabilityStatus.enabled,
            ),
          ];

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('AtFIx Active'), findsOneWidget);
          expect(
            find.text(
              'AtFIx has the necessary system permissions to detect commands and transform text.',
            ),
            findsOneWidget,
          );
          // No recovery buttons should appear
          expect(find.text('Open Settings'), findsNothing);
          expect(find.text('Select AtFIx'), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Desktop: displays missing Accessibility with Open Settings action',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          mockDesktopRepo.capabilities = const [
            DesktopCapability(
              type: DesktopCapabilityType.accessibility,
              title: 'Accessibility',
              description: 'Allows AtFIx to interact with text fields.',
              status: DesktopCapabilityStatus.required,
            ),
            DesktopCapability(
              type: DesktopCapabilityType.inputMonitoring,
              title: 'Keyboard Input Monitoring',
              description: 'Allows AtFIx to detect trailing commands.',
              status: DesktopCapabilityStatus.enabled,
            ),
          ];

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('AtFIx Not Active'), findsOneWidget);
          expect(
            find.text(
              'AtFIx requires system permissions to detect commands and interact with active text fields.',
            ),
            findsOneWidget,
          );
          expect(find.text('Accessibility'), findsOneWidget);
          expect(find.text('Required'), findsOneWidget);
          expect(find.text('Open Settings'), findsOneWidget);

          // Verify clicking Open Settings routes to Accessibility
          await tester.tap(find.text('Open Settings'));
          await tester.pumpAndSettle();
          expect(
            mockDesktopRepo.openedSettingsType,
            equals(DesktopCapabilityType.accessibility),
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Desktop: displays unknown Input Monitoring with Verify in Settings action',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          mockDesktopRepo.capabilities = const [
            DesktopCapability(
              type: DesktopCapabilityType.accessibility,
              title: 'Accessibility',
              description: 'Allows AtFIx to interact with text fields.',
              status: DesktopCapabilityStatus.enabled,
            ),
            DesktopCapability(
              type: DesktopCapabilityType.inputMonitoring,
              title: 'Keyboard Input Monitoring',
              description: 'Allows AtFIx to detect trailing commands.',
              status: DesktopCapabilityStatus.unknown,
            ),
          ];

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('AtFIx Not Active'), findsOneWidget);
          expect(find.text('Keyboard Input Monitoring'), findsOneWidget);
          expect(find.text('Verify in Settings'), findsOneWidget);
          expect(
            find.text(
              'Status cannot be verified automatically. Verify or enable this permission in System Settings.',
            ),
            findsOneWidget,
          );
          expect(find.text('Open Settings'), findsOneWidget);

          await tester.tap(find.text('Open Settings'));
          await tester.pumpAndSettle();
          expect(
            mockDesktopRepo.openedSettingsType,
            equals(DesktopCapabilityType.inputMonitoring),
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Desktop: resumes app lifecycle and refreshes permissions state',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          // Start with Accessibility required
          mockDesktopRepo.capabilities = const [
            DesktopCapability(
              type: DesktopCapabilityType.accessibility,
              title: 'Accessibility',
              description: 'Allows AtFIx to interact with text fields.',
              status: DesktopCapabilityStatus.required,
            ),
            DesktopCapability(
              type: DesktopCapabilityType.inputMonitoring,
              title: 'Keyboard Input Monitoring',
              description: 'Allows AtFIx to detect trailing commands.',
              status: DesktopCapabilityStatus.enabled,
            ),
          ];

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
          expect(find.text('AtFIx Not Active'), findsOneWidget);

          // Simulate user granted Accessibility in System Settings
          mockDesktopRepo.capabilities = const [
            DesktopCapability(
              type: DesktopCapabilityType.accessibility,
              title: 'Accessibility',
              description: 'Allows AtFIx to interact with text fields.',
              status: DesktopCapabilityStatus.enabled,
            ),
            DesktopCapability(
              type: DesktopCapabilityType.inputMonitoring,
              title: 'Keyboard Input Monitoring',
              description: 'Allows AtFIx to detect trailing commands.',
              status: DesktopCapabilityStatus.enabled,
            ),
          ];

          // Simulate returning to app
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();

          // Card automatically transitions to Active!
          expect(find.text('AtFIx Active'), findsOneWidget);
          expect(find.text('Open Settings'), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Desktop: completed onboarding does not hide missing permissions',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          mockDesktopRepo.completed = true; // Onboarding was completed
          mockDesktopRepo.capabilities = const [
            DesktopCapability(
              type: DesktopCapabilityType.accessibility,
              title: 'Accessibility',
              description: 'Allows AtFIx to interact with text fields.',
              status: DesktopCapabilityStatus.required, // Revoked!
            ),
            DesktopCapability(
              type: DesktopCapabilityType.inputMonitoring,
              title: 'Keyboard Input Monitoring',
              description: 'Allows AtFIx to detect trailing commands.',
              status: DesktopCapabilityStatus.enabled,
            ),
          ];

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          // Missing permission must NOT be hidden
          expect(find.text('AtFIx Not Active'), findsOneWidget);
          expect(find.text('Accessibility'), findsOneWidget);
          expect(find.text('Required'), findsOneWidget);
          expect(find.text('Open Settings'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
