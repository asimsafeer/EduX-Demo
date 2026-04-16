/// EduX Teacher App - Classes Provider
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../models/class_section.dart';
import '../models/sync_models.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

part 'classes_provider.g.dart';

/// Classes state
class ClassesState {
  final List<ClassSection> classes;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final Map<ClassSection, String> classErrors; // Per-class error messages
  final bool isPartialData; // True if some classes failed to load

  const ClassesState({
    this.classes = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.classErrors = const {},
    this.isPartialData = false,
  });

  ClassesState copyWith({
    List<ClassSection>? classes,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    Map<ClassSection, String>? classErrors,
    bool? isPartialData,
  }) {
    return ClassesState(
      classes: classes ?? this.classes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      classErrors: classErrors ?? this.classErrors,
      isPartialData: isPartialData ?? this.isPartialData,
    );
  }

  /// Get class by ID
  ClassSection? getClass(int classId, int sectionId) {
    try {
      return classes.firstWhere(
        (c) => c.classId == classId && c.sectionId == sectionId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a specific class has an error
  bool hasClassError(ClassSection classSection) => 
      classErrors.containsKey(classSection);

  /// Get error for a specific class
  String? getClassError(ClassSection classSection) => 
      classErrors[classSection];
}

/// Classes provider
@Riverpod(keepAlive: true)
class Classes extends _$Classes {
  late AppDatabase _db;

  @override
  ClassesState build() {
    _db = ref.read(databaseProvider);

    // Load cached classes on init
    _loadCachedClasses();

    return const ClassesState(isLoading: true);
  }

  /// Load cached classes from local DB
  Future<void> _loadCachedClasses() async {
    try {
      final cachedClasses = await _db.getCachedClasses();

      final classes = cachedClasses.map((c) => ClassSection(
            classId: c.classId,
            sectionId: c.sectionId,
            className: c.className,
            sectionName: c.sectionName,
            subjectName: c.subjectName,
            totalStudents: c.totalStudents,
            isClassTeacher: c.isClassTeacher,
          )).toList();

      state = ClassesState(
        classes: classes,
        lastUpdated: cachedClasses.isNotEmpty ? cachedClasses.first.cachedAt : null,
      );
    } catch (e) {
      state = ClassesState(error: e.toString());
    }
  }

  /// Refresh classes from server
  Future<bool> refreshClasses() async {
    state = state.copyWith(isLoading: true, error: null, classErrors: {});

    try {
      final syncService = ref.read(syncServiceProvider);

      // Reinitialize if needed
      if (!syncService.isInitialized) {
        final success = await syncService.reinitialize();
        if (!success) {
          state = state.copyWith(
            isLoading: false,
            error: 'Server not configured. Please log in again.',
          );
          return false;
        }
      }

      final classes = await syncService.fetchClasses();

      state = ClassesState(
        classes: classes,
        lastUpdated: DateTime.now(),
        isPartialData: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Refresh a specific class's students (for retry)
  Future<bool> refreshClassStudents(ClassSection classSection) async {
    try {
      final syncService = ref.read(syncServiceProvider);
      
      if (!syncService.isInitialized) {
        return false;
      }

      await syncService.fetchAndCacheStudents(
        classSection.classId,
        classSection.sectionId,
      );

      // Clear error for this class
      final newErrors = Map<ClassSection, String>.from(state.classErrors)
        ..remove(classSection);
      
      state = state.copyWith(classErrors: newErrors);
      return true;
    } catch (e) {
      // Add error for this class
      final newErrors = Map<ClassSection, String>.from(state.classErrors)
        ..[classSection] = e.toString();
      
      state = state.copyWith(classErrors: newErrors);
      return false;
    }
  }

  /// Check and fix missing student data for all classes
  Future<DataIntegrityReport> checkDataIntegrity() async {
    final syncService = ref.read(syncServiceProvider);
    return await syncService.validateDataIntegrity();
  }

  /// Fix missing student data for classes with issues
  Future<int> fixMissingStudents() async {
    final report = await checkDataIntegrity();
    if (!report.hasIssues) return 0;

    int fixedCount = 0;
    final syncService = ref.read(syncServiceProvider);

    for (final classSection in report.classesNeedingRefresh) {
      try {
        await syncService.fetchAndCacheStudents(
          classSection.classId,
          classSection.sectionId,
        );
        fixedCount++;
      } catch (e) {
        // Continue with other classes
      }
    }

    return fixedCount;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Selected class provider (for navigation)
@Riverpod(keepAlive: true)
class SelectedClass extends _$SelectedClass {
  @override
  ClassSection? build() => null;

  void select(ClassSection? classSection) {
    state = classSection;
  }
}

/// Selected date provider (for attendance)
@Riverpod(keepAlive: true)
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => DateTime.now();

  void select(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}
