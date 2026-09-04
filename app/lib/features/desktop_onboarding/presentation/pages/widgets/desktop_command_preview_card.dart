import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DesktopCommandPreviewCard extends StatelessWidget {
  const DesktopCommandPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    final commands = [
      (trigger: '@fix', label: 'Fix grammar & spelling', color: colors.primary),
      (
        trigger: '@rewrite',
        label: 'Improve clarity & flow',
        color: colors.accent2,
      ),
      (
        trigger: '@pro',
        label: 'Professional workplace tone',
        color: colors.success,
      ),
      (
        trigger: '@casual',
        label: 'Friendly & conversational',
        color: colors.warning,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supported Commands',
            style: typo.titleMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commands.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.trigger,
                      style: typo.bodyMedium.copyWith(
                        color: c.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.label,
                      style: typo.bodyMedium.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.terminal_rounded,
                      size: 16,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Transformation Preview',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'I has a apple @fix',
                        style: typo.bodyMedium.copyWith(
                          fontFamily: 'monospace',
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'I have an apple.',
                        style: typo.bodyMedium.copyWith(
                          fontFamily: 'monospace',
                          color: colors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
