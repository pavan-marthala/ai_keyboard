import 'package:ai_keyboard/core/di/injection.dart';
import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:ai_keyboard/features/desktop_onboarding/domain/entities/desktop_capability.dart';
import 'package:ai_keyboard/features/desktop_onboarding/domain/repositories/desktop_capability_repository.dart';
import 'package:ai_keyboard/features/desktop_onboarding/presentation/bloc/desktop_onboarding_bloc.dart';
import 'package:ai_keyboard/features/desktop_onboarding/presentation/pages/desktop_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestDesktopCapabilityRepository implements DesktopCapabilityRepository {
  bool completed = false;

  @override
  Future<List<DesktopCapability>> getCapabilities() async {
    return const [
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
  }

  @override
  Future<bool> requestCapability(DesktopCapabilityType type) async => true;

  @override
  Future<void> openSystemSettings(DesktopCapabilityType type) async {}

  @override
  bool isOnboardingCompleted() => completed;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    this.completed = completed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    if (getIt.isRegistered<DesktopCapabilityRepository>()) {
      getIt.unregister<DesktopCapabilityRepository>();
    }
    if (getIt.isRegistered<DesktopOnboardingBloc>()) {
      getIt.unregister<DesktopOnboardingBloc>();
    }

    final repo = TestDesktopCapabilityRepository();
    getIt.registerSingleton<DesktopCapabilityRepository>(repo);
    getIt.registerFactory<DesktopOnboardingBloc>(
      () => DesktopOnboardingBloc(repo),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<DesktopCapabilityRepository>()) {
      getIt.unregister<DesktopCapabilityRepository>();
    }
    if (getIt.isRegistered<DesktopOnboardingBloc>()) {
      getIt.unregister<DesktopOnboardingBloc>();
    }
  });

  testWidgets('DesktopOnboardingPage renders Page 1 and navigates to Page 2', (
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

    // Verify Page 1 elements
    expect(find.text('AI Keyboard'), findsOneWidget);
    expect(find.text('AI assistance wherever you type'), findsOneWidget);
    expect(find.text('Supported Commands'), findsOneWidget);
    expect(find.text('@fix'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue to navigate to Page 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Page 2 elements
    expect(find.text('Enable Desktop Access'), findsOneWidget);
    expect(find.text('Accessibility'), findsOneWidget);
    expect(find.text('Keyboard Input Monitoring'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // Tap Back to return to Page 1
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('AI Keyboard'), findsOneWidget);
    expect(find.text('Supported Commands'), findsOneWidget);
  });
}
