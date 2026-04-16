/// EduX School Management System
/// Toast Notification Utility
library;

import 'package:flutter/material.dart';

/// Toast notification types
enum ToastType { success, error, warning, info }

/// Toast notification configuration
class ToastConfig {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback? action;
  final String? actionLabel;

  const ToastConfig({
    required this.message,
    this.type = ToastType.info,
    this.duration = const Duration(seconds: 3),
    this.action,
    this.actionLabel,
  });
}

/// Toast notification service for showing snackbar-style notifications
class AppToast {
  AppToast._();

  /// Show a success toast
  static void success(
    BuildContext context,
    String message, {
    VoidCallback? action,
    String? actionLabel,
  }) {
    _show(
      context,
      ToastConfig(
        message: message,
        type: ToastType.success,
        action: action,
        actionLabel: actionLabel,
      ),
    );
  }

  /// Show an error toast
  static void error(
    BuildContext context,
    String message, {
    VoidCallback? action,
    String? actionLabel,
  }) {
    _show(
      context,
      ToastConfig(
        message: message,
        type: ToastType.error,
        duration: const Duration(seconds: 4),
        action: action,
        actionLabel: actionLabel,
      ),
    );
  }

  /// Show a warning toast
  static void warning(
    BuildContext context,
    String message, {
    VoidCallback? action,
    String? actionLabel,
  }) {
    _show(
      context,
      ToastConfig(
        message: message,
        type: ToastType.warning,
        action: action,
        actionLabel: actionLabel,
      ),
    );
  }

  /// Show an info toast
  static void info(
    BuildContext context,
    String message, {
    VoidCallback? action,
    String? actionLabel,
  }) {
    _show(
      context,
      ToastConfig(
        message: message,
        type: ToastType.info,
        action: action,
        actionLabel: actionLabel,
      ),
    );
  }

  /// Show a custom toast
  static void show(BuildContext context, ToastConfig config) {
    _show(context, config);
  }

  static void _show(BuildContext context, ToastConfig config) {
    // Remove any existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final scheme = Theme.of(context).colorScheme;
    final (bgColor, fgColor, icon) = _getColors(config.type, scheme);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: fgColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(config.message, style: TextStyle(color: fgColor)),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: config.duration,
        action: config.action != null && config.actionLabel != null
            ? SnackBarAction(
                label: config.actionLabel!,
                textColor: fgColor,
                onPressed: config.action!,
              )
            : null,
      ),
    );
  }

  static (Color, Color, IconData) _getColors(
    ToastType type,
    ColorScheme scheme,
  ) {
    return switch (type) {
      ToastType.success => (
        const Color(0xFF1B5E20),
        Colors.white,
        Icons.check_circle_outline,
      ),
      ToastType.error => (scheme.error, scheme.onError, Icons.error_outline),
      ToastType.warning => (
        const Color(0xFFF57C00),
        Colors.white,
        Icons.warning_amber_outlined,
      ),
      ToastType.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.info_outline,
      ),
    };
  }
}
