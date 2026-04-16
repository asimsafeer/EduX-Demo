/// EduX School Management System
/// Settings Screen - Main settings navigation
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../../../providers/providers.dart';
import '../../../router/app_router.dart';
import '../../../sync/sync.dart';
import '../widgets/widgets.dart';

/// Main settings screen with navigation to settings sections
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final schoolSettings = ref.watch(schoolSettingsProvider);
    final userCount = ref.watch(totalUserCountProvider);
    final backupCount = ref.watch(backupCountProvider);
    final deviceCount = ref.watch(deviceCountProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 24),

            // Settings sections
            _buildSectionTitle('School'),
            const SizedBox(height: 12),
            SettingsCard(
              icon: LucideIcons.building2,
              title: 'School Profile',
              subtitle: schoolSettings.when(
                data: (settings) =>
                    settings?.schoolName ?? 'Configure school information',
                loading: () => 'Loading...',
                error: (_, __) => 'Configure school information',
              ),
              onTap: () => context.push(AppRoutes.schoolProfile),
            ),
            if (!DemoConfig.isDemo) ...[
              const SizedBox(height: 12),
              SettingsCard(
                icon: LucideIcons.shieldCheck,
                title: 'License & Plan',
                subtitle: 'View your current plan or request an upgrade',
                onTap: () => context.push(AppRoutes.requestLicense),
              ),
            ],
            const SizedBox(height: 12),
            SettingsCard(
              icon: LucideIcons.calendar,
              title: 'Academic Settings',
              subtitle: 'Manage academic years and sessions',
              onTap: () => context.push('${AppRoutes.settings}/academic'),
            ),
            const SizedBox(height: 24),

            // Administration section (admin only)
            if (permissions.canManageUsers) ...[
              _buildSectionTitle('Administration'),
              const SizedBox(height: 12),
              SettingsCard(
                icon: LucideIcons.users,
                title: 'User Management',
                subtitle: 'Manage user accounts and roles',
                badge: userCount.when(
                  data: (count) => '$count',
                  loading: () => null,
                  error: (_, __) => null,
                ),
                onTap: () => context.push(AppRoutes.users),
              ),
              const SizedBox(height: 12),
              SettingsCard(
                icon: LucideIcons.history,
                title: 'Activity Log',
                subtitle: 'View system activity and audit trail',
                onTap: () => context.push('${AppRoutes.settings}/activity-log'),
              ),
              const SizedBox(height: 12),
              SettingsCard(
                icon: LucideIcons.smartphone,
                title: 'Connected Devices',
                subtitle: 'Manage teacher mobile app connections',
                badge: deviceCount.when(
                  data: (count) => '$count',
                  loading: () => null,
                  error: (_, __) => null,
                ),
                onTap: () => context.push(AppRoutes.syncDevices),
              ),

              const SizedBox(height: 24),
            ],

            // Data section (admin only)
            if (permissions.canManageBackups) ...[
              _buildSectionTitle('Data'),
              const SizedBox(height: 12),
              SettingsCard(
                icon: LucideIcons.hardDrive,
                title: 'Backup & Restore',
                subtitle: 'Create backups and restore data',
                badge: backupCount.when(
                  data: (count) => '$count',
                  loading: () => null,
                  error: (_, __) => null,
                ),
                onTap: () => context.push(AppRoutes.backup),
              ),
              const SizedBox(height: 24),
            ],

            // Print Settings (for future)
            _buildSectionTitle('Print'),
            const SizedBox(height: 12),
            SettingsCard(
              icon: LucideIcons.printer,
              title: 'Print Settings',
              subtitle: 'Configure receipts and report formats',
              onTap: () => context.push(AppRoutes.printSettings),
            ),
            const SizedBox(height: 24),

            // Support section
            _buildSectionTitle('Support'),
            const SizedBox(height: 12),
            SettingsCard(
              icon: LucideIcons.headphones,
              title: 'Help & Support',
              subtitle: 'Contact ${NovaByteContact.companyName} for assistance',
              onTap: () => _showSupportDialog(context),
            ),
            const SizedBox(height: 24),

            // Application info
            _buildSectionTitle('About'),
            const SizedBox(height: 12),
            _buildAboutCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure your school management system',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icon.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appFullName,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.code, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Powered by Nova Byte',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const _SupportDialog());
  }
}

// ─────────────────────────────────────────────────────────────
//  Support Dialog
// ─────────────────────────────────────────────────────────────

class _SupportDialog extends StatelessWidget {
  const _SupportDialog();

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  LucideIcons.headphones,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Help & Support',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reach out to ${NovaByteContact.companyName} for any help,\nupgrades, or technical support.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Contact options
              _buildContactTile(
                context,
                icon: LucideIcons.messageCircle,
                label: 'WhatsApp',
                value: NovaByteContact.phoneDisplay,
                color: const Color(0xFF25D366),
                onTap: () => _launchUrl(
                  'https://wa.me/${NovaByteContact.whatsApp.replaceAll("+", "")}',
                ),
              ),
              const SizedBox(height: 10),
              _buildContactTile(
                context,
                icon: LucideIcons.mail,
                label: 'Email',
                value: NovaByteContact.email,
                color: AppColors.info,
                onTap: () => _launchUrl(
                  'mailto:${NovaByteContact.email}?subject=EduX Support',
                ),
              ),
              const SizedBox(height: 10),
              _buildContactTile(
                context,
                icon: LucideIcons.phone,
                label: 'Phone',
                value: NovaByteContact.phoneDisplay,
                color: AppColors.success,
                onTap: () => _launchUrl('tel:${NovaByteContact.whatsApp}'),
              ),
              const SizedBox(height: 10),
              _buildContactTile(
                context,
                icon: LucideIcons.globe,
                label: 'Website',
                value: 'novabyte.studio',
                color: AppColors.primary,
                onTap: () => _launchUrl(NovaByteContact.website),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.externalLink,
                size: 16,
                color: color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
