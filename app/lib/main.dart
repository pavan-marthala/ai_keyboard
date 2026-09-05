import 'package:ai_keyboard/core/di/injection.dart';
import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:ai_keyboard/core/utils/app_routes.dart';
import 'package:ai_keyboard/features/app_shell/presentation/screens%20/app_shell_screen.dart';
import 'package:ai_keyboard/features/commands/presentation/bloc/command_bloc.dart';
import 'package:ai_keyboard/features/commands/presentation/bloc/command_event.dart';
import 'package:ai_keyboard/features/playground/presentation/pages/keyboard_playground_page.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_event.dart';
import 'package:ai_keyboard/features/settings/presentation/pages/settings_page.dart';
import 'package:ai_keyboard/core/utils/check_platforms.dart';
import 'package:ai_keyboard/features/desktop_onboarding/domain/repositories/desktop_capability_repository.dart';
import 'package:ai_keyboard/features/desktop_onboarding/presentation/pages/desktop_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GlobalKey<NavigatorState> _shellNavigatorKeyPlayGround =
    GlobalKey<NavigatorState>(debugLabel: 'shell-playground');
final GlobalKey<NavigatorState> _shellNavigatorKeySettings =
    GlobalKey<NavigatorState>(debugLabel: 'shell-settings');

final GoRouter _appRouter = GoRouter(
  initialLocation: AppRoutes.playground,
  navigatorKey: rootNavigatorKey,
  debugLogDiagnostics: true,
  redirect: (context, state) {
    if (PlatformChecker.isDesktop()) {
      final repository = getIt<DesktopCapabilityRepository>();
      final isCompleted = repository.isOnboardingCompleted();
      final isOnboarding = state.matchedLocation == AppRoutes.desktopOnboarding;

      if (!isCompleted && !isOnboarding) {
        return AppRoutes.desktopOnboarding;
      }
      if (isCompleted && isOnboarding) {
        return AppRoutes.playground;
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.desktopOnboarding,
      name: AppRoutes.desktopOnboarding,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: DesktopOnboardingPage()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShellScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyPlayGround,
          routes: [
            GoRoute(
              path: AppRoutes.playground,
              name: AppRoutes.playground,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: KeyboardPlaygroundPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeySettings,
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              name: AppRoutes.settings,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsPage()),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const AtFIxApp());
}

class AtFIxApp extends StatelessWidget {
  const AtFIxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<SettingsBloc>()..add(const SettingsEvent.loadSettings()),
          lazy: false,
        ),
        BlocProvider(
          create: (_) =>
              getIt<CommandBloc>()..add(const CommandEvent.loadCommands()),
          lazy: false,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: _appRouter,
        title: 'AtFIx Utility',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        builder: (context, child) {
          return child ?? const Scaffold();
        },
      ),
    );
  }
}
