/// EduX School Management System
/// Refresh Service - Centralized cross-module provider invalidation
///
/// When data changes in one module, related providers in other modules
/// need to be refreshed. This service groups invalidation patterns to
/// avoid scattering cross-module logic across dozens of files.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'academics_provider.dart';
import 'dashboard_provider.dart';
import 'student_provider.dart' hide classesProvider;
import 'fee_provider.dart';
import 'exam_provider.dart';

/// Public typedef so callers can pass `ref.invalidate` from both
/// [Ref] (inside providers) and [WidgetRef] (inside widgets).
typedef Invalidator = void Function(ProviderOrFamily provider);

/// Centralized refresh utility for cross-module provider invalidation.
///
/// All methods accept an [Invalidator] (i.e. `ref.invalidate`) so they work
/// from both provider code and widget code.
///
/// Usage: `RefreshService.refreshStudentData(ref.invalidate);`
class RefreshService {
  RefreshService._(); // Prevent instantiation

  /// Refresh all student-related data including class/section stats.
  /// Call after: student import, create, update, delete, promote.
  static void refreshStudentData(Invalidator invalidate) {
    // Student module providers
    invalidate(studentsProvider);
    invalidate(studentCountProvider);
    invalidate(allStudentsProvider);

    // Cross-module: class/section stats include student counts
    invalidate(classesWithStatsProvider);
    invalidate(classesProvider);
    invalidate(classSectionPairsProvider);

    // Dashboard
    invalidate(dashboardProvider);
  }

  /// Refresh academic data (classes, sections, subjects, timetable).
  /// Call after: class/section/subject/timetable CRUD.
  static void refreshAcademicData(Invalidator invalidate) {
    invalidate(classesProvider);
    invalidate(classesWithStatsProvider);
    invalidate(classesGroupedByLevelProvider);
    invalidate(classSectionPairsProvider);
    invalidate(subjectsProvider);
    invalidate(filteredSubjectsProvider);
    invalidate(subjectsWithUsageProvider);
    invalidate(dashboardProvider);
  }

  /// Refresh fee data (invoices, payments, stats).
  /// Call after: invoice generation, payment collection.
  static void refreshFeeData(Invalidator invalidate) {
    invalidate(invoicesListProvider);
    invalidate(invoiceStatsProvider);
    invalidate(paymentsListProvider);
    invalidate(dashboardProvider);
  }

  /// Refresh exam data.
  /// Call after: exam create, update, delete, marks save.
  static void refreshExamData(Invalidator invalidate) {
    invalidate(examsListProvider);
    invalidate(dashboardProvider);
  }

  /// Refresh everything — useful after bulk operations like import.
  static void refreshAll(Invalidator invalidate) {
    refreshStudentData(invalidate);
    refreshAcademicData(invalidate);
    refreshFeeData(invalidate);
    refreshExamData(invalidate);
  }
}
