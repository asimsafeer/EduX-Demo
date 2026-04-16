/// EduX School Management System
/// Backup Screen - Backup and restore management
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../providers/providers.dart';

import '../widgets/widgets.dart';

/// Screen for managing backups and restore
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isCreatingBackup = false;
  bool _isRestoring = false;

  Future<void> _createBackup() async {
    final description = await _showDescriptionDialog();
    if (description == null) return;

    setState(() => _isCreatingBackup = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final activityLog = ref.read(activityLogServiceProvider);
      final currentUser = ref.read(currentUserProvider);

      final backup = await backupService.createBackup(
        description: description.isEmpty ? null : description,
        type: 'manual',
      );

      await activityLog.logBackup(
        userId: currentUser?.id,
        description: 'Created manual backup: ${backup.fileName}',
        details: {
          'fileName': backup.fileName,
          'fileSize': backup.fileSize,
          'studentCount': backup.studentCount,
          'staffCount': backup.staffCount,
        },
      );

      ref.invalidate(backupListProvider);
      ref.invalidate(backupCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created: ${backup.fileName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating backup: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingBackup = false);
      }
    }
  }

  Future<String?> _showDescriptionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add an optional description for this backup:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., Before report card distribution',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(int backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Confirm Restore'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to restore this backup?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'This will replace all current data. The app will need to restart after restoration.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final activityLog = ref.read(activityLogServiceProvider);
      final currentUser = ref.read(currentUserProvider);
      final backup = await backupService.getBackupById(backupId);

      await activityLog.logRestore(
        userId: currentUser?.id,
        description: 'Restored from backup: ${backup?.fileName}',
      );

      await backupService.restoreBackup(backupId);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Restore Complete'),
            content: const Text(
              'The backup has been restored. Please restart the application for changes to take effect.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring backup: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _exportBackup(int backupId) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;

    try {
      final backupService = ref.read(backupServiceProvider);
      final file = await backupService.exportBackup(backupId, result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup exported to: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting backup: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.isEmpty) return;

    try {
      final backupService = ref.read(backupServiceProvider);
      final activityLog = ref.read(activityLogServiceProvider);
      final currentUser = ref.read(currentUserProvider);

      final backup = await backupService.importBackup(result.files.first.path!);

      await activityLog.logBackup(
        userId: currentUser?.id,
        description: 'Imported backup: ${backup.fileName}',
      );

      ref.invalidate(backupListProvider);
      ref.invalidate(backupCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup imported: ${backup.fileName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing backup: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteBackup(int backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: const Text(
          'This will permanently delete this backup. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.deleteBackup(backupId);

      ref.invalidate(backupListProvider);
      ref.invalidate(backupCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting backup: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupsAsync = ref.watch(backupListProvider);
    final recentBackup = ref.watch(mostRecentBackupProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats card
                  _buildStatsCard(recentBackup),
                  const SizedBox(height: 24),

                  // Actions
                  _buildActions(),
                  const SizedBox(height: 24),

                  // Backup list
                  Text(
                    'Backups',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  backupsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (backups) => backups.isEmpty
                        ? _buildEmptyState()
                        : _buildBackupList(backups),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup & Restore',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Protect your data with backups',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<dynamic> recentBackup) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.hardDrive,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Backup',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                recentBackup.when(
                  loading: () => Text(
                    'Loading...',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  error: (_, __) => Text(
                    'Unable to load',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  data: (backup) => backup == null
                      ? Text(
                          'No backups yet',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _formatRelativeTime(backup.createdAt),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: _isCreatingBackup || _isRestoring ? null : _createBackup,
          icon: _isCreatingBackup
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.archive, size: 18),
          label: const Text('Create Backup'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _isCreatingBackup || _isRestoring ? null : _importBackup,
          icon: const Icon(LucideIcons.upload, size: 18),
          label: const Text('Import Backup'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupList(List<dynamic> backups) {
    return Column(
      children: backups.map((backup) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BackupListTile(
            backup: backup,
            onRestore: _isRestoring ? null : () => _restoreBackup(backup.id),
            onExport: () => _exportBackup(backup.id),
            onDelete: () => _deleteBackup(backup.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(LucideIcons.archive, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No backups yet',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first backup to protect your data',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}
