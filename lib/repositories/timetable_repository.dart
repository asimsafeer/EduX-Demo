/// EduX School Management System
/// Timetable Repository - Data access layer for timetable management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Query parameters for timetable
class TimetableQuery {
  final int classId;
  final int sectionId;
  final String academicYear;
  final String? dayOfWeek;

  const TimetableQuery({
    required this.classId,
    required this.sectionId,
    required this.academicYear,
    this.dayOfWeek,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimetableQuery &&
        other.classId == classId &&
        other.sectionId == sectionId &&
        other.academicYear == academicYear &&
        other.dayOfWeek == dayOfWeek;
  }

  @override
  int get hashCode =>
      classId.hashCode ^
      sectionId.hashCode ^
      academicYear.hashCode ^
      (dayOfWeek?.hashCode ?? 0);
}

/// Timetable slot with full details
class TimetableSlotWithDetails {
  final TimetableSlot slot;
  final Subject? subject;
  final String? teacherName;
  final int? teacherId;

  TimetableSlotWithDetails({
    required this.slot,
    this.subject,
    this.teacherName,
    this.teacherId,
  });

  String get displayName {
    if (slot.isBreak) return 'Break';
    return subject?.name ?? 'Free Period';
  }

  String get shortCode {
    if (slot.isBreak) return 'BRK';
    return subject?.code ?? '-';
  }
}

/// Conflict information
class TimetableConflict {
  final String type; // 'teacher' or 'room'
  final String message;
  final TimetableSlot conflictingSlot;

  TimetableConflict({
    required this.type,
    required this.message,
    required this.conflictingSlot,
  });
}

/// Abstract timetable repository interface
abstract class TimetableRepository {
  /// Get all timetable slots for a class-section
  Future<List<TimetableSlotWithDetails>> getByClassSection(
    TimetableQuery query,
  );

  /// Get slots for a specific day
  Future<List<TimetableSlotWithDetails>> getByDay(
    int classId,
    int sectionId,
    String day,
    String academicYear,
  );

  /// Get all slots for a teacher on a specific day
  Future<List<TimetableSlot>> getByTeacher(
    int teacherId,
    String day,
    String academicYear,
  );

  /// Get a specific slot by ID
  Future<TimetableSlot?> getById(int id);

  /// Create a new timetable slot
  Future<int> create(TimetableSlotsCompanion slot);

  /// Update an existing slot
  Future<bool> update(int id, TimetableSlotsCompanion slot);

  /// Delete a slot
  Future<bool> delete(int id);

  /// Check for conflicts before creating/updating a slot
  Future<TimetableConflict?> checkConflict(
    int? excludeId,
    int? teacherId,
    String dayOfWeek,
    int periodNumber,
    String academicYear,
  );

  /// Copy timetable from one class-section to another
  Future<void> copyTimetable(
    int fromClassId,
    int fromSectionId,
    int toClassId,
    int toSectionId,
    String academicYear,
  );

  /// Delete all slots for a class-section
  Future<int> deleteByClassSection(
    int classId,
    int sectionId,
    String academicYear,
  );

  /// Get weekly timetable organized by day and period
  Future<Map<String, Map<int, TimetableSlotWithDetails?>>> getWeeklyTimetable(
    int classId,
    int sectionId,
    String academicYear,
  );
}

/// Implementation of TimetableRepository using Drift database
class TimetableRepositoryImpl implements TimetableRepository {
  final AppDatabase _db;

  TimetableRepositoryImpl(this._db);

  static const List<String> daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
  ];

  @override
  Future<List<TimetableSlotWithDetails>> getByClassSection(
    TimetableQuery query,
  ) async {
    var dbQuery = _db.select(_db.timetableSlots)
      ..where(
        (t) =>
            t.classId.equals(query.classId) &
            t.sectionId.equals(query.sectionId) &
            t.academicYear.equals(query.academicYear),
      );

    if (query.dayOfWeek != null) {
      dbQuery = dbQuery..where((t) => t.dayOfWeek.equals(query.dayOfWeek!));
    }

    dbQuery = dbQuery
      ..orderBy([
        (t) => OrderingTerm.asc(t.dayOfWeek),
        (t) => OrderingTerm.asc(t.periodNumber),
      ]);

    final slots = await dbQuery.get();
    return await _enrichSlots(slots);
  }

