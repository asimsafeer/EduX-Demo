/// EduX School Management System
/// Dashboard Alert Card Widget
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../router/app_router.dart';
import '../../../services/license_service.dart';

/// Alert card widget for dashboard alerts
class AlertCard extends StatelessWidget {
  final DashboardAlert alert;

  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getAlertStyle(alert.severity);

    return Card(
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: alert.actionRoute != null
            ? () => _handleTap(context)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (alert.actionRoute != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData) _getAlertStyle(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.info => (AppColors.info, LucideIcons.info),
      AlertSeverity.warning => (AppColors.warning, LucideIcons.alertTriangle),
      AlertSeverity.critical => (AppColors.error, LucideIcons.alertCircle),
    };
  }

  Future<void> _handleTap(BuildContext context) async {
    if (alert.actionRoute == null) return;

    // Check if the route requires a module
    final moduleId = _getModuleIdFromRoute(alert.actionRoute!);
    if (moduleId != null) {
      final isAccessible = await LicenseService.instance.isModuleAccessible(moduleId);
      if (!context.mounted) return;
      
      if (!isAccessible) {
        _showModuleLockedDialog(context, moduleId);
        return;
      }
    }
    
    context.push(alert.actionRoute!);
  }

  String? _getModuleIdFromRoute(String route) {
    if (route.startsWith('/students')) return 'student_management';
    if (route.startsWith('/staff')) return 'staff_management';
    if (route.startsWith('/fees')) return 'fee_management';
    if (route.startsWith('/attendance')) return 'attendance_tracking';
    if (route.startsWith('/exams')) return 'exam_management';
    if (route.startsWith('/reports')) return 'reporting';
    if (route.startsWith('/expenses')) return 'expense_tracking';
    if (route.startsWith('/canteen')) return 'canteen_management';
    if (route.startsWith('/academics')) return 'academic_management';
    return null;
  }

  void _showModuleLockedDialog(BuildContext context, String moduleId) {
    final module = EduXModules.byId(moduleId);
    final moduleName = module?.name ?? 'This feature';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(LucideIcons.lock, color: AppColors.error, size: 48),
        title: Text('$moduleName Locked'),
        content: const Text(
          'This feature requires an active license. Please request a license to unlock this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.requestLicense);
            },
            child: const Text('Request License'),
          ),
        ],
      ),
    );
  }
}

/// Section widget for alerts list
class AlertsSection extends StatelessWidget {
  final List<DashboardAlert> alerts;

  const AlertsSection({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.checkCircle2,
                size: 40,
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              Text(
                'All caught up!',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'No alerts at this time',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => AlertCard(alert: alerts[index]),
    );
  }
}
