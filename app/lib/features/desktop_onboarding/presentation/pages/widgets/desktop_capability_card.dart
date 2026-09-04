import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/desktop_capability.dart';

class DesktopCapabilityCard extends StatelessWidget {
  final DesktopCapability capability;
  final VoidCallback onOpenSettings;

  const DesktopCapabilityCard({
    super.key,
    required this.capability,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    final isEnabled = capability.status == DesktopCapabilityStatus.enabled;
    final isRequired = capability.status == DesktopCapabilityStatus.required;
    final isUnknown = capability.status == DesktopCapabilityStatus.unknown;

    final Color statusColor = isEnabled
        ? colors.success
        : isUnknown
        ? colors.primary300
        : isRequired
        ? colors.warning
        : colors.textSecondary;

    final String statusLabel = isEnabled
        ? 'Enabled'
        : isUnknown
        ? 'Verify in Settings'
        : isRequired
        ? 'Required'
        : 'Not configured yet';

    final IconData statusIcon = isEnabled
        ? Icons.check_circle_rounded
        : isUnknown
        ? Icons.help_outline_rounded
        : isRequired
        ? Icons.warning_amber_rounded
        : Icons.info_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? colors.success.withValues(alpha: 0.3)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capability.title,
                      style: typo.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      capability.description,
                      style: typo.bodyMedium.copyWith(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (isUnknown) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Status cannot be verified automatically. Verify or enable this permission in System Settings.',
                        style: typo.bodyMedium.copyWith(
                          color: colors.primary300,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isRequired || isUnknown) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onOpenSettings,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderLight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