  @override
  Future<List<TimetableSlotWithDetails>> getByDay(
    int classId,
    int sectionId,
    String day,
    String academicYear,
  ) async {
    final slots =
        await (_db.select(_db.timetableSlots)
              ..where(
                (t) =>
                    t.classId.equals(classId) &
                    t.sectionId.equals(sectionId) &
                    t.dayOfWeek.equals(day) &
                    t.academicYear.equals(academicYear),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.periodNumber)]))
            .get();

    return await _enrichSlots(slots);
  }

  @override
  Future<List<TimetableSlot>> getByTeacher(
    int teacherId,
    String day,
    String academicYear,
  ) async {
    return await (_db.select(_db.timetableSlots)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                t.dayOfWeek.equals(day) &
                t.academicYear.equals(academicYear),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.periodNumber)]))
        .get();
  }

  Future<List<TimetableSlotWithDetails>> _enrichSlots(
    List<TimetableSlot> slots,
  ) async {
    final List<TimetableSlotWithDetails> result = [];

    for (final slot in slots) {
      Subject? subject;
      String? teacherName;

      if (!slot.isBreak) {
        subject = await (_db.select(
          _db.subjects,
        )..where((t) => t.id.equals(slot.subjectId))).getSingleOrNull();

        if (slot.teacherId != null) {
          final staff = await (_db.select(
            _db.staff,
          )..where((t) => t.id.equals(slot.teacherId!))).getSingleOrNull();
          if (staff != null) {
            teacherName = '${staff.firstName} ${staff.lastName}';
          }
        }
      }

      result.add(
        TimetableSlotWithDetails(
          slot: slot,
          subject: subject,
          teacherName: teacherName,
          teacherId: slot.teacherId,
        ),
      );
    }

    return result;
  }

  @override
  Future<TimetableSlot?> getById(int id) async {
    return await (_db.select(
      _db.timetableSlots,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<int> create(TimetableSlotsCompanion slot) async {
    return await _db.into(_db.timetableSlots).insert(slot);
  }

  @override
  Future<bool> update(int id, TimetableSlotsCompanion slot) async {
    final updated =
        await (_db.update(_db.timetableSlots)..where((t) => t.id.equals(id)))
            .write(slot.copyWith(updatedAt: Value(DateTime.now())));
    return updated > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final deleted = await (_db.delete(
      _db.timetableSlots,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  @override
  Future<TimetableConflict?> checkConflict(
    int? excludeId,
    int? teacherId,
    String dayOfWeek,
    int periodNumber,
    String academicYear,
  ) async {
    if (teacherId == null) return null;

    // Check if teacher is already assigned to another class at this time
    var query = _db.select(_db.timetableSlots)
      ..where(
        (t) =>
            t.teacherId.equals(teacherId) &
            t.dayOfWeek.equals(dayOfWeek) &
            t.periodNumber.equals(periodNumber) &
            t.academicYear.equals(academicYear),
      );

    if (excludeId != null) {
      query = query..where((t) => t.id.equals(excludeId).not());
    }

    final conflicting = await query.getSingleOrNull();
    if (conflicting != null) {
      // Get class and section info for the message
      final schoolClass = await (_db.select(
        _db.classes,
      )..where((t) => t.id.equals(conflicting.classId))).getSingleOrNull();
      final section = await (_db.select(
        _db.sections,
      )..where((t) => t.id.equals(conflicting.sectionId))).getSingleOrNull();

      final className = schoolClass?.name ?? 'Unknown';
      final sectionName = section?.name ?? '';

      return TimetableConflict(
        type: 'teacher',
        message:
            'Teacher is already assigned to $className-$sectionName at this time',
        conflictingSlot: conflicting,
      );
    }

    return null;
  }

  @override
  Future<void> copyTimetable(
    int fromClassId,
    int fromSectionId,
    int toClassId,
    int toSectionId,
    String academicYear,
  ) async {
    // Get source timetable
    final sourceSlots =
        await (_db.select(_db.timetableSlots)..where(
              (t) =>
                  t.classId.equals(fromClassId) &
                  t.sectionId.equals(fromSectionId) &
                  t.academicYear.equals(academicYear),
            ))
            .get();

    // Delete existing slots in target
    await deleteByClassSection(toClassId, toSectionId, academicYear);

    // Copy slots
    await _db.batch((batch) {
      for (final slot in sourceSlots) {
        batch.insert(
          _db.timetableSlots,
          TimetableSlotsCompanion.insert(
            classId: toClassId,
            sectionId: toSectionId,
            subjectId: slot.subjectId,
            dayOfWeek: slot.dayOfWeek,
            periodNumber: slot.periodNumber,
            startTime: slot.startTime,
            endTime: slot.endTime,
            academicYear: academicYear,
            teacherId: Value(slot.teacherId),
            isBreak: Value(slot.isBreak),
          ),
        );
      }
    });
  }

  @override
  Future<int> deleteByClassSection(
    int classId,
    int sectionId,
    String academicYear,
  ) async {
    return await (_db.delete(_db.timetableSlots)..where(
          (t) =>
              t.classId.equals(classId) &
              t.sectionId.equals(sectionId) &
              t.academicYear.equals(academicYear),
        ))
        .go();
  }

  @override
  Future<Map<String, Map<int, TimetableSlotWithDetails?>>> getWeeklyTimetable(
    int classId,
    int sectionId,
    String academicYear,
  ) async {
    final slots = await getByClassSection(
      TimetableQuery(
        classId: classId,
        sectionId: sectionId,
        academicYear: academicYear,
      ),
    );

    // Get period definitions to know max periods
    final periods =
        await (_db.select(_db.periodDefinitions)
              ..where((t) => t.academicYear.equals(academicYear))
              ..orderBy([
                (t) => OrderingTerm.asc(t.startTime), // Sort by time first
                (t) => OrderingTerm.asc(t.displayOrder), // Then by order
              ]))
            .get();

    // Initialize the map
    final Map<String, Map<int, TimetableSlotWithDetails?>> result = {};

    for (final day in daysOfWeek) {
      result[day] = {};
      for (final period in periods) {
        result[day]![period.periodNumber] = null;
      }
    }

    // Fill in slots
    for (final slot in slots) {
      final day = slot.slot.dayOfWeek;
      final periodNum = slot.slot.periodNumber;
      if (result.containsKey(day)) {
        result[day]![periodNum] = slot;
      }
    }

    return result;
  }
}
