import 'package:atfix/features/desktop_onboarding/domain/entities/desktop_capability.dart';
import 'package:atfix/features/desktop_onboarding/domain/repositories/desktop_capability_repository.dart';
import 'package:atfix/features/desktop_onboarding/presentation/bloc/desktop_onboarding_bloc.dart';
import 'package:atfix/features/desktop_onboarding/presentation/bloc/desktop_onboarding_event.dart';
import 'package:atfix/features/desktop_onboarding/presentation/bloc/desktop_onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDesktopCapabilityRepository implements DesktopCapabilityRepository {
  List<DesktopCapability> capabilities = [
    const DesktopCapability(
      type: DesktopCapabilityType.accessibility,
      title: 'Accessibility',
      description: 'Test description',
      status: DesktopCapabilityStatus.required,
    ),
  ];
  bool onboardingCompleted = false;
  DesktopCapabilityType? requestedType;
  DesktopCapabilityType? openedSettingsType;

  @override
  Future<List<DesktopCapability>> getCapabilities() async => capabilities;

  @override
  Future<bool> requestCapability(DesktopCapabilityType type) async {
    requestedType = type;
    return true;
  }

  @override
  Future<void> openSystemSettings(DesktopCapabilityType type) async {
    openedSettingsType = type;
  }

  @override
  bool isOnboardingCompleted() => onboardingCompleted;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    onboardingCompleted = completed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDesktopCapabilityRepository repository;
  late DesktopOnboardingBloc bloc;

  setUp(() {
    repository = FakeDesktopCapabilityRepository();
    bloc = DesktopOnboardingBloc(repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('DesktopOnboardingBloc', () {
    test('initial state has isLoading true and empty capabilities', () {
      expect(bloc.state.isLoading, isTrue);
      expect(bloc.state.capabilities, isEmpty);
      expect(bloc.state.isAllRequiredGranted, isFalse);
    });

    test(
      'checkCapabilities updates capabilities and checks granted status',
      () async {
        bloc.add(const DesktopOnboardingEvent.checkCapabilities());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<DesktopOnboardingState>().having(
              (s) => s.isLoading,
              'isLoading',
              isTrue,
            ),
            isA<DesktopOnboardingState>()
                .having((s) => s.isLoading, 'isLoading', isFalse)
                .having((s) => s.capabilities.length, 'capabilities.length', 1)
                .having(
                  (s) => s.isAllRequiredGranted,
                  'isAllRequiredGranted',
                  isFalse,
                ),
          ]),
        );
      },
    );

    test('checkCapabilities reports isAllRequiredGranted true when all required are enabled', () async {
      repository.capabilities = [
        const DesktopCapability(
          type: DesktopCapabilityType.accessibility,
          title: 'Accessibility',
          description: 'Test description',
          status: DesktopCapabilityStatus.enabled,
        ),
      ];

      bloc.add(const DesktopOnboardingEvent.checkCapabilities());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DesktopOnboardingState>().having(
            (s) => s.isLoading,
            'isLoading',
            isTrue,
          ),
          isA<DesktopOnboardingState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having(
                (s) => s.isAllRequiredGranted,
                'isAllRequiredGranted',
                isTrue,
              ),
        ]),
      );
    });

    test('checkCapabilities reports isAllRequiredGranted false when capabilities are empty', () async {
      repository.capabilities = [];

      bloc.add(const DesktopOnboardingEvent.checkCapabilities());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DesktopOnboardingState>().having(
            (s) => s.isLoading,
            'isLoading',
            isTrue,
          ),
          isA<DesktopOnboardingState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having((s) => s.capabilities, 'capabilities', isEmpty)
              .having(
                (s) => s.isAllRequiredGranted,
                'isAllRequiredGranted',
                isFalse,
              ),
        ]),
      );
    });

    test(
      'checkCapabilities preserves independent decoupled capability states',
      () async {
        repository.capabilities = [
          const DesktopCapability(
            type: DesktopCapabilityType.accessibility,
            title: 'Accessibility',
            description: 'Accessibility description',
            status: DesktopCapabilityStatus.enabled,
          ),
          const DesktopCapability(
            type: DesktopCapabilityType.inputMonitoring,
            title: 'Input Monitoring',
            description: 'Input Monitoring description',
            status: DesktopCapabilityStatus.required,
          ),
        ];

        bloc.add(const DesktopOnboardingEvent.checkCapabilities());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<DesktopOnboardingState>().having(
              (s) => s.isLoading,
              'isLoading',
              isTrue,
            ),
            isA<DesktopOnboardingState>()
                .having((s) => s.isLoading, 'isLoading', isFalse)
                .having(
                  (s) => s.capabilities[0].status,
                  'accessibility',
                  DesktopCapabilityStatus.enabled,
                )
                .having(
                  (s) => s.capabilities[1].status,
                  'inputMonitoring',
                  DesktopCapabilityStatus.required,
                )
                .having(
                  (s) => s.isAllRequiredGranted,
                  'isAllRequiredGranted',
                  isFalse,
                ),
          ]),
        );
      },
    );

    test('requestCapability delegates to repository', () async {
      bloc.add(
        const DesktopOnboardingEvent.requestCapability(
          DesktopCapabilityType.accessibility,
        ),
      );

      await expectLater(bloc.stream, emits(isA<DesktopOnboardingState>()));

      expect(
        repository.requestedType,
        equals(DesktopCapabilityType.accessibility),
      );
    });

    test('completeOnboarding sets completed state', () async {
      bloc.add(const DesktopOnboardingEvent.completeOnboarding());

      await expectLater(
        bloc.stream,
        emits(
          isA<DesktopOnboardingState>().having(
            (s) => s.isCompleted,
            'isCompleted',
            isTrue,
          ),
        ),
      );

      expect(repository.isOnboardingCompleted(), isTrue);
    });
  });
}
