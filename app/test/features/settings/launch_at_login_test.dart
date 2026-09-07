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
}
