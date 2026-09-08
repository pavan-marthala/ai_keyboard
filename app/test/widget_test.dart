import 'package:atfix/core/di/injection.dart';
import 'package:atfix/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const desktopChannel = MethodChannel('com.pk.atfix/desktop');

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(desktopChannel, (call) async {
          if (call.method == 'isAccessibilityGranted') return true;
          if (call.method == 'getInputMonitoringStatus') return 'granted';
          if (call.method == 'registerHotkey') return true;
          return null;
        });
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(desktopChannel, null);
    await getIt.reset();
  });

  testWidgets('App renders Desktop Onboarding on first launch on desktop', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AtFixApp());
    await tester.pumpAndSettle();

    expect(find.text('AtFix'), findsWidgets);
    expect(find.text('AI assistance wherever you type'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('App renders Playground when onboarding is completed', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'desktop_onboarding_completed': true,
    });
    await getIt.reset();
    await configureDependencies();

    await tester.pumpWidget(const AtFixApp());
    await tester.pumpAndSettle();

    expect(find.text('Playground'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
