/// NovaByte Hub — Status Badge Widget
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

/// Pill-shaped badge showing request/license status with icon and color.
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: fontSize + 2, color: config.color),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  static _StatusConfig _getConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusConfig(
          color: AppColors.warning,
          icon: LucideIcons.clock,
          label: 'Pending',
        );
      case 'approved':
        return _StatusConfig(
          color: AppColors.success,
          icon: LucideIcons.checkCircle,
          label: 'Approved',
        );
      case 'rejected':
        return _StatusConfig(
          color: AppColors.error,
          icon: LucideIcons.xCircle,
          label: 'Rejected',
        );
      case 'active':
        return _StatusConfig(
          color: AppColors.primary,
          icon: LucideIcons.shieldCheck,
          label: 'Active',
        );
      case 'expired':
        return _StatusConfig(
          color: AppColors.textSecondary,
          icon: LucideIcons.alertTriangle,
          label: 'Expired',
        );
      case 'expiring':
        return _StatusConfig(
          color: AppColors.warning,
          icon: LucideIcons.alertTriangle,
          label: 'Expiring Soon',
        );

      default:
        return _StatusConfig(
          color: AppColors.textSecondary,
          icon: LucideIcons.helpCircle,
          label: status,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
