import 'package:atfix/core/di/injection.dart';
import 'package:atfix/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  tearDown(() async {
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
