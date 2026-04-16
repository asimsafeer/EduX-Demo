/// EduX School Management System
/// Role Guard Widget - Conditionally show content based on user role/permissions
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/rbac_service.dart';
import '../../providers/auth_provider.dart';

/// Widget that only displays its child if the user has the required permission/role
class RoleGuard extends ConsumerWidget {
  /// The child widget to display if permitted
  final Widget child;

  /// The fallback widget to display if access is denied (optional)
  final Widget? fallback;

  /// Specific permission required (preferred)
  final String? permission;

  /// Specific role required (use permission instead if possible)
  final String? role;

  /// If true, will check if user has ANY of the permissions (if input is list, simplified here to single)
  // For now we keep it simple: single permission or role check.

  const RoleGuard({
    super.key,
    required this.child,
    this.fallback,
    this.permission,
    this.role,
  }) : assert(
         permission != null || role != null,
         'Must provide permission or role',
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    if (user == null) {
      return fallback ?? const SizedBox.shrink();
    }

    bool hasAccess = false;

    if (permission != null) {
      hasAccess = rbacService.hasPermission(user, permission!);
    } else if (role != null) {
      // Direct role check (legacy support, avoid using if possible)
      hasAccess = user.role == role || user.isSystemAdmin;
    }

    if (hasAccess) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
