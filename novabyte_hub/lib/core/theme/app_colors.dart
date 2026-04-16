/// NovaByte Hub — Color Palette
/// Premium dark theme colors for the admin app
library;

import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  AppColors._();

  // ── Background Layers ──
  /// Deep navy background
  static const Color background = Color(0xFF0A0E21);

  /// Elevated surface (cards, bottom sheets)
  static const Color surface = Color(0xFF1C2340);

  /// Lighter surface (input fields, hover states)
  static const Color surfaceLight = Color(0xFF252D4A);

  /// Highest elevation surface
  static const Color surfaceElevated = Color(0xFF2D3660);

  // ── Primary & Accent ──
  /// Electric blue primary
  static const Color primary = Color(0xFF4F7AFF);

  /// Primary with slight purple shift (for gradients)
  static const Color primaryDark = Color(0xFF3D5FCC);

  /// Purple accent (gradient end)
  static const Color accent = Color(0xFF7C4DFF);

  /// Cyan glow (highlights, badges)
  static const Color glow = Color(0xFF00E5FF);

  // ── Status Colors ──
  /// Success green
  static const Color success = Color(0xFF00E676);

  /// Warning amber
  static const Color warning = Color(0xFFFFD740);

  /// Error / danger red
  static const Color error = Color(0xFFFF5252);

  /// Info blue
  static const Color info = Color(0xFF40C4FF);

  // ── Text Colors ──
  /// Primary text (white)
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text (muted blue-grey)
  static const Color textSecondary = Color(0xFF8B95B3);

  /// Muted text (barely visible)
  static const Color textMuted = Color(0xFF555F7E);

  // ── Borders & Dividers ──
  /// Subtle border color
  static const Color border = Color(0xFF2A3256);

  /// Active border
  static const Color borderActive = Color(0xFF4F7AFF);

  // ── Gradient Definitions ──
  /// Primary gradient (blue to purple)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  /// Surface gradient (subtle depth)
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceLight],
  );

  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C853), success],
  );

  /// Warning gradient
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9100), warning],
  );

  /// Error gradient
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD50000), error],
  );

  /// Info gradient
  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, info],
  );

  // ── Helper Methods ──
  /// Get a color with custom opacity
  static Color withAlpha(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get status color for request status
  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return warning;
      case 'approved':
        return success;
      case 'rejected':
        return error;
      default:
        return textSecondary;
    }
  }

  /// Get status gradient for request status
  static LinearGradient getStatusGradient(String status) {
    switch (status) {
      case 'pending':
        return warningGradient;
      case 'approved':
        return successGradient;
      case 'rejected':
        return errorGradient;
      default:
        return surfaceGradient;
    }
  }
}
