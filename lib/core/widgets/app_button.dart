/// EduX School Management System
/// Custom button widgets
library;

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Primary elevated button
class AppButton extends StatelessWidget {
  /// Button text
  final String text;

  /// On pressed callback
  final VoidCallback? onPressed;

  /// Leading icon
  final IconData? icon;

  /// Trailing icon
  final IconData? trailingIcon;

  /// Whether button is in loading state
  final bool isLoading;

  /// Whether button is expanded to full width
  final bool isExpanded;

  /// Button size
  final AppButtonSize size;

  /// Button variant
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = AppButtonSize.medium,
    this.variant = AppButtonVariant.primary,
  });

  /// Primary button
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.primary;

  /// Secondary/outlined button
  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.secondary;

  /// Text button
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.text;

  /// Danger/destructive button
  const AppButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.danger;

  /// Success button
  const AppButton.success({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.success;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final padding = _getPadding();
    final iconSize = _getIconSize();
    final textStyle = _getTextStyle();

    final textColor =
        variant == AppButtonVariant.primary ||
            variant == AppButtonVariant.danger ||
            variant == AppButtonVariant.success
        ? AppColors.textOnPrimary
        : AppColors.primary;

    Widget buttonChild = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else if (icon != null)
          Icon(icon, size: iconSize),
        if ((icon != null || isLoading) && text.isNotEmpty)
          SizedBox(width: size == AppButtonSize.small ? 6 : 8),
        if (text.isNotEmpty) Text(text, style: textStyle),
        if (trailingIcon != null && text.isNotEmpty)
          SizedBox(width: size == AppButtonSize.small ? 6 : 8),
        if (trailingIcon != null) Icon(trailingIcon, size: iconSize),
      ],
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStateProperty.all(padding),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStateProperty.all(padding),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStateProperty.all(padding),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textOnPrimary,
          ).copyWith(padding: WidgetStateProperty.all(padding)),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.success:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.textOnPrimary,
          ).copyWith(padding: WidgetStateProperty.all(padding)),
          child: buttonChild,
        );
        break;
    }

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  ButtonStyle _getButtonStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
      case AppButtonVariant.success:
        return ElevatedButton.styleFrom();
      case AppButtonVariant.secondary:
        return OutlinedButton.styleFrom();
      case AppButtonVariant.text:
        return TextButton.styleFrom();
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.buttonTextSmall;
      case AppButtonSize.medium:
      case AppButtonSize.large:
        return AppTextStyles.buttonText;
    }
  }
}

/// Button size options
enum AppButtonSize { small, medium, large }

/// Button variant options
enum AppButtonVariant { primary, secondary, text, danger, success }

/// Icon button with consistent styling
class AppIconButton extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// On pressed callback
  final VoidCallback? onPressed;

  /// Icon color
  final Color? color;

  /// Background color
  final Color? backgroundColor;

  /// Icon size
  final double size;

  /// Tooltip text
  final String? tooltip;

  /// Whether the button has a border
  final bool hasBorder;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 20,
    this.tooltip,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      icon: Icon(icon, size: size, color: color ?? AppColors.textSecondary),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        side: hasBorder ? const BorderSide(color: AppColors.border) : null,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
