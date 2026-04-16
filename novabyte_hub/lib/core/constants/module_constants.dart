/// NovaByte Hub — Module Definitions
/// These module IDs must match exactly between EduX desktop and NovaByte Hub
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Information about a single EduX module
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

/// All gatable EduX modules
class EduXModules {
  EduXModules._();

  // Module IDs — these must match EduX desktop app
  static const String students = 'student_management';
  static const String guardians = 'guardian_management';
  static const String staff = 'staff_management';
  static const String academics = 'academic_management';
  static const String attendance = 'attendance_tracking';
  static const String exams = 'exam_management';
  static const String fees = 'fee_management';
  static const String expenses = 'expense_tracking';
  static const String canteen = 'canteen_management';
  static const String reports = 'reporting';
  static const String teacherApp = 'teacher_app';

  /// All module IDs
  static const List<String> allIds = [
    students,
    guardians,
    staff,
    academics,
    attendance,
    exams,
    fees,
    expenses,
    canteen,
    reports,
    teacherApp,
  ];

  /// Full module info with names, descriptions, icons, and colors
  static final List<ModuleInfo> allModules = [
    ModuleInfo(
      id: students,
      name: 'Student Management',
      description: 'Student enrollment, profiles, promotion, import/export',
      icon: LucideIcons.graduationCap,
      color: const Color(0xFF6C5CE7),
    ),
    ModuleInfo(
      id: guardians,
      name: 'Guardian Management',
      description: 'Parent/guardian management and linking',
      icon: LucideIcons.shieldCheck,
      color: const Color(0xFF74B9FF),
    ),
    ModuleInfo(
      id: staff,
      name: 'Staff Management',
      description: 'Staff profiles, attendance, leave, payroll',
      icon: LucideIcons.userCog,
      color: const Color(0xFF00B894),
    ),
    ModuleInfo(
      id: academics,
      name: 'Academic Management',
      description: 'Classes, sections, subjects, timetable',
      icon: LucideIcons.school,
      color: const Color(0xFFFDAA5E),
    ),
    ModuleInfo(
      id: attendance,
      name: 'Attendance Tracking',
      description: 'Daily attendance marking, reports, student history',
      icon: LucideIcons.calendarCheck,
      color: const Color(0xFF0984E3),
    ),
    ModuleInfo(
      id: exams,
      name: 'Exam Management',
      description: 'Exams, marks entry, result analysis, report cards',
      icon: LucideIcons.clipboardList,
      color: const Color(0xFFE17055),
    ),
    ModuleInfo(
      id: fees,
      name: 'Fee Management',
      description: 'Fee structures, invoicing, payment collection',
      icon: LucideIcons.receipt,
      color: const Color(0xFF00CEC9),
    ),
    ModuleInfo(
      id: expenses,
      name: 'Expense Tracking',
      description: 'Track and categorize school expenses',
      icon: LucideIcons.wallet,
      color: const Color(0xFFE84393),
    ),
    ModuleInfo(
      id: canteen,
      name: 'Canteen Management',
      description: 'Menu items, daily sales, canteen reports',
      icon: LucideIcons.store,
      color: const Color(0xFFFD79A8),
    ),
    ModuleInfo(
      id: reports,
      name: 'Reports & Analytics',
      description: 'Comprehensive reports across all modules',
      icon: LucideIcons.barChart3,
      color: const Color(0xFF636E72),
    ),
    ModuleInfo(
      id: teacherApp,
      name: 'Teacher Mobile App',
      description: 'Android app for teachers to mark attendance offline',
      icon: LucideIcons.smartphone,
      color: const Color(0xFF00B894),
    ),
  ];

  /// Get module info by ID
  static ModuleInfo? getById(String id) {
    try {
      return allModules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get module name by ID
  static String getModuleName(String id) {
    return getById(id)?.name ?? id;
  }
}

/// Pre-defined package template
class PackageTemplate {
  final String id;
  final String name;
  final String description;
  final List<String> moduleIds;
  final IconData icon;

  const PackageTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.moduleIds,
    required this.icon,
  });
}

/// Pre-defined EduX package templates
class EduXPackages {
  EduXPackages._();

  static final basic = PackageTemplate(
    id: 'basic',
    name: 'Basic',
    description: 'Core features for small institutions',
    moduleIds: const [
      EduXModules.students,
      EduXModules.guardians,
      EduXModules.academics,
      EduXModules.attendance,
      EduXModules.teacherApp,
    ],
    icon: LucideIcons.box,
  );

  static final standard = PackageTemplate(
    id: 'standard',
    name: 'Standard',
    description: 'Essential + exams and fees for growing schools',
    moduleIds: const [
      EduXModules.students,
      EduXModules.guardians,
      EduXModules.staff,
      EduXModules.academics,
      EduXModules.attendance,
      EduXModules.exams,
      EduXModules.fees,
      EduXModules.reports,
      EduXModules.teacherApp,
    ],
    icon: LucideIcons.shield,
  );

  static final premium = PackageTemplate(
    id: 'premium',
    name: 'Premium',
    description: 'Full access to every EduX module',
    moduleIds: const [
      EduXModules.students,
      EduXModules.guardians,
      EduXModules.staff,
      EduXModules.academics,
      EduXModules.attendance,
      EduXModules.exams,
      EduXModules.fees,
      EduXModules.expenses,
      EduXModules.canteen,
      EduXModules.reports,
      EduXModules.teacherApp,
    ],
    icon: LucideIcons.crown,
  );

  static final List<PackageTemplate> all = [basic, standard, premium];

  /// Get package by ID
  static PackageTemplate? getById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
