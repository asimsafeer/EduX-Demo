/// EduX School Management System
/// Payment mode icon and color helpers for consistent UI
library;

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Helper class for payment mode UI elements
class PaymentModeHelper {
  PaymentModeHelper._();

  /// Get icon data for payment mode
  static IconData getIcon(String mode) {
    switch (mode) {
      case FeeConstants.paymentModeCash:
        return Icons.money;
      case FeeConstants.paymentModeBank:
        return Icons.account_balance;
      case FeeConstants.paymentModeCheque:
        return Icons.article;
      case FeeConstants.paymentModeOnline:
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  /// Get color for payment mode
  static Color getColor(String mode) {
    switch (mode) {
      case FeeConstants.paymentModeCash:
        return Colors.green;
      case FeeConstants.paymentModeBank:
        return Colors.blue;
      case FeeConstants.paymentModeCheque:
        return Colors.orange;
      case FeeConstants.paymentModeOnline:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get display name for payment mode
  static String getDisplayName(String mode) {
    return FeeConstants.getPaymentModeDisplayName(mode);
  }

  /// Build an icon widget with background for payment mode
  static Widget buildIconWidget(
    String mode, {
    double size = 24,
    double? backgroundSize,
    EdgeInsets? padding,
  }) {
    final color = getColor(mode);
    final iconData = getIcon(mode);
    final bgSize = backgroundSize ?? size * 2;

    return Container(
      width: bgSize,
      height: bgSize,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(bgSize / 4),
      ),
      child: Icon(
        iconData,
        color: color,
        size: size,
      ),
    );
  }

  /// Build a chip widget for payment mode
  static Widget buildChip(
    String mode, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final color = getColor(mode);
    final displayName = getDisplayName(mode);
    final iconData = getIcon(mode);

    return FilterChip(
      selected: isSelected,
      label: Text(displayName),
      onSelected: onTap != null ? (_) => onTap() : null,
      avatar: Icon(
        iconData,
        size: 18,
        color: isSelected ? Colors.white : color,
      ),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }
}

/// Extension on String for payment mode helpers
extension PaymentModeStringExtension on String {
  /// Get icon data for this payment mode
  IconData get paymentModeIcon => PaymentModeHelper.getIcon(this);

  /// Get color for this payment mode
  Color get paymentModeColor => PaymentModeHelper.getColor(this);

  /// Get display name for this payment mode
  String get paymentModeDisplayName => PaymentModeHelper.getDisplayName(this);
}
