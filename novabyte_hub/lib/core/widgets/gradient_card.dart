/// NovaByte Hub — Glassmorphism Gradient Card
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A premium glassmorphism card with frosted glass effect and optional gradient border.
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient? gradient;
  final bool showBorder;
  final VoidCallback? onTap;
  final double blurAmount;

  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
    this.gradient,
    this.showBorder = true,
    this.onTap,
    this.blurAmount = 12,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppColors.primaryGradient;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: showBorder ? effectiveGradient : null,
        ),
        padding: showBorder ? const EdgeInsets.all(1) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            showBorder ? borderRadius - 1 : borderRadius,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(
                  showBorder ? borderRadius - 1 : borderRadius,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A variant with a solid gradient background (for stat cards, hero sections).
class GradientBackgroundCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient gradient;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const GradientBackgroundCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
    this.gradient = AppColors.primaryGradient,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow:
              shadows ??
              [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        ),
        child: child,
      ),
    );
  }
}
