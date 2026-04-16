/// EduX Teacher App - Settings Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(currentTeacherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          _buildProfileSection(context, teacher),

          const Divider(),

          // App Settings
          _buildSectionHeader(context, 'App Settings'),
          _buildSettingTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Coming soon',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.fingerprint,
            title: 'Biometric Lock',
            subtitle: 'Secure app with fingerprint',
            trailing: _buildBiometricToggle(ref),
          ),

          const Divider(),

          // Data Section
          _buildSectionHeader(context, 'Data'),
          _buildSettingTile(
            context,
            icon: Icons.storage_outlined,
            title: 'Storage Usage',
            subtitle: 'View database statistics',
            onTap: () => _showStorageInfo(context, ref),
          ),
          _buildSettingTile(
            context,
            icon: Icons.sync_outlined,
            title: 'Sync Settings',
            subtitle: 'Configure sync behavior',
            onTap: () {},
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildSettingTile(
            context,
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
          ),
          _buildSettingTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get assistance',
            onTap: () => _showHelpDialog(context),
          ),
          _buildSettingTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),

          const Divider(),

          // Danger Zone
          _buildSectionHeader(context, 'Danger Zone', color: AppTheme.error),
          _buildSettingTile(
            context,
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove synced attendance records',
            textColor: AppTheme.error,
            onTap: () => _showClearCacheDialog(context, ref),
          ),
          _buildSettingTile(
            context,
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out and clear all data',
            textColor: AppTheme.error,
            onTap: () => _showLogoutDialog(context, ref),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, dynamic teacher) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryLight,
            backgroundImage: teacher?.photoUrl != null
                ? NetworkImage(teacher.photoUrl!)
                : null,
            child: teacher?.photoUrl == null
                ? Text(
                    teacher?.name.substring(0, 1).toUpperCase() ?? 'T',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher?.name ?? 'Teacher',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  teacher?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color ?? AppTheme.textTertiary,
              letterSpacing: 1,
            ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: textColor?.withValues(alpha: 0.7)),
            )
          : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  Widget _buildBiometricToggle(WidgetRef ref) {
    final deviceService = ref.watch(deviceServiceProvider);

    return FutureBuilder<bool>(
      future: deviceService.isBiometricAvailable(),
      builder: (context, snapshot) {
        final isAvailable = snapshot.data ?? false;

        if (!isAvailable) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<bool>(
          future: deviceService.isBiometricEnabled(),
          builder: (context, enabledSnapshot) {
            final isEnabled = enabledSnapshot.data ?? false;

            return Switch(
              value: isEnabled,
              onChanged: (value) async {
                await deviceService.setBiometricEnabled(value);
                ref.invalidate(deviceServiceProvider);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showStorageInfo(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final stats = await db.getDatabaseStats();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Usage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Cached Classes', '${stats['classes']}'),
              _buildStatRow('Cached Students', '${stats['students']}'),
              _buildStatRow('Pending Records', '${stats['pending']}'),
              _buildStatRow('Synced Records', '${stats['synced']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _showHelpDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For assistance, please contact your school administrator or IT support.',
            ),
            SizedBox(height: 16),
            Text('Common issues:'),
            SizedBox(height: 8),
            Text('• Ensure you\'re connected to school WiFi'),
            Text('• Verify server is running on the main system'),
            Text('• Check your username and password'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearCacheDialog(
      BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will remove all synced attendance records from your device. Pending records will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await db.deleteOldSyncedAttendance(0);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'This will sign you out and remove all data from this device. Any unsynced attendance will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Check for pending attendance
      final db = ref.read(databaseProvider);
      final pendingCount = await db.getPendingCount();

      if (pendingCount > 0 && context.mounted) {
        final forceLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsynced Data'),
            content: Text(
              'You have $pendingCount unsynced attendance records. These will be lost if you logout.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout Anyway'),
              ),
            ],
          ),
        );

        if (forceLogout != true) {
          return;
        }
      }

      await ref.read(authProvider.notifier).logout();
    }
  }
}
