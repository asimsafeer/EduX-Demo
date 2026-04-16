/// EduX School Management System
/// RBAC Service - Manage roles and permissions
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../core/core.dart';

/// Provider for RBAC service
final rbacServiceProvider = Provider<RbacService>((ref) {
  return RbacService();
});

/// Service to handle Role-Based Access Control
class RbacService {
  // --- PERMISSION CONSTANTS ---

  // Student Permissions
  static const String viewStudents = 'view_students';
  static const String manageStudents = 'manage_students';

  // Staff Permissions
  static const String viewStaff = 'view_staff';
  static const String manageStaff = 'manage_staff';

  // Academic Permissions
  static const String viewAcademics = 'view_academics';
  static const String manageAcademics = 'manage_academics';

  // Attendance Permissions
  static const String viewAttendance = 'view_attendance';
  static const String manageAttendance = 'manage_attendance';

  // Exam Permissions
  static const String viewExams = 'view_exams';
  static const String manageExams = 'manage_exams';

  // Fee Permissions
  static const String viewFees = 'view_fees';
  static const String manageFees = 'manage_fees';

  // Report Permissions
  static const String viewReports = 'view_reports';

  // Expense Permissions
  static const String viewExpenses = 'view_expenses';
  static const String manageExpenses = 'manage_expenses';

  // Canteen Permissions
  static const String viewCanteen = 'view_canteen';
  static const String manageCanteen = 'manage_canteen';

  // Setting Permissions
  static const String viewSettings = 'view_settings';
  static const String manageSettings = 'manage_settings';
  static const String manageUsers = 'manage_users';

  /// All available permissions with display names
  static const Map<String, String> allPermissions = {
    viewStudents: 'View Students',
    manageStudents: 'Manage Students (Add/Edit/Delete)',
    viewStaff: 'View Staff',
    manageStaff: 'Manage Staff',
    viewAcademics: 'View Academics (Classes/Subjects)',
    manageAcademics: 'Manage Academics',
    viewAttendance: 'View Attendance',
    manageAttendance: 'Take/Edit Attendance',
    viewExams: 'View Exams',
    manageExams: 'Manage Exams & Marks',
    viewFees: 'View Fees',
    manageFees: 'Manage Fees & Payments',
    viewReports: 'View Reports',
    viewExpenses: 'View Expenses',
    manageExpenses: 'Manage Expenses',
    viewCanteen: 'View Canteen',
    manageCanteen: 'Manage Canteen',
    viewSettings: 'View Settings',
    manageSettings: 'Manage Settings',
    manageUsers: 'Manage Users',
  };

  /// Default permissions for each role
  static const Map<String, List<String>> defaultRolePermissions = {
    UserRoles.admin: [
      viewStudents,
      manageStudents,
      viewStaff,
      manageStaff,
      viewAcademics,
      manageAcademics,
      viewAttendance,
      manageAttendance,
      viewExams,
      manageExams,
      viewFees,
      manageFees,
      viewReports,
      viewExpenses,
      manageExpenses,
      viewCanteen,
      manageCanteen,
      viewSettings,
      manageSettings,
      manageUsers,
    ],
    UserRoles.principal: [
      viewStudents, manageStudents,
      viewStaff,
      viewAcademics,
      manageAcademics, // Principal usually oversees academics
      viewAttendance, viewExams,
      viewFees, viewReports,
      viewExpenses,
      viewCanteen,
      viewSettings, // Principal might verify settings but not manage users/db backup
    ],
    UserRoles.teacher: [
      viewStudents,
      viewAcademics,
      viewAttendance,
      manageAttendance,
      viewExams,
      manageExams,
    ],
    UserRoles.accountant: [
      viewStudents,
      viewFees,
      manageFees,
      viewExpenses,
      manageExpenses,
      viewReports,
    ],
  };

  /// Check if a user has a specific permission
  bool hasPermission(User? user, String permission) {
    if (user == null) return false;

    // 1. Check if user is System Admin -> All permissions
    if (user.isSystemAdmin) return true;

    // 2. Check explicit permissions from DB (comma-separated string)
    if (user.permissions != null && user.permissions!.isNotEmpty) {
      final userPermissions = user.permissions!.split(',');
      if (userPermissions.contains(permission)) return true;
    }

    // 3. Fallback to Role-based defaults if no explicit permissions set?
    // OR should explicit permissions OVERRIDE role defaults?
    // Decision: If permissions column is NULL, use Role Default.
    // If permissions column is NOT NULL (even empty string), use it exclusively.
    // This allows creating an "Admin" with restricted access by setting specific permissions.

    if (user.permissions == null) {
      final defaults = defaultRolePermissions[user.role] ?? [];
      return defaults.contains(permission);
    }

    return false;
  }

  /// Get list of permissions for a user
  List<String> getUserPermissions(User? user) {
    if (user == null) return [];
    if (user.isSystemAdmin) return allPermissions.keys.toList();

    if (user.permissions != null) {
      return user.permissions!.split(',').where((p) => p.isNotEmpty).toList();
    }

    return defaultRolePermissions[user.role] ?? [];
  }
}
