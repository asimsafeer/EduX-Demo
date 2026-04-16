/// EduX School Management System
/// Confirmation Dialog Utility
library;

import 'package:flutter/material.dart';

/// Confirmation dialog result
enum ConfirmResult { confirm, cancel }

/// Pre-configured dialog types
enum ConfirmDialogType { delete, discard, logout, custom }

/// Confirmation dialog utility class
class ConfirmDialog {
  ConfirmDialog._();

  /// Show a delete confirmation dialog
  static Future<bool> delete(
    BuildContext context, {
    required String itemName,
    String? description,
  }) async {
    return await show(
      context,
      title: 'Delete $itemName?',
      message:
          description ??
          'This action cannot be undone. Are you sure you want to delete this $itemName?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
  }

  /// Show a discard changes confirmation
  static Future<bool> discardChanges(BuildContext context) async {
    return await show(
      context,
      title: 'Discard Changes?',
      message:
          'You have unsaved changes. Are you sure you want to discard them?',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
  }

  /// Show a logout confirmation
  static Future<bool> logout(BuildContext context) async {
    return await show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
    );
  }

  /// Show a custom confirmation dialog
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<ConfirmResult>(
      context: context,
      builder: (context) => _ConfirmDialogWidget(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result == ConfirmResult.confirm;
  }
}

class _ConfirmDialogWidget extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  const _ConfirmDialogWidget({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dialogIcon =
        icon ??
        (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline);
    final iconColor = isDestructive ? scheme.error : scheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(dialogIcon, color: iconColor, size: 28),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop(ConfirmResult.cancel),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(ConfirmResult.confirm),
                style: FilledButton.styleFrom(
                  backgroundColor: isDestructive
                      ? scheme.error
                      : scheme.primary,
                  foregroundColor: isDestructive
                      ? scheme.onError
                      : scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
