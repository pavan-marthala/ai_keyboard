import 'package:ai_keyboard/core/di/injection.dart';
import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:ai_keyboard/core/utils/app_buitton.dart';
import 'package:ai_keyboard/core/utils/app_routes.dart';
import 'package:ai_keyboard/core/utils/check_platforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/desktop_onboarding_bloc.dart';
import '../bloc/desktop_onboarding_event.dart';
import '../bloc/desktop_onboarding_state.dart';
import 'widgets/desktop_capability_card.dart';
import 'widgets/desktop_command_preview_card.dart';
import 'widgets/onboarding_page_indicator.dart';

class DesktopOnboardingPage extends StatelessWidget {
  const DesktopOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<DesktopOnboardingBloc>()
            ..add(const DesktopOnboardingEvent.checkCapabilities()),
      child: const _DesktopOnboardingView(),
    );
  }
}

class _DesktopOnboardingView extends StatefulWidget {
  const _DesktopOnboardingView();

  @override
  State<_DesktopOnboardingView> createState() => _DesktopOnboardingViewState();
}

class _DesktopOnboardingViewState extends State<_DesktopOnboardingView>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DesktopOnboardingBloc>().add(
        const DesktopOnboardingEvent.checkCapabilities(),
      );
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _finishOnboarding() {
    final bloc = context.read<DesktopOnboardingBloc>();
    if (bloc.state.isCompleted) {
      context.go(AppRoutes.playground);
    } else {
      bloc.add(const DesktopOnboardingEvent.completeOnboarding());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocListener<DesktopOnboardingBloc, DesktopOnboardingState>(
        listenWhen: (previous, current) =>
            !previous.isCompleted && current.isCompleted,
        listener: (context, state) {
          context.go(AppRoutes.playground);
        },
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  OnboardingPageIndicator(
                    currentPage: _currentPage,
                    pageCount: 2,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      children: [
                        _buildIntroductionPage(context),
                        _buildEnableAccessPage(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroductionPage(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.25),
                  colors.surfaceDark,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Keyboard',
            style: typo.displayMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI assistance wherever you type',
            style: typo.titleMedium.copyWith(
              color: colors.primary300,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Use simple commands such as @fix, @rewrite, @pro, or @casual to transform your text without leaving the application you're working in.",
            textAlign: TextAlign.center,
            style: typo.bodyMedium.copyWith(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const DesktopCommandPreviewCard(),
          const SizedBox(height: 36),
          AppButton(
            text: 'Continue',
            width: double.infinity,
            onPressed: _nextPage,
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEnableAccessPage(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    final isWindows = PlatformChecker.isWindows();

    final title = 'Enable Desktop Access';
    final subtitle = isWindows
        ? 'AI Keyboard needs desktop integration to detect commands and interact with supported text fields.'
        : 'AI Keyboard needs access to interact with supported applications and detect your typing commands.';

    return BlocBuilder<DesktopOnboardingBloc, DesktopOnboardingState>(
      builder: (context, state) {
        final bloc = context.read<DesktopOnboardingBloc>();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: typo.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: typo.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.capabilities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'No capability configuration required for this platform.',
                    style: typo.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                )
              else
                ...state.capabilities.map((capability) {
                  return DesktopCapabilityCard(
                    capability: capability,
                    onOpenSettings: () => bloc.add(
                      DesktopOnboardingEvent.openSettings(capability.type),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _previousPage,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: isWindows
                          ? 'Continue to App'
                          : state.isAllRequiredGranted
                          ? 'Get Started'
                          : 'Continue',
                      color: state.isAllRequiredGranted || isWindows
                          ? colors.primary
                          : colors.surfaceDark,
                      side: state.isAllRequiredGranted || isWindows
                          ? null
                          : Border.all(color: colors.borderLight),
                      onPressed: _finishOnboarding,
                      icon: const Icon(Icons.check_rounded, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
