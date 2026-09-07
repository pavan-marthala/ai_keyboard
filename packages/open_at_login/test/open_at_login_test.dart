import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_at_login/core/app_launcher_macos_impl.dart';
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
              message: 'Something went wrong',
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

  group('OpenAtLogin Singleton & Lifecycle', () {
    test('returns the identical singleton instance', () {
      expect(identical(OpenAtLogin.instance, OpenAtLogin.instance), isTrue);
    });

    test('isInitialized is false before initialize is called', () {
      expect(OpenAtLogin.instance.isInitialized, isFalse);
      expect(OpenAtLogin.instance.launcher, isNull);
    });

    test('calling isEnabled before initialize throws StateError', () async {
      expect(
        () => OpenAtLogin.instance.isEnabled(),
        throwsA(isA<StateError>()),
      );
    });

    test('calling setEnabled before initialize throws StateError', () async {
      expect(
        () => OpenAtLogin.instance.setEnabled(true),
        throwsA(isA<StateError>()),
      );
    });

    test('initialize configures launcher on macOS', () {
      OpenAtLogin.instance.initialize(
        appName: 'TestApp',
        appPath: '/Applications/TestApp.app',
        args: ['--hidden'],
      );

      expect(OpenAtLogin.instance.isInitialized, isTrue);
      expect(OpenAtLogin.instance.launcher, isNotNull);
      expect(OpenAtLogin.instance.launcher, isA<AppLauncherMacOSImpl>());
      expect(OpenAtLogin.instance.launcher!.appName, equals('TestApp'));
      expect(
        OpenAtLogin.instance.launcher!.appPath,
        equals('/Applications/TestApp.app'),
      );
      expect(OpenAtLogin.instance.launcher!.args, equals(['--hidden']));
    });

    test('initialize throws UnsupportedError on unsupported platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      expect(
        () => OpenAtLogin.instance.initialize(
          appName: 'TestApp',
          appPath: '/usr/bin/testapp',
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('OpenAtLogin Platform Operations', () {
    setUp(() {
      OpenAtLogin.instance.initialize(
        appName: 'TestApp',
        appPath: '/Applications/TestApp.app',
      );
    });

    test('isEnabled queries isOpenAtLoginEnabled and returns false', () async {
      mockIsEnabledValue = false;
      final enabled = await OpenAtLogin.instance.isEnabled();

      expect(enabled, isFalse);
      expect(log, hasLength(1));
      expect(log.first.method, equals('isOpenAtLoginEnabled'));
      expect(log.first.arguments, isNull);
    });

    test('isEnabled queries isOpenAtLoginEnabled and returns true', () async {
      mockIsEnabledValue = true;
      final enabled = await OpenAtLogin.instance.isEnabled();

      expect(enabled, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, equals('isOpenAtLoginEnabled'));
    });

    test('isEnabled throws StateError if native method returns null', () async {
      returnNull = true;

      expect(
        () => OpenAtLogin.instance.isEnabled(),
        throwsA(isA<StateError>()),
      );
    });

    test('setEnabled(true) sends enabled: true to native channel', () async {
      await OpenAtLogin.instance.setEnabled(true);

      expect(log, hasLength(1));
      expect(log.first.method, equals('setOpenAtLoginEnabled'));
      expect(log.first.arguments, equals({'enabled': true}));
      expect(mockIsEnabledValue, isTrue);
    });

    test('setEnabled(false) sends enabled: false to native channel', () async {
      mockIsEnabledValue = true;
      await OpenAtLogin.instance.setEnabled(false);

      expect(log, hasLength(1));
      expect(log.first.method, equals('setOpenAtLoginEnabled'));
      expect(log.first.arguments, equals({'enabled': false}));
      expect(mockIsEnabledValue, isFalse);
    });

    test('PlatformException is rethrown when channel fails', () async {
      shouldThrowPlatformException = true;

      expect(
        () => OpenAtLogin.instance.isEnabled(),
        throwsA(isA<PlatformException>()),
      );

      expect(
        () => OpenAtLogin.instance.setEnabled(true),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
