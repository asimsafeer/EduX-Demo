/// EduX Teacher App - App Database
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/cached_classes.dart';
import 'tables/cached_students.dart';
import 'tables/pending_attendance.dart';
import 'tables/sync_config.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CachedClasses,
    CachedStudents,
    PendingAttendances,
    SyncConfig,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'teacher_cache.db'));
      return NativeDatabase.createInBackground(file);
    });
  }

  // ===========================================================================
  // CONFIG HELPERS
  // ===========================================================================

  /// Get config value by key
  Future<String?> getConfig(String key) async {
    final entry =
        await (select(syncConfig)..where((c) => c.key.equals(key))).getSingleOrNull();
    return entry?.value;
  }

  /// Set config value
  Future<void> setConfig(String key, String? value) async {
    await into(syncConfig).insert(
      SyncConfigEntry(key: key, value: value, updatedAt: DateTime.now()),
      onConflict: DoUpdate((old) => SyncConfigEntry(key: key, value: value, updatedAt: DateTime.now())),
    );
  }

  /// Delete config entry
  Future<void> deleteConfig(String key) async {
    await (delete(syncConfig)..where((c) => c.key.equals(key))).go();
  }

  // ===========================================================================
  // CLASS CACHE HELPERS
  // ===========================================================================

  /// Get all cached classes
  Future<List<CachedClass>> getCachedClasses() async {
    return await select(cachedClasses).get();
  }

  /// Get cached class by class and section ID
  Future<CachedClass?> getCachedClass(int classId, int sectionId) async {
    return await (select(cachedClasses)
          ..where((c) => c.classId.equals(classId) & c.sectionId.equals(sectionId)))
        .getSingleOrNull();
  }

  /// Cache classes (replaces all existing)
  Future<void> cacheClasses(List<CachedClassesCompanion> classes) async {
    await batch((batch) {
      batch.deleteAll(cachedClasses);
      for (final cls in classes) {
        batch.insert(cachedClasses, cls);
      }
    });
  }

  /// Clear all cached classes
  Future<void> clearCachedClasses() async {
    await delete(cachedClasses).go();
  }

  // ===========================================================================
  // STUDENT CACHE HELPERS
  // ===========================================================================

  /// Get cached students for a class/section
  Future<List<CachedStudent>> getCachedStudents(int classId, int sectionId) async {
    return await (select(cachedStudents)
          ..where((s) => s.classId.equals(classId) & s.sectionId.equals(sectionId))
          ..orderBy([(s) => OrderingTerm.asc(s.rollNumber)]))
        .get();
  }

  /// Get cached student by ID
  Future<CachedStudent?> getCachedStudent(int studentId) async {
    return await (select(cachedStudents)
          ..where((s) => s.studentId.equals(studentId)))
        .getSingleOrNull();
  }

  /// Cache students for a class/section
  /// Clears existing students for the same class/section first to prevent duplicates
  Future<void> cacheStudents(List<CachedStudentsCompanion> students) async {
    if (students.isEmpty) return;

    await transaction(() async {
      // Get unique class/section combinations from the input
      final classSections = students
          .map((s) => (s.classId.value, s.sectionId.value))
          .toSet();

      // Clear existing students for each class/section before inserting new ones
      for (final (classId, sectionId) in classSections) {
        await (delete(cachedStudents)
              ..where((s) => 
                  s.classId.equals(classId) & 
                  s.sectionId.equals(sectionId)))
            .go();
      }

      // Insert new student data
      await batch((batch) {
        for (final student in students) {
          batch.insert(
            cachedStudents,
            student,
            onConflict: DoUpdate((old) => student),
          );
        }
      });
    });
  }

  /// Clear cached students for a class/section
  Future<void> clearCachedStudents(int classId, int sectionId) async {
    await (delete(cachedStudents)
          ..where((s) => s.classId.equals(classId) & s.sectionId.equals(sectionId)))
        .go();
  }

  /// Clear all cached students
  Future<void> clearAllCachedStudents() async {
    await delete(cachedStudents).go();
  }

  // ===========================================================================
  // ATTENDANCE HELPERS
  // ===========================================================================

  /// Get all pending (unsynced) attendance records
  Future<List<PendingAttendance>> getPendingAttendance() async {
    return await (select(pendingAttendances)
          ..where((a) => a.isSynced.equals(false)))
        .get();
  }

  /// Get attendance for a specific class/section/date
  Future<List<PendingAttendance>> getAttendanceForClass(
    int classId,
    int sectionId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await (select(pendingAttendances)
          ..where((a) =>
              a.classId.equals(classId) &
              a.sectionId.equals(sectionId) &
              a.date.isBiggerOrEqualValue(startOfDay) &
              a.date.isSmallerThanValue(endOfDay)))
        .get();
  }

  /// Get attendance for a specific student and date
  Future<PendingAttendance?> getStudentAttendance(int studentId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await (select(pendingAttendances)
          ..where((a) =>
              a.studentId.equals(studentId) &
              a.date.isBiggerOrEqualValue(startOfDay) &
              a.date.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }

  /// Save attendance record
  Future<void> saveAttendance(PendingAttendancesCompanion attendance) async {
    await into(pendingAttendances).insert(
      attendance,
      onConflict: DoUpdate((old) => attendance),
    );
  }

  /// Save multiple attendance records in batch
  Future<void> saveAttendanceBatch(List<PendingAttendancesCompanion> attendances) async {
    await batch((batch) {
      for (final attendance in attendances) {
        batch.insert(
          pendingAttendances,
          attendance,
          onConflict: DoUpdate((old) => attendance),
        );
      }
    });
  }

  /// Mark attendance record as synced
  Future<void> markAttendanceSynced(int id) async {
    await (update(pendingAttendances)..where((a) => a.id.equals(id))).write(
      const PendingAttendancesCompanion(isSynced: Value(true)),
    );
  }

  /// Mark multiple attendance records as synced
  Future<void> markAttendanceSyncedBatch(List<int> ids) async {
    await batch((batch) {
      for (final id in ids) {
        batch.update(
          pendingAttendances,
          const PendingAttendancesCompanion(isSynced: Value(true)),
          where: (a) => a.id.equals(id),
        );
      }
    });
  }

  /// Update sync error for an attendance record
  Future<void> updateSyncError(int id, String error) async {
    final attendance = await (select(pendingAttendances)
          ..where((a) => a.id.equals(id)))
        .getSingle();

    await (update(pendingAttendances)..where((a) => a.id.equals(id))).write(
      PendingAttendancesCompanion(
        syncError: Value(error),
        syncAttempts: Value(attendance.syncAttempts + 1),
      ),
    );
  }

  /// Delete attendance record
  Future<void> deleteAttendance(int id) async {
    await (delete(pendingAttendances)..where((a) => a.id.equals(id))).go();
  }

  /// Get pending attendance count
  Future<int> getPendingCount() async {
    final query = selectOnly(pendingAttendances)
      ..addColumns([pendingAttendances.id.count()])
      ..where(pendingAttendances.isSynced.equals(false));

    final result = await query.getSingle();
    return result.read(pendingAttendances.id.count()) ?? 0;
  }

  /// Get attendance count for a class/section/date
  Future<int> getAttendanceCount(int classId, int sectionId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = selectOnly(pendingAttendances)
      ..addColumns([pendingAttendances.id.count()])
      ..where(pendingAttendances.classId.equals(classId) &
          pendingAttendances.sectionId.equals(sectionId) &
          pendingAttendances.date.isBiggerOrEqualValue(startOfDay) &
          pendingAttendances.date.isSmallerThanValue(endOfDay));

    final result = await query.getSingle();
    return result.read(pendingAttendances.id.count()) ?? 0;
  }

  /// Get attendance statistics for a class/section/date
  Future<Map<String, int>> getAttendanceStats(
    int classId,
    int sectionId,
    DateTime date,
  ) async {
    final records = await getAttendanceForClass(classId, sectionId, date);

    final stats = <String, int>{
      'present': 0,
      'absent': 0,
      'late': 0,
      'leave': 0,
      'half_day': 0,
      'total': records.length,
    };

    for (final record in records) {
      if (stats.containsKey(record.status)) {
        stats[record.status] = stats[record.status]! + 1;
      }
    }

    return stats;
  }

  /// Delete old synced attendance records (older than days)
  Future<int> deleteOldSyncedAttendance(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return await (delete(pendingAttendances)
          ..where((a) =>
              a.isSynced.equals(true) & a.markedAt.isSmallerThanValue(cutoffDate)))
        .go();
  }

  // ===========================================================================
  // DATA INTEGRITY CHECKS
  // ===========================================================================

  /// Check if all classes have their student data cached
  Future<List<CachedClass>> getClassesMissingStudents() async {
    final allClasses = await getCachedClasses();
    final missing = <CachedClass>[];

    for (final classInfo in allClasses) {
      final students = await getCachedStudents(
        classInfo.classId,
        classInfo.sectionId,
      );
      
      if (students.isEmpty && classInfo.totalStudents > 0) {
        missing.add(classInfo);
      }
    }

    return missing;
  }

  /// Get cache statistics for debugging
  Future<Map<String, dynamic>> getCacheStats() async {
    final classes = await getCachedClasses();
    final allStudents = await select(cachedStudents).get();
    
    final studentCounts = <String, int>{};
    for (final classInfo in classes) {
      final count = allStudents
          .where((s) => 
              s.classId == classInfo.classId && 
              s.sectionId == classInfo.sectionId)
          .length;
      studentCounts['${classInfo.className}-${classInfo.sectionName}'] = count;
    }

    return {
      'totalClasses': classes.length,
      'totalStudentsCached': allStudents.length,
      'studentCountsByClass': studentCounts,
      'pendingAttendance': await getPendingCount(),
    };
  }

  // ===========================================================================
  // DATA MANAGEMENT
  // ===========================================================================

  /// Clear all data (logout)
  Future<void> clearAllData() async {
    await batch((batch) {
      batch.deleteAll(cachedClasses);
      batch.deleteAll(cachedStudents);
      batch.deleteAll(pendingAttendances);
      batch.deleteAll(syncConfig);
    });
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final classCount =
        await select(cachedClasses).get().then((value) => value.length);
    final studentCount =
        await select(cachedStudents).get().then((value) => value.length);
    final pendingCount = await getPendingCount();
    final syncedCount = await select(pendingAttendances).get().then((records) {
      return records.where((r) => r.isSynced).length;
    });

    return {
      'classes': classCount,
      'students': studentCount,
      'pending': pendingCount,
      'synced': syncedCount,
    };
  }
}
