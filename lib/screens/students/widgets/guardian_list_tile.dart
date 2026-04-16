/// EduX School Management System
/// Guardian List Tile - Display guardian info with actions
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/guardian_repository.dart';
import '../../../providers/guardian_provider.dart';

/// A tile widget to display guardian information with actions
class GuardianListTile extends ConsumerWidget {
  final StudentGuardianLink guardianLink;
  final int studentId;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const GuardianListTile({
    super.key,
    required this.guardianLink,
    required this.studentId,
    this.onEdit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final guardian = guardianLink.guardian;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getAvatarColor(guardianLink.isPrimary, theme),
                child: Text(
                  '${guardian.firstName[0]}${guardian.lastName[0]}'
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: guardianLink.isPrimary
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and badges row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            guardianLink.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (guardianLink.isPrimary)
                          _buildBadge('Primary', Colors.blue, theme),
                        if (guardianLink.isEmergencyContact) ...[
                          const SizedBox(width: 6),
                          _buildBadge('Emergency', Colors.red, theme),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Relation
                    Text(
                      guardian.relation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Contact info row
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(Icons.phone, guardian.phone, theme),
                        if (guardian.email != null)
                          _buildInfoChip(Icons.email, guardian.email!, theme),
                        if (guardian.occupation != null)
                          _buildInfoChip(
                            Icons.work,
                            guardian.occupation!,
                            theme,
                          ),
                      ],
                    ),

                    // Permissions row
                    if (guardianLink.canPickup) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Can pick up student',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleAction(context, ref, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'call',
                    child: ListTile(
                      leading: Icon(Icons.phone),
                      title: Text('Call'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (!guardianLink.isPrimary)
                    const PopupMenuItem(
                      value: 'set_primary',
                      child: ListTile(
                        leading: Icon(Icons.star),
                        title: Text('Set as Primary'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'unlink',
                    child: ListTile(
                      leading: Icon(Icons.link_off, color: Colors.orange),
                      title: Text(
                        'Unlink from Student',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Delete Guardian',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(bool isPrimary, ThemeData theme) {
    return isPrimary
        ? theme.colorScheme.primary
        : theme.colorScheme.primaryContainer;
  }

  Widget _buildBadge(String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    final guardian = guardianLink.guardian;

    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'call':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Call ${guardian.phone}')));
        break;
      case 'set_primary':
        _confirmSetPrimary(context, ref);
        break;
      case 'unlink':
        _confirmUnlink(context, ref);
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  Future<void> _confirmSetPrimary(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set as Primary Guardian'),
        content: Text('Set ${guardianLink.fullName} as the primary guardian?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Set Primary'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(guardianOperationProvider.notifier)
          .setPrimaryGuardian(studentId, guardianLink.guardian.id);
    }
  }

  Future<void> _confirmUnlink(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Guardian'),
        content: Text(
          'Remove ${guardianLink.fullName} from this student? '
          'The guardian record will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(guardianOperationProvider.notifier)
          .unlinkFromStudent(studentId, guardianLink.guardian.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardian unlinked'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Guardian'),
        content: Text(
          'Are you sure you want to delete ${guardianLink.fullName}? '
          'This will also remove them from all students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(guardianOperationProvider.notifier)
          .deleteGuardian(guardianLink.guardian.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardian deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Compact version of guardian tile for smaller spaces
class GuardianCompactTile extends StatelessWidget {
  final StudentGuardianLink guardianLink;
  final VoidCallback? onTap;

  const GuardianCompactTile({
    super.key,
    required this.guardianLink,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guardian = guardianLink.guardian;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: guardianLink.isPrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.primaryContainer,
        child: Text(
          '${guardian.firstName[0]}${guardian.lastName[0]}'.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: guardianLink.isPrimary
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(guardianLink.fullName),
      subtitle: Text(
        '${guardian.relation} • ${guardian.phone}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: guardianLink.isPrimary
          ? Icon(Icons.star, color: Colors.amber.shade600, size: 20)
          : null,
    );
  }
}
