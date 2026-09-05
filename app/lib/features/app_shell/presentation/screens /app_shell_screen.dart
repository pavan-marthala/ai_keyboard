import 'package:atfix/core/theme/app_theme.dart';
import 'package:atfix/features/app_shell/presentation/screens%20/app_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellScreen extends StatelessWidget {
  const AppShellScreen({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          navigationShell,
          Positioned(
            bottom: 0,
            child: AppNavigationBar(
              selectedIndex: navigationShell.currentIndex,
              unreadCount: 0,
              onTabSelected: (index) {
                navigationShell.goBranch(index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
