/// EduX School Management System
/// Error state widget for displaying errors
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/theme.dart';

/// A widget to display when an error occurs
class AppErrorState extends StatelessWidget {
  /// Error message
  final String message;

  /// Custom title
  final String? title;

  /// Retry callback
  final VoidCallback? onRetry;

  /// Custom icon
  final IconData icon;

  /// Icon size
  final double iconSize;

  const AppErrorState({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon = LucideIcons.alertCircle,
    this.iconSize = 64,
  });

  /// Network error state
  const AppErrorState.network({super.key, this.onRetry})
    : message =
          'Unable to load data. Please check your connection and try again.',
      title = 'Connection Error',
      icon = LucideIcons.wifiOff,
      iconSize = 64;

  /// Generic error state
  const AppErrorState.generic({super.key, this.onRetry})
    : message = 'An unexpected error occurred. Please try again.',
      title = 'Something Went Wrong',
      icon = LucideIcons.alertCircle,
      iconSize = 64;

  /// Permission denied error
  const AppErrorState.permissionDenied({super.key})
    : message = 'You don\'t have permission to view this content.',
      title = 'Access Denied',
      icon = LucideIcons.lock,
      onRetry = null,
      iconSize = 64;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.errorBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? 'Error',
              style: AppTextStyles.emptyStateTitle.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.emptyStateMessage,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An inline error message widget
class AppErrorMessage extends StatelessWidget {
  /// Error message
  final String message;

  /// Dismiss callback
  final VoidCallback? onDismiss;

  const AppErrorMessage({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.errorDark,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(LucideIcons.x, size: 18, color: AppColors.error),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
