/// EduX School Management System
/// Reusable loading indicator widget
library;

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// A reusable loading indicator with optional message
class AppLoadingIndicator extends StatelessWidget {
  /// Loading message to display
  final String? message;

  /// Size of the progress indicator
  final double size;

  /// Color of the progress indicator
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A loading overlay that covers the entire screen
class AppLoadingOverlay extends StatelessWidget {
  /// Loading message to display
  final String? message;

  /// Whether the overlay is visible
  final bool isLoading;

  /// Child widget
  final Widget child;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: AppLoadingIndicator(
              message: message,
              color: AppColors.textOnDark,
            ),
          ),
      ],
    );
  }
}
