import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/desktop_capability.dart';
import '../../domain/repositories/desktop_capability_repository.dart';
import 'desktop_onboarding_event.dart';
import 'desktop_onboarding_state.dart';

@injectable
class DesktopOnboardingBloc
    extends Bloc<DesktopOnboardingEvent, DesktopOnboardingState> {
  final DesktopCapabilityRepository _repository;

  DesktopOnboardingBloc(this._repository)
    : super(DesktopOnboardingState.initial()) {
    on<DesktopOnboardingEvent>((event, emit) async {
      await event.map(
        checkCapabilities: (_) => _onCheckCapabilities(emit),
        requestCapability: (e) => _onRequestCapability(e.type, emit),
        openSettings: (e) => _onOpenSettings(e.type, emit),
        completeOnboarding: (_) => _onCompleteOnboarding(emit),
      );
    });
  }

  Future<void> _onCheckCapabilities(
    Emitter<DesktopOnboardingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final capabilities = await _repository.getCapabilities();
      final allGranted =
          capabilities.isNotEmpty &&
          capabilities
              .where((c) => c.isRequired)
              .every((c) => c.status == DesktopCapabilityStatus.enabled);
      final isCompleted = _repository.isOnboardingCompleted();

      emit(
        state.copyWith(
          isLoading: false,
          capabilities: capabilities,
          isAllRequiredGranted: allGranted,
          isCompleted: isCompleted,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onRequestCapability(
    DesktopCapabilityType type,
    Emitter<DesktopOnboardingState> emit,
  ) async {
    try {
      await _repository.requestCapability(type);
      // Re-check capability status after request
      final capabilities = await _repository.getCapabilities();
      final allGranted =
          capabilities.isNotEmpty &&
          capabilities
              .where((c) => c.isRequired)
              .every((c) => c.status == DesktopCapabilityStatus.enabled);

      emit(
        state.copyWith(
          capabilities: capabilities,
          isAllRequiredGranted: allGranted,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onOpenSettings(
    DesktopCapabilityType type,
    Emitter<DesktopOnboardingState> emit,
  ) async {
    try {
      await _repository.openSystemSettings(type);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onCompleteOnboarding(
    Emitter<DesktopOnboardingState> emit,
  ) async {
    try {
      await _repository.setOnboardingCompleted(true);
      emit(state.copyWith(isCompleted: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
