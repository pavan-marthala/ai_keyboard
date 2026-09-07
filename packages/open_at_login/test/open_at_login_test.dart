import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_at_login/core/app_launcher_macos_impl.dart';
import 'package:open_at_login/core/app_launcher_windows_impl.dart';
import 'package:open_at_login/core/no_op_app_launcher.dart';
import 'package:open_at_login/open_at_login.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('open_at_login');
  final List<MethodCall> log = <MethodCall>[];
  bool mockIsEnabledValue = false;
  bool shouldThrowPlatformException = false;
  bool returnNull = false;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    log.clear();
    mockIsEnabledValue = false;
    shouldThrowPlatformException = false;
    returnNull = false;
    OpenAtLogin.instance.reset();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);

          if (shouldThrowPlatformException) {
            throw PlatformException(
              code: 'UNEXPECTED_ERROR',
              message: 'Something went wrong natively',
              details: 'Details from native',
            );
          }

          switch (methodCall.method) {
            case 'isOpenAtLoginEnabled':
              if (returnNull) return null;
              return mockIsEnabledValue;
            case 'setOpenAtLoginEnabled':
              final args = methodCall.arguments as Map<dynamic, dynamic>;
              mockIsEnabledValue = args['enabled'] as bool;
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    OpenAtLogin.instance.reset();
  });

  group('Requirement 1 & 2: Singleton, Safety & Lifecycle', () {
    test('1. OpenAtLogin.instance exists and is identical', () {
      expect(identical(OpenAtLogin.instance, OpenAtLogin.instance), isTrue);
      expect(OpenAtLogin.instance, isNotNull);
    });

    test('2. initialize() is safe across platforms', () {
      // macOS
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      OpenAtLogin.instance.initialize(
        appName: 'TestApp',
        appPath: '/Applications/TestApp.app',
        args: ['--background'],
      );
      expect(OpenAtLogin.instance.isInitialized, isTrue);

      // Windows
      OpenAtLogin.instance.reset();
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      OpenAtLogin.instance.initialize(
        appName: 'TestApp',
        appPath: r'C:\Program Files\TestApp\TestApp.exe',
      );
      expect(OpenAtLogin.instance.isInitialized, isTrue);

      // Linux
      OpenAtLogin.instance.reset();
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      OpenAtLogin.instance.initialize(
        appName: 'TestApp',
        appPath: '/usr/bin/testapp',
      );
      expect(OpenAtLogin.instance.isInitialized, isTrue);
    });

    test(
      '3. isEnabled() before initialization does not throw and returns false',
      () async {
        expect(OpenAtLogin.instance.isInitialized, isFalse);
        expect(OpenAtLogin.instance.launcher, isA<NoOpAppLauncher>());

        final enabled = await OpenAtLogin.instance.isEnabled();
        expect(enabled, isFalse);
        expect(log, isEmpty);
      },
    );

    test(
      '4. setEnabled() before initialization does not throw and safely no-ops',
      () async {
        expect(OpenAtLogin.instance.isInitialized, isFalse);
        expect(OpenAtLogin.instance.launcher, isA<NoOpAppLauncher>());

        await expectLater(OpenAtLogin.instance.setEnabled(true), completes);
        await expectLater(OpenAtLogin.instance.setEnabled(false), completes);
        expect(log, isEmpty);
      },
    );
  });

  group('Requirement 5, 6, 7: Unsupported Platform Behavior', () {
    for (final platform in [
      TargetPlatform.linux,
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ]) {
      test('5. $platform uses NoOpAppLauncher after initialize()', () {
        debugDefaultTargetPlatformOverride = platform;
        OpenAtLogin.instance.initialize(
          appName: 'TestApp',
          appPath: '/path/to/app',
        );

        expect(OpenAtLogin.instance.isInitialized, isTrue);
        expect(OpenAtLogin.instance.launcher, isA<NoOpAppLauncher>());
      });

      test('6. $platform isEnabled() returns false', () async {
        debugDefaultTargetPlatformOverride = platform;
        OpenAtLogin.instance.initialize(
          appName: 'TestApp',
          appPath: '/path/to/app',
        );

        final result = await OpenAtLogin.instance.isEnabled();
        expect(result, isFalse);
        expect(log, isEmpty);
      });

      test(
        '7. $platform setEnabled() does not invoke a MethodChannel',
        () async {
          debugDefaultTargetPlatformOverride = platform;
          OpenAtLogin.instance.initialize(
            appName: 'TestApp',
            appPath: '/path/to/app',
          );

          await OpenAtLogin.instance.setEnabled(true);
          await OpenAtLogin.instance.setEnabled(false);
          expect(log, isEmpty);
        },
      );
    }
  });

  group('Requirement 8: macOS Implementation', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      OpenAtLogin.instance.initialize(
        appName: 'AtFix',
        appPath: '/Applications/AtFix.app',
        args: ['--background'],
      );
    });

    test('8. macOS selects MacOSAppLauncher', () {
      expect(OpenAtLogin.instance.isInitialized, isTrue);
      expect(OpenAtLogin.instance.launcher, isA<MacOSAppLauncher>());
      expect(OpenAtLogin.instance.launcher.appName, equals('AtFix'));
      expect(
        OpenAtLogin.instance.launcher.appPath,
        equals('/Applications/AtFix.app'),
      );
      expect(OpenAtLogin.instance.launcher.args, equals(['--background']));
    });

    test('macOS isEnabled() communicates via MethodChannel', () async {
      mockIsEnabledValue = true;
      final enabled = await OpenAtLogin.instance.isEnabled();

      expect(enabled, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, equals('isOpenAtLoginEnabled'));
    });

    test('macOS setEnabled() communicates via MethodChannel', () async {
      await OpenAtLogin.instance.setEnabled(true);

      expect(log, hasLength(1));
      expect(log.first.method, equals('setOpenAtLoginEnabled'));
      expect(log.first.arguments, equals({'enabled': true}));
      expect(mockIsEnabledValue, isTrue);

      await OpenAtLogin.instance.setEnabled(false);
      expect(log, hasLength(2));
      expect(log.last.method, equals('setOpenAtLoginEnabled'));
      expect(log.last.arguments, equals({'enabled': false}));
      expect(mockIsEnabledValue, isFalse);
    });
  });

  group('Requirement 9: Windows Implementation', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      OpenAtLogin.instance.initialize(
        appName: 'AtFix',
        appPath: r'C:\Program Files\AtFix\atfix.exe',
        args: ['--background'],
      );
    });

    test('9. Windows selects WindowsAppLauncher and passes correct config', () {
      expect(OpenAtLogin.instance.isInitialized, isTrue);
      expect(OpenAtLogin.instance.launcher, isA<WindowsAppLauncher>());
      expect(OpenAtLogin.instance.launcher.appName, equals('AtFix'));
      expect(
        OpenAtLogin.instance.launcher.appPath,
        equals(r'C:\Program Files\AtFix\atfix.exe'),
      );
      expect(OpenAtLogin.instance.launcher.args, equals(['--background']));
    });

    test('Windows isEnabled() communicates via MethodChannel', () async {
      mockIsEnabledValue = true;
      final enabled = await OpenAtLogin.instance.isEnabled();

      expect(enabled, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, equals('isOpenAtLoginEnabled'));
      expect(
        log.first.arguments,
        equals({
          'appName': 'AtFix',
          'appPath': r'C:\Program Files\AtFix\atfix.exe',
        }),
      );
    });

    test(
      'Windows setEnabled() communicates via MethodChannel with args',
      () async {
        await OpenAtLogin.instance.setEnabled(true);

        expect(log, hasLength(1));
        expect(log.first.method, equals('setOpenAtLoginEnabled'));
        expect(
          log.first.arguments,
          equals({
            'enabled': true,
            'appName': 'AtFix',
            'appPath': r'C:\Program Files\AtFix\atfix.exe',
            'args': ['--background'],
          }),
        );
        expect(mockIsEnabledValue, isTrue);

        await OpenAtLogin.instance.setEnabled(false);
        expect(log, hasLength(2));
        expect(log.last.method, equals('setOpenAtLoginEnabled'));
        expect(
          log.last.arguments,
          equals({
            'enabled': false,
            'appName': 'AtFix',
            'appPath': r'C:\Program Files\AtFix\atfix.exe',
            'args': ['--background'],
          }),
        );
        expect(mockIsEnabledValue, isFalse);
      },
    );

    test('Windows throws ArgumentError when appName or appPath is empty on setEnabled(true)', () async {
      final launcherEmptyName = WindowsAppLauncher(
        appName: '',
        appPath: r'C:\app.exe',
      );
      expect(
        () => launcherEmptyName.setEnabled(true),
        throwsA(isA<ArgumentError>()),
      );

      final launcherEmptyPath = WindowsAppLauncher(appName: 'App', appPath: '');
      expect(
        () => launcherEmptyPath.setEnabled(true),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Requirement 10: Error Handling', () {
    test('10. PlatformException is preserved and propagated with meaningful error details', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      OpenAtLogin.instance.initialize(
        appName: 'AtFix',
        appPath: '/Applications/AtFix.app',
      );
      shouldThrowPlatformException = true;

      expect(
        () => OpenAtLogin.instance.isEnabled(),
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'UNEXPECTED_ERROR')
              .having(
                (e) => e.message,
                'message',
                'Something went wrong natively',
              )
              .having((e) => e.details, 'details', 'Details from native'),
        ),
      );

      expect(
        () => OpenAtLogin.instance.setEnabled(true),
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'UNEXPECTED_ERROR')
              .having(
                (e) => e.message,
                'message',
                'Something went wrong natively',
              ),
        ),
      );
    });

    test(
      'Windows propagates native PlatformException with code and message',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        OpenAtLogin.instance.initialize(
          appName: 'AtFix',
          appPath: r'C:\Program Files\AtFix\atfix.exe',
        );
        shouldThrowPlatformException = true;

        expect(
          () => OpenAtLogin.instance.isEnabled(),
          throwsA(
            isA<PlatformException>()
                .having((e) => e.code, 'code', 'UNEXPECTED_ERROR')
                .having(
                  (e) => e.message,
                  'message',
                  'Something went wrong natively',
                ),
          ),
        );

        expect(
          () => OpenAtLogin.instance.setEnabled(true),
          throwsA(
            isA<PlatformException>()
                .having((e) => e.code, 'code', 'UNEXPECTED_ERROR')
                .having(
                  (e) => e.message,
                  'message',
                  'Something went wrong natively',
                ),
          ),
        );
      },
    );

    test('macOS throws StateError when native method returns null', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      OpenAtLogin.instance.initialize(
        appName: 'AtFix',
        appPath: '/Applications/AtFix.app',
      );
      returnNull = true;

      expect(
        () => OpenAtLogin.instance.isEnabled(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
