import 'package:atfix/core/theme/app_theme.dart';
import 'package:atfix/features/shortcuts/domain/entities/desktop_shortcut.dart';
import 'package:atfix/features/shortcuts/presentation/widgets/shortcut_recorder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ShortcutRecorder displays current shortcut tokens', (tester) async {
    const shortcut = DesktopShortcut(
      key: 'space',
      modifiers: ['control', 'option'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ShortcutRecorder(
            currentShortcut: shortcut,
            onShortcutChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Global Shortcut'), findsOneWidget);
    expect(find.text('Control + Option + Space'), findsOneWidget);
    expect(find.byTooltip('Change Shortcut'), findsOneWidget);
  });

  testWidgets('ShortcutRecorder displays error message when provided', (tester) async {
    const shortcut = DesktopShortcut(
      key: 'space',
      modifiers: ['control', 'option'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ShortcutRecorder(
            currentShortcut: shortcut,
            errorMessage: 'Shortcut is already in use by another app',
            onShortcutChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.text('Shortcut is already in use by another app'),
      findsOneWidget,
    );
  });

  testWidgets('ShortcutRecorder enters recording state on tap', (tester) async {
    const shortcut = DesktopShortcut(
      key: 'space',
      modifiers: ['control', 'option'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ShortcutRecorder(
            currentShortcut: shortcut,
            onShortcutChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Change Shortcut'));
    await tester.pumpAndSettle();

    expect(find.text('Listening for shortcut...'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Global Shortcut'), findsOneWidget);
  });
}
