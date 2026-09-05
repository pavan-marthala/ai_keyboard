import 'package:atfix/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class OnboardingPageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const OnboardingPageIndicator({
    super.key,
    required this.currentPage,
    this.pageCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isSelected = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isSelected ? 24 : 6,
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary
                : colors.textTertiary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
