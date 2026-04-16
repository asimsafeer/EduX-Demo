/// EduX School Management System
/// Module Gate Widget — Controls access to features based on license status
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../core.dart';
import '../../router/app_router.dart';
import '../../services/license_service.dart';

/// Wraps a child widget and only shows it if the module is accessible.
///
/// Only licensed modules are shown.
class ModuleGate extends StatelessWidget {
  /// The module ID to check (from [EduXModules]).
  final String moduleId;

  /// Widget shown when module is accessible.
  final Widget child;

  /// Optional custom locked widget. Defaults to a premium upsell card.
  final Widget? lockedWidget;

  const ModuleGate({
    super.key,
    required this.moduleId,
    required this.child,
    this.lockedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LicenseService.instance.isModuleAccessible(moduleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final isAccessible = snapshot.data ?? false;
        if (isAccessible) return child;

        return lockedWidget ?? _DefaultLockedScreen(moduleId: moduleId);
      },
    );
  }
}

/// Default locked screen shown when a module is not accessible.
class _DefaultLockedScreen extends StatelessWidget {
  final String moduleId;

  const _DefaultLockedScreen({required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final module = EduXModules.byId(moduleId);
    final moduleName = module?.name ?? 'This Module';
    final moduleColor = module?.color ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon with animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (value * 0.5),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: moduleColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.lock,
                        size: 48,
                        color: moduleColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                '$moduleName is Locked',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: FutureBuilder<AppLicenseStatus>(
                  future: LicenseService.instance.getAppStatus(),
                  builder: (context, snapshot) {
                    final status = snapshot.data;

                    if (status == AppLicenseStatus.pendingRequest) {
                      return Text(
                        'Your license request is pending approval. '
                        'You\'ll be notified once approved.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }

                    return Text(
                      'This module requires an active license. '
                      'Please request a license to unlock this feature.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton.primary(
                    text: 'Request License',
                    icon: LucideIcons.shieldCheck,
                    onPressed: () {
                      context.push(AppRoutes.requestLicense);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that shows a lock badge on the child if the module is locked.
/// Useful for sidebar navigation items.
class ModuleLockBadge extends StatelessWidget {
  final String moduleId;
  final Widget child;

  const ModuleLockBadge({
    super.key,
    required this.moduleId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LicenseService.instance.isModuleAccessible(moduleId),
      builder: (context, snapshot) {
        final isAccessible = snapshot.data ?? false;
        if (isAccessible) return child;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(
                  LucideIcons.lock,
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
