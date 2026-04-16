/// EduX School Management System
/// Context and Widget utility extensions
library;

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Extension methods for BuildContext
extension ContextExtensions on BuildContext {
  // ============================================
  // THEME ACCESS
  // ============================================

  /// Get current theme data
  ThemeData get theme => Theme.of(this);

  /// Get current color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Get current text theme
  TextTheme get textTheme => theme.textTheme;

  // ============================================
  // MEDIA QUERY ACCESS
  // ============================================

  /// Get media query data
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => mediaQuery.size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Get screen padding (safe area)
  EdgeInsets get screenPadding => mediaQuery.padding;

  /// Get view insets (keyboard, etc.)
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  // ============================================
  // RESPONSIVE BREAKPOINTS
  // ============================================

  /// Check if screen is mobile size (< 600)
  bool get isMobile => screenWidth < 600;

  /// Check if screen is tablet size (600-900)
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;

  /// Check if screen is desktop size (>= 900)
  bool get isDesktop => screenWidth >= 900;

  /// Check if screen is large desktop (>= 1200)
  bool get isLargeDesktop => screenWidth >= 1200;

  // ============================================
  // SNACKBARS
  // ============================================

  /// Show a snackbar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration, action: action),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.textOnDark),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: AppColors.textOnDark),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show warning snackbar
  void showWarningSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar
  void showInfoSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: AppColors.textOnDark),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================
  // DIALOGS
  // ============================================

  /// Show a confirmation dialog
  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show a delete confirmation dialog
  Future<bool> showDeleteConfirmDialog({
    String title = 'Delete Confirmation',
    String? itemName,
    String? message,
  }) {
    return showConfirmDialog(
      title: title,
      message:
          message ??
          'Are you sure you want to delete${itemName != null ? ' "$itemName"' : ' this item'}? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
  }

  /// Show loading dialog
  void showLoadingDialog({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Expanded(child: Text(message ?? 'Please wait...')),
            ],
          ),
        ),
      ),
    );
  }

  /// Hide current dialog
  void hideDialog() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }

  // ============================================
  // FOCUS
  // ============================================

  /// Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Request focus on a node
  void requestFocus(FocusNode node) {
    FocusScope.of(this).requestFocus(node);
  }
}
