import '../entities/desktop_capability.dart';

abstract class DesktopCapabilityRepository {
  /// Queries the current capability/permission statuses for the active platform.
  Future<List<DesktopCapability>> getCapabilities();

  /// Prompts the user or requests access for the given capability.
  Future<bool> requestCapability(DesktopCapabilityType type);

  /// Opens the system preferences or settings pane for the given capability.
  Future<void> openSystemSettings(DesktopCapabilityType type);

  /// Checks if desktop onboarding has been previously completed.
  bool isOnboardingCompleted();

  /// Sets whether desktop onboarding has been completed.
  Future<void> setOnboardingCompleted(bool completed);
}
