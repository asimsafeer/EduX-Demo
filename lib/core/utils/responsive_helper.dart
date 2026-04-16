/// EduX School Management System
/// Responsive layout utilities for adaptive UI across different window sizes
library;

import 'package:flutter/material.dart';

/// Responsive breakpoint helper for consistent adaptive layouts
class ResponsiveHelper {
  ResponsiveHelper._();

  // ============================================
  // BREAKPOINTS
  // ============================================

  /// Compact: sidebar collapsed, single-column layouts
  static const double compactBreakpoint = 800;

  /// Medium: two-column layouts, reduced grid counts
  static const double mediumBreakpoint = 1100;

  /// Expanded: full desktop layout, max grid columns
  static const double expandedBreakpoint = 1400;

  // ============================================
  // BREAKPOINT CHECKS
  // ============================================

  /// Whether the width is compact (< 800)
  static bool isCompact(double width) => width < compactBreakpoint;

  /// Whether the width is medium (800–1100)
  static bool isMedium(double width) =>
      width >= compactBreakpoint && width < mediumBreakpoint;

  /// Whether the width is expanded (>= 1100)
  static bool isExpanded(double width) => width >= mediumBreakpoint;

  // ============================================
  // RESPONSIVE VALUE SELECTOR
  // ============================================

  /// Returns the appropriate value based on available width.
  ///
  /// [compact] is used when width < 800.
  /// [medium] is used when width is 800–1100 (falls back to [compact] if null).
  /// [expanded] is used when width >= 1100 (falls back to [medium] then [compact]).
  static T value<T>(
    double width, {
    required T compact,
    T? medium,
    T? expanded,
  }) {
    if (width >= mediumBreakpoint) {
      return expanded ?? medium ?? compact;
    } else if (width >= compactBreakpoint) {
      return medium ?? compact;
    }
    return compact;
  }

  // ============================================
  // GRID HELPERS
  // ============================================

  /// Calculate optimal grid column count based on width.
  ///
  /// [minItemWidth] is the minimum width each grid item should have.
  /// [maxColumns] caps the column count.
  /// [minColumns] is the floor (defaults to 1).
  static int columns(
    double width, {
    double minItemWidth = 250,
    int maxColumns = 4,
    int minColumns = 1,
  }) {
    final count = (width / minItemWidth).floor();
    return count.clamp(minColumns, maxColumns);
  }

  // ============================================
  // SIDEBAR HELPERS
  // ============================================

  /// Whether the sidebar should be auto-collapsed at this width.
  /// Returns true when the content area width is narrow enough that
  /// an expanded sidebar would cramp the main content.
  static bool shouldCollapseSidebar(double totalWidth) => totalWidth < 1000;

  // ============================================
  // PADDING HELPERS
  // ============================================

  /// Responsive page padding — smaller on compact screens.
  static EdgeInsets pagePadding(double width) {
    if (width < compactBreakpoint) {
      return const EdgeInsets.all(12);
    } else if (width < mediumBreakpoint) {
      return const EdgeInsets.all(16);
    }
    return const EdgeInsets.all(24);
  }
}
