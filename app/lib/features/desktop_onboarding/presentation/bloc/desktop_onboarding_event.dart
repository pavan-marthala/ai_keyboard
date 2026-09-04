import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/desktop_capability.dart';

part 'desktop_onboarding_event.freezed.dart';

@freezed
abstract class DesktopOnboardingEvent with _$DesktopOnboardingEvent {
  const factory DesktopOnboardingEvent.checkCapabilities() = _CheckCapabilities;
  const factory DesktopOnboardingEvent.requestCapability(
    DesktopCapabilityType type,
  ) = _RequestCapability;
  const factory DesktopOnboardingEvent.openSettings(
    DesktopCapabilityType type,
  ) = _OpenSettings;
  const factory DesktopOnboardingEvent.completeOnboarding() =
      _CompleteOnboarding;
}
