/// EduX School Management System
/// Role Badge Widget - Colored badge for user roles
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';

/// A badge widget showing user role with appropriate color
class RoleBadge extends StatelessWidget {
  /// The role to display
  final String role;

  /// Badge size (small, medium, large)
  final RoleBadgeSize size;

  const RoleBadge({
    super.key,
    required this.role,
    this.size = RoleBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final roleInfo = _getRoleInfo(role);

    final padding = switch (size) {
      RoleBadgeSize.small => const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      RoleBadgeSize.medium => const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      RoleBadgeSize.large => const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
    };

    final textStyle = switch (size) {
      RoleBadgeSize.small => AppTextStyles.labelSmall,
      RoleBadgeSize.medium => AppTextStyles.labelMedium,
      RoleBadgeSize.large => AppTextStyles.labelLarge,
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: roleInfo.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: roleInfo.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        roleInfo.displayName,
        style: textStyle.copyWith(
          color: roleInfo.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _RoleInfo _getRoleInfo(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _RoleInfo('Admin', AppColors.error);
      case 'principal':
        return _RoleInfo('Principal', AppColors.info);
      case 'teacher':
        return _RoleInfo('Teacher', AppColors.success);
      case 'accountant':
        return _RoleInfo('Accountant', AppColors.warning);
      default:
        return _RoleInfo(role, AppColors.textSecondary);
    }
  }
}

class _RoleInfo {
  final String displayName;
  final Color color;

  _RoleInfo(this.displayName, this.color);
}

enum RoleBadgeSize { small, medium, large }
