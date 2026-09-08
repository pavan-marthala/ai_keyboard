import '../entities/desktop_shortcut.dart';

/// Repository for managing, persisting, and registering desktop global shortcuts.
abstract interface class DesktopShortcutRepository {
  /// Retrieves the current shortcut configuration (saved or platform default).
  Future<DesktopShortcut> getShortcut();

  /// Attempts native registration; if successful, persists to storage and returns true.
  /// If registration fails (conflict/unsupported), keeps existing shortcut and returns false.
  Future<bool> registerAndSaveShortcut(DesktopShortcut shortcut);

  /// Tests/attempts native registration without immediately persisting.
  Future<bool> registerShortcut(DesktopShortcut shortcut);
}
