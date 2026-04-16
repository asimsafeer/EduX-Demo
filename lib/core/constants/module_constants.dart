/// EduX School Management System
/// Module Definitions & Package Templates
///
/// These IDs MUST match the NovaByte Hub admin app exactly.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─────────────────────────────────────────────────────────────
//  Module Info
// ─────────────────────────────────────────────────────────────

/// Represents a single EduX feature module.
class ModuleInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const ModuleInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────
//  All EduX Modules (10 total)
// ─────────────────────────────────────────────────────────────

class EduXModules {
  EduXModules._();

  static const studentManagement = ModuleInfo(
    id: 'student_management',
    name: 'Student Management',
    description: 'Student enrollment, profiles, promotion, and bulk import',
    icon: LucideIcons.users,
    color: Color(0xFF6C5CE7),
  );

  static const staffManagement = ModuleInfo(
    id: 'staff_management',
    name: 'Staff Management',
    description: 'Staff profiles, attendance, leave, and payroll',
    icon: LucideIcons.userCog,
    color: Color(0xFF00B894),
  );

  static const academicManagement = ModuleInfo(
    id: 'academic_management',
    name: 'Academic Management',
    description: 'Classes, sections, subjects, and timetable',
    icon: LucideIcons.school,
    color: Color(0xFFFDAA5E),
  );

  static const attendanceTracking = ModuleInfo(
    id: 'attendance_tracking',
    name: 'Attendance Tracking',
    description: 'Daily attendance marking, reports, and student history',
    icon: LucideIcons.calendarCheck,
    color: Color(0xFF0984E3),
  );

  static const examManagement = ModuleInfo(
    id: 'exam_management',
    name: 'Exam Management',
    description: 'Exams, marks entry, result analysis, and report cards',
    icon: LucideIcons.clipboardList,
    color: Color(0xFFE17055),
  );

  static const feeManagement = ModuleInfo(
    id: 'fee_management',
    name: 'Fee Management',
    description:
        'Fee structures, invoicing, payment collection, and defaulters',
    icon: LucideIcons.receipt,
    color: Color(0xFF00CEC9),
  );

  static const expenseTracking = ModuleInfo(
    id: 'expense_tracking',
    name: 'Expense Tracking',
    description: 'Track and categorize school expenses',
    icon: LucideIcons.wallet,
    color: Color(0xFFE84393),
  );

  static const canteenManagement = ModuleInfo(
    id: 'canteen_management',
    name: 'Canteen Management',
    description: 'Menu items, daily sales, and canteen reports',
    icon: LucideIcons.store,
    color: Color(0xFFFD79A8),
  );

  static const reporting = ModuleInfo(
    id: 'reporting',
    name: 'Reports & Analytics',
    description: 'Comprehensive reports across all modules',
    icon: LucideIcons.barChart3,
    color: Color(0xFF636E72),
  );

  static const guardianManagement = ModuleInfo(
    id: 'guardian_management',
    name: 'Guardian Management',
    description: 'Guardian profiles and student-guardian linking',
    icon: LucideIcons.shieldCheck,
    color: Color(0xFF74B9FF),
  );

  static const teacherApp = ModuleInfo(
    id: 'teacher_app',
    name: 'Teacher Mobile App',
    description: 'Android app for teachers to mark attendance offline',
    icon: LucideIcons.smartphone,
    color: Color(0xFF00B894),
  );

  /// Complete list of all modules.
  static const List<ModuleInfo> all = [
    studentManagement,
    staffManagement,
    academicManagement,
    attendanceTracking,
    examManagement,
    feeManagement,
    expenseTracking,
    canteenManagement,
    reporting,
    guardianManagement,
    teacherApp,
  ];

  /// Lookup a module by its ID.
  static ModuleInfo? byId(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  Package Templates
// ─────────────────────────────────────────────────────────────

class PackageTemplate {
  final String id;
  final String name;
  final String description;
  final List<String> moduleIds;
  final IconData icon;
  final Color color;

  const PackageTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.moduleIds,
    required this.icon,
    required this.color,
  });
}

class EduXPackages {
  EduXPackages._();

  static const basic = PackageTemplate(
    id: 'basic',
    name: 'Basic',
    description: 'Core features for small institutions',
    moduleIds: [
      'student_management',
      'academic_management',
      'attendance_tracking',
      'guardian_management',
      'teacher_app',
    ],
    icon: LucideIcons.box,
    color: Color(0xFF74B9FF),
  );

  static const standard = PackageTemplate(
    id: 'standard',
    name: 'Standard',
    description: 'Essential + exams and fees for growing schools',
    moduleIds: [
      'student_management',
      'staff_management',
      'academic_management',
      'attendance_tracking',
      'exam_management',
      'fee_management',
      'guardian_management',
      'reporting',
      'teacher_app',
    ],
    icon: LucideIcons.shield,
    color: Color(0xFF6C5CE7),
  );

  static const premium = PackageTemplate(
    id: 'premium',
    name: 'Premium',
    description: 'Full access to every EduX module',
    moduleIds: [
      'student_management',
      'staff_management',
      'academic_management',
      'attendance_tracking',
      'exam_management',
      'fee_management',
      'expense_tracking',
      'canteen_management',
      'reporting',
      'guardian_management',
      'teacher_app',
    ],
    icon: LucideIcons.crown,
    color: Color(0xFFFDAA5E),
  );

  /// All available packages.
  static const List<PackageTemplate> all = [basic, standard, premium];
}
