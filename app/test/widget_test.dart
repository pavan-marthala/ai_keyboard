import 'package:ai_keyboard/core/di/injection.dart';
import 'package:ai_keyboard/main.dart';
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

  testWidgets('App renders home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AiKeyboardApp());
    await tester.pumpAndSettle();

    expect(find.text('AI Keyboard Utility'), findsWidgets);
  });
}
