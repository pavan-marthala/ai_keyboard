import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/desktop_capability.dart';

part 'desktop_onboarding_state.freezed.dart';

@freezed
abstract class DesktopOnboardingState with _$DesktopOnboardingState {
  const factory DesktopOnboardingState({
    @Default(false) bool isLoading,
    @Default([]) List<DesktopCapability> capabilities,
    @Default(false) bool isAllRequiredGranted,
    @Default(false) bool isCompleted,
    String? errorMessage,
  }) = _DesktopOnboardingState;

  factory DesktopOnboardingState.initial() => const DesktopOnboardingState(
    isLoading: true,
    capabilities: [],
    isAllRequiredGranted: false,
    isCompleted: false,
  );
}
