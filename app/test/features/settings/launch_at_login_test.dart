import 'package:atfix/core/di/injection.dart';
import 'package:atfix/core/theme/app_theme.dart';
import 'package:atfix/features/commands/presentation/bloc/command_bloc.dart';
import 'package:atfix/features/commands/presentation/bloc/command_event.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_event.dart';
import 'package:atfix/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:atfix/core/utils/app_buitton.dart';
import 'package:atfix/core/utils/app_routes.dart';
import 'package:atfix/features/desktop_onboarding/presentation/pages/desktop_onboarding_page.dart';
import 'package:go_router/go_router.dart';
import 'package:open_at_login/open_at_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('open_at_login');

  testWidgets(
    'SettingsPage displays Launch AtFix at Login switch and toggles state',
    (WidgetTester tester) async {
      final List<MethodCall> log = <MethodCall>[];
      bool isEnabled = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'isOpenAtLoginEnabled') {
              return isEnabled;
            } else if (methodCall.method == 'setOpenAtLoginEnabled') {
              final args = methodCall.arguments as Map<dynamic, dynamic>;
              isEnabled = args['enabled'] as bool;
              return null;
            }
            return null;
          });

      SharedPreferences.setMockInitialValues({});
      await getIt.reset();
      await configureDependencies();

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      OpenAtLogin.instance.initialize(
        appName: 'AtFix',
        appPath: '/Applications/AtFix.app',
        args: const ['--background'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    getIt<SettingsBloc>()
                      ..add(const SettingsEvent.loadSettings()),
              ),
              BlocProvider(
                create: (_) =>
                    getIt<CommandBloc>()
                      ..add(const CommandEvent.loadCommands()),
              ),
            ],
            child: const SettingsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify "Launch AtFix at Login" switch is present
      final switchFinder = find.widgetWithText(
        SwitchListTile,
        'Launch AtFix at Login',
      );
      expect(switchFinder, findsOneWidget);

      // Initial state is false
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, isFalse);

      // Tap to enable
      await tester.tap(switchFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        log.any(
          (call) =>
              call.method == 'setOpenAtLoginEnabled' &&
              call.arguments['enabled'] == true,
        ),
        isTrue,
      );

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await getIt.reset();
    },
  );

  testWidgets(
    'DesktopOnboardingPage displays launch-at-login checkbox checked by default and applies upon completion',
    (WidgetTester tester) async {
      final List<MethodCall> log = <MethodCall>[];
      bool isEnabled = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'isOpenAtLoginEnabled') {
              return isEnabled;
            } else if (methodCall.method == 'setOpenAtLoginEnabled') {
              final args = methodCall.arguments as Map<dynamic, dynamic>;
              isEnabled = args['enabled'] as bool;
              return null;
            }
            return null;
          });

      SharedPreferences.setMockInitialValues({});
      await getIt.reset();
      await configureDependencies();

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      OpenAtLogin.instance.initialize(
        appName: 'AtFix',
        appPath: 'C:\\Program Files\\AtFix\\AtFix.exe',
        args: const ['--background'],
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DesktopOnboardingPage(),
          ),
          GoRoute(
            path: AppRoutes.playground,
            builder: (context, state) => const SizedBox(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Verify checkbox is present and checked by default
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      final checkboxWidget = tester.widget<Checkbox>(checkboxFinder);
      expect(checkboxWidget.value, isTrue);

      // Verify no method call was made yet to setOpenAtLoginEnabled
      expect(
        log.any((call) => call.method == 'setOpenAtLoginEnabled'),
        isFalse,
      );

      // Click "Get Started" on Windows to complete onboarding
      final getStartedButton = find.widgetWithText(AppButton, 'Get Started');
      expect(getStartedButton, findsOneWidget);
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      // Verify setOpenAtLoginEnabled was called with true
      final calls = log.where((call) => call.method == 'setOpenAtLoginEnabled').toList();
      expect(calls.length, equals(1));
      expect(calls.first.arguments['enabled'], isTrue);

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await getIt.reset();
    },
  );

  testWidgets(
    'DesktopOnboardingPage unchecking launch-at-login applies false upon completion',
    (WidgetTester tester) async {
      final List<MethodCall> log = <MethodCall>[];
      bool isEnabled = true;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'isOpenAtLoginEnabled') {
              return isEnabled;
            } else if (methodCall.method == 'setOpenAtLoginEnabled') {
              final args = methodCall.arguments as Map<dynamic, dynamic>;
              isEnabled = args['enabled'] as bool;
              return null;
            }
            return null;
          });

      SharedPreferences.setMockInitialValues({});
      await getIt.reset();
      await configureDependencies();

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      OpenAtLogin.instance.initialize(
        appName: 'AtFix',
        appPath: 'C:\\Program Files\\AtFix\\AtFix.exe',
        args: const ['--background'],
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DesktopOnboardingPage(),
          ),
          GoRoute(
            path: AppRoutes.playground,
            builder: (context, state) => const SizedBox(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Checkbox is checked
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);

      // Uncheck it
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
      // Still no method call while just toggling
      expect(
        log.any((call) => call.method == 'setOpenAtLoginEnabled'),
        isFalse,
      );

      // Complete onboarding
      final getStartedButton = find.widgetWithText(AppButton, 'Get Started');
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      // Verify setOpenAtLoginEnabled called with false
      final calls = log.where((call) => call.method == 'setOpenAtLoginEnabled').toList();
      expect(calls.length, equals(1));
      expect(calls.first.arguments['enabled'], isFalse);

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await getIt.reset();
    },
  );

  testWidgets(
    'DesktopOnboardingPage does NOT display launch-at-login checkbox on Android',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await getIt.reset();
      await configureDependencies();

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const DesktopOnboardingPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Launch AtFix at login'), findsNothing);

      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await getIt.reset();
    },
  );
}
