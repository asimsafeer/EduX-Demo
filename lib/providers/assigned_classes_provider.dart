/// EduX School Management System
/// Assigned Classes Provider — resolves the current user's assigned class IDs
///
/// For admin/principal roles this returns null (meaning "all classes").
/// For teacher/accountant roles it queries:
///   User.id → Staff.userId → StaffSubjectAssignments.staffId → classId list
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../database/app_database.dart';
import 'auth_provider.dart';

/// Provides the list of class IDs the current user is assigned to.
/// Returns `null` for admin/principal (all-access), or `List<int>` for
/// restricted roles like teacher.
final assignedClassIdsProvider = FutureProvider<List<int>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  // Admin & principal see everything
  if (user.isSystemAdmin ||
      user.role == UserRoles.admin ||
      user.role == UserRoles.principal) {
    return null; // null => no restriction
  }

  final db = AppDatabase.instance;

  // 1. Find the staff record linked to this user
  final staffQuery = db.select(db.staff)
    ..where((s) => s.userId.equals(user.id));
  final staffRecord = await staffQuery.getSingleOrNull();

  if (staffRecord == null) {
    // User has no linked staff record → no classes assigned
    return [];
  }

  // 2. Get distinct class IDs from staff_subject_assignments
  final assignmentQuery =
      db.selectOnly(db.staffSubjectAssignments, distinct: true)
        ..addColumns([db.staffSubjectAssignments.classId])
        ..where(db.staffSubjectAssignments.staffId.equals(staffRecord.id));

  final rows = await assignmentQuery.get();
  final classIds = rows
      .map((row) => row.read(db.staffSubjectAssignments.classId))
      .whereType<int>()
      .toSet()
      .toList();

  return classIds;
});

/// Convenience provider that returns true if the current user has
/// restricted (non-admin) access, i.e. should only see assigned classes.
final isRestrictedUserProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return true;
  return !user.isSystemAdmin &&
      user.role != UserRoles.admin &&
      user.role != UserRoles.principal;
});
