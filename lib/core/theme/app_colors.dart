/// EduX School Management System
/// Application color palette and color utilities
library;

import 'package:flutter/material.dart';

/// Application color palette
/// Professional color scheme designed for educational software
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY COLORS
  // ============================================

  /// Primary brand color - Deep Blue
  static const Color primary = Color(0xFF1E3A5F);

  /// Primary color light variant
  static const Color primaryLight = Color(0xFF2E5077);

  /// Primary color dark variant
  static const Color primaryDark = Color(0xFF0F2847);

  /// Primary color with specific opacity levels
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);

  // ============================================
  // SECONDARY COLORS
  // ============================================

  /// Secondary color - Teal
  static const Color secondary = Color(0xFF0D9488);

  /// Secondary color light variant
  static const Color secondaryLight = Color(0xFF14B8A6);

  /// Secondary color dark variant
  static const Color secondaryDark = Color(0xFF0A7A70);

  // ============================================
  // ACCENT COLORS
  // ============================================

  /// Accent color - Amber for highlights
  static const Color accent = Color(0xFFF59E0B);

  /// Accent color light variant
  static const Color accentLight = Color(0xFFFBBF24);

  /// Accent color dark variant
  static const Color accentDark = Color(0xFFD97706);

  // ============================================
  // BACKGROUND COLORS
  // ============================================

  /// Main background color - Light slate
  static const Color background = Color(0xFFF8FAFC);

  /// Surface color - White
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface variant - Slightly darker
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  /// Card background color
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Dialog background color
  static const Color dialogBackground = Color(0xFFFFFFFF);

  /// Sidebar background color
  static const Color sidebarBackground = Color(0xFF1E293B);

  /// Sidebar item hover color
  static const Color sidebarHover = Color(0xFF334155);

  // ============================================
  // STATUS COLORS
  // ============================================

  /// Success color - Green
  static const Color success = Color(0xFF22C55E);

  /// Success color light variant
  static const Color successLight = Color(0xFF86EFAC);

  /// Success color dark variant
  static const Color successDark = Color(0xFF16A34A);

  /// Success background for alerts
  static const Color successBackground = Color(0xFFDCFCE7);

  /// Warning color - Amber
  static const Color warning = Color(0xFFF59E0B);

  /// Warning color light variant
  static const Color warningLight = Color(0xFFFCD34D);

  /// Warning color dark variant
  static const Color warningDark = Color(0xFFD97706);

  /// Warning background for alerts
  static const Color warningBackground = Color(0xFFFEF3C7);

  /// Error color - Red
  static const Color error = Color(0xFFEF4444);

  /// Error color light variant
  static const Color errorLight = Color(0xFFFCA5A5);

  /// Error color dark variant
  static const Color errorDark = Color(0xFFDC2626);

  /// Error background for alerts
  static const Color errorBackground = Color(0xFFFEE2E2);

  /// Info color - Blue
  static const Color info = Color(0xFF3B82F6);

  /// Info color light variant
  static const Color infoLight = Color(0xFF93C5FD);

  /// Info color dark variant
  static const Color infoDark = Color(0xFF2563EB);

  /// Info background for alerts
  static const Color infoBackground = Color(0xFFDBEAFE);

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Primary text color - Dark slate
  static const Color textPrimary = Color(0xFF1E293B);

  /// Secondary text color - Medium slate
  static const Color textSecondary = Color(0xFF64748B);

  /// Tertiary text color - Light slate
  static const Color textTertiary = Color(0xFF94A3B8);

  /// Disabled text color
  static const Color textDisabled = Color(0xFFCBD5E1);

  /// Text on primary color
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text on secondary color
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  /// Text on dark surfaces
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Hint text color
  static const Color textHint = Color(0xFF94A3B8);

  // ============================================
  // BORDER COLORS
  // ============================================

  /// Default border color
  static const Color border = Color(0xFFE2E8F0);

  /// Dark border color
  static const Color borderDark = Color(0xFFCBD5E1);

  /// Light border color
  static const Color borderLight = Color(0xFFF1F5F9);

  /// Focus border color
  static const Color borderFocus = Color(0xFF3B82F6);

  // ============================================
  // DIVIDER COLORS
  // ============================================

  /// Divider color
  static const Color divider = Color(0xFFE2E8F0);

  /// Divider color light
  static const Color dividerLight = Color(0xFFF1F5F9);

  // ============================================
  // SHADOW COLORS
  // ============================================

  /// Shadow color
  static const Color shadow = Color(0x1A000000);

  /// Shadow color dark
  static const Color shadowDark = Color(0x26000000);

  // ============================================
  // ATTENDANCE STATUS COLORS
  // ============================================

  /// Present status color
  static const Color attendancePresent = Color(0xFF22C55E);

  /// Absent status color
  static const Color attendanceAbsent = Color(0xFFEF4444);

  /// Late status color
  static const Color attendanceLate = Color(0xFFF59E0B);

  /// Leave status color
  static const Color attendanceLeave = Color(0xFF3B82F6);

  /// Half day status color
  static const Color attendanceHalfDay = Color(0xFF8B5CF6);

  // ============================================
  // GRADE COLORS
  // ============================================

  /// Grade A+ color
  static const Color gradeAPlus = Color(0xFF22C55E);

  /// Grade A color
  static const Color gradeA = Color(0xFF4ADE80);

  /// Grade B+ color
  static const Color gradeBPlus = Color(0xFF84CC16);

  /// Grade B color
  static const Color gradeB = Color(0xFFA3E635);

  /// Grade C+ color
  static const Color gradeCPlus = Color(0xFFFACC15);

  /// Grade C color
  static const Color gradeC = Color(0xFFFBBF24);

  /// Grade D color
  static const Color gradeD = Color(0xFFF59E0B);

  /// Grade F color
  static const Color gradeF = Color(0xFFEF4444);

  // ============================================
  // CHART COLORS
  // ============================================

  /// Chart color palette for data visualization
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
  ];

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Get color for attendance status
  static Color getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return attendancePresent;
      case 'absent':
        return attendanceAbsent;
      case 'late':
        return attendanceLate;
      case 'leave':
        return attendanceLeave;
      case 'half_day':
        return attendanceHalfDay;
      default:
        return textSecondary;
    }
  }

  /// Get color for grade
  static Color getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
        return gradeAPlus;
      case 'A':
        return gradeA;
      case 'B+':
        return gradeBPlus;
      case 'B':
        return gradeB;
      case 'C+':
        return gradeCPlus;
      case 'C':
        return gradeC;
      case 'D':
        return gradeD;
      case 'F':
        return gradeF;
      default:
        return textSecondary;
    }
  }

  /// Get color for invoice status
  static Color getInvoiceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return success;
      case 'pending':
        return warning;
      case 'partial':
        return info;
      case 'overdue':
        return error;
      default:
        return textSecondary;
    }
  }

  /// Get color for student status
  static Color getStudentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return success;
      case 'inactive':
        return textSecondary;
      case 'graduated':
        return info;
      case 'withdrawn':
        return warning;
      case 'transferred':
        return accent;
      default:
        return textSecondary;
    }
  }
}
