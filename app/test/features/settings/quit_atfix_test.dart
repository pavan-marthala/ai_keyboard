import 'package:atfix/core/di/injection.dart';
import 'package:atfix/core/theme/app_theme.dart';
import 'package:atfix/features/commands/presentation/bloc/command_bloc.dart';
import 'package:atfix/features/commands/presentation/bloc/command_event.dart';
import 'package:atfix/features/desktop_onboarding/data/datasources/desktop_platform_channel_datasource.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_event.dart';
import 'package:atfix/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.pk.atfix/desktop');

  test('DesktopPlatformChannelDataSource quitAtFixCompletely invokes native method', () async {
    final List<MethodCall> log = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == 'quitAtFixCompletely') {
        return true;
      }
      return null;
    });

    final dataSource = DesktopPlatformChannelDataSource();
    await dataSource.quitAtFixCompletely();

    expect(log, hasLength(1));
    expect(log.first.method, 'quitAtFixCompletely');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('SettingsPage displays Quit AtFix Completely button and triggers channel call on confirm', (
    WidgetTester tester,
  ) async {
    final List<MethodCall> log = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == 'quitAtFixCompletely') {
        return true;
      }
      return null;
    });

    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();

    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => getIt<SettingsBloc>()..add(const SettingsEvent.loadSettings()),
            ),
            BlocProvider(
              create: (_) => getIt<CommandBloc>()..add(const CommandEvent.loadCommands()),
            ),
          ],
          child: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Application section
    expect(find.text('Application'), findsOneWidget);

    // Verify "Quit AtFix Completely" button is present
    final quitButton = find.text('Quit AtFix Completely');
    expect(quitButton, findsOneWidget);

    // Tap "Quit AtFix Completely"
    await tester.tap(quitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify confirmation dialog
    expect(find.text('Quit AtFix Completely?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    final confirmQuitButton = find.widgetWithText(FilledButton, 'Quit Completely');
    expect(confirmQuitButton, findsOneWidget);

    // Tap "Quit Completely"
    await tester.tap(confirmQuitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify channel method was called
    expect(log.any((call) => call.method == 'quitAtFixCompletely'), isTrue);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await getIt.reset();
  });
}
