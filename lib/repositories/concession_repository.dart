/// EduX School Management System
/// Concession Repository - Data access layer for student fee concessions
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Concession with full details
class ConcessionWithDetails {
  final Concession concession;
  final Student student;
  final Enrollment enrollment;
  final SchoolClass schoolClass;
  final Section? section;
  final FeeType? feeType; // null means applies to all fee types

  const ConcessionWithDetails({
    required this.concession,
    required this.student,
    required this.enrollment,
    required this.schoolClass,
    this.section,
    this.feeType,
  });

  String get studentName => '${student.studentName} ${student.fatherName}';
  String get classSection => section != null
      ? '${schoolClass.name}-${section!.name}'
      : schoolClass.name;

  /// Calculate discount amount for a given fee amount
  double calculateDiscount(double feeAmount) {
    if (concession.discountType == 'percentage') {
      return feeAmount * (concession.discountValue / 100);
    } else {
      // Fixed amount
      return concession.discountValue > feeAmount
          ? feeAmount
          : concession.discountValue;
    }
  }

  bool get isActive {
    final now = DateTime.now();
    if (now.isBefore(concession.startDate)) {
      return false;
    }
    if (concession.endDate != null && now.isAfter(concession.endDate!)) {
      return false;
    }
    return concession.isActive;
  }
}

/// Concession filter parameters
class ConcessionFilters {
  final int? studentId;
  final int? classId;
  final int? feeTypeId;
  final bool activeOnly;
  final int limit;
  final int offset;

  const ConcessionFilters({
    this.studentId,
    this.classId,
    this.feeTypeId,
    this.activeOnly = true,
    this.limit = 50,
    this.offset = 0,
  });

  ConcessionFilters copyWith({
    int? studentId,
    int? classId,
    int? feeTypeId,
    String? academicYear,
    bool? activeOnly,
    int? limit,
    int? offset,
  }) {
    return ConcessionFilters(
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      feeTypeId: feeTypeId ?? this.feeTypeId,
      activeOnly: activeOnly ?? this.activeOnly,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

/// Concession summary for reports
class ConcessionSummary {
  final int totalStudents;
  final int totalConcessions;
  final double totalDiscountPercentage;
  final double totalFixedDiscount;
  final List<ConcessionCategoryCount> byConcessionType;

  const ConcessionSummary({
    required this.totalStudents,
    required this.totalConcessions,
    required this.totalDiscountPercentage,
    required this.totalFixedDiscount,
    required this.byConcessionType,
  });
}

/// Concession type category count
class ConcessionCategoryCount {
  final String concessionType;
  final int count;
  final int studentCount;

  const ConcessionCategoryCount({
    required this.concessionType,
    required this.count,
    required this.studentCount,
  });
}

/// Student discount info - all applicable concessions for a student
class StudentDiscountInfo {
  final int studentId;
  final List<ConcessionWithDetails> concessions;

  const StudentDiscountInfo({
    required this.studentId,
    required this.concessions,
  });

  /// Check if student has any active concession
  bool get hasConcession => concessions.isNotEmpty;

  /// Get total percentage discount for a fee type
  /// Returns the sum of all percentage discounts applicable to the fee type
  double getPercentageDiscount(int? feeTypeId) {
    double total = 0;
    for (final c in concessions) {
      if (!c.isActive) continue;
      if (c.concession.discountType != 'percentage') continue;

      // If concession has no feeTypeId, it applies to all
      // If concession has a feeTypeId, it must match
      if (c.concession.feeTypeId == null ||
          c.concession.feeTypeId == feeTypeId) {
        total += c.concession.discountValue;
      }
    }
    // Cap at 100%
    return total > 100 ? 100 : total;
  }

  /// Get total fixed discount for a fee type
  double getFixedDiscount(int? feeTypeId) {
    double total = 0;
    for (final c in concessions) {
      if (!c.isActive) continue;
      if (c.concession.discountType != 'fixed') continue;

      if (c.concession.feeTypeId == null ||
          c.concession.feeTypeId == feeTypeId) {
        total += c.concession.discountValue;
      }
    }
    return total;
  }

  /// Calculate total discount for a fee amount
  double calculateDiscount(double feeAmount, int? feeTypeId) {
    final percentDiscount =
        feeAmount * (getPercentageDiscount(feeTypeId) / 100);
    final fixedDiscount = getFixedDiscount(feeTypeId);

    final totalDiscount = percentDiscount + fixedDiscount;
    return totalDiscount > feeAmount ? feeAmount : totalDiscount;
  }
}

/// Abstract concession repository interface
abstract class ConcessionRepository {
  // CRUD operations
  Future<Concession?> getById(int id);
  Future<int> create(ConcessionsCompanion concession);
  Future<bool> update(int id, ConcessionsCompanion concession);
  Future<bool> delete(int id);

  // Query operations
  Future<List<ConcessionWithDetails>> getConcessions(ConcessionFilters filters);
  Future<ConcessionWithDetails?> getConcessionWithDetails(int id);
  Future<List<Concession>> getStudentConcessions(
    int studentId, {
    bool activeOnly = true,
  });
  Future<StudentDiscountInfo> getStudentDiscountInfo(int studentId);
  Future<Map<int, StudentDiscountInfo>> getBulkStudentDiscountInfo(
    List<int> studentIds,
  );

  // Check operations
  Future<bool> hasActiveConcession(int studentId, {int? feeTypeId});

  // Reports
  Future<ConcessionSummary> getConcessionSummary({
    String? academicYear,
    int? classId,
  });

  // Bulk operations
  Future<void> deactivateExpiredConcessions();
}

/// Drift implementation of ConcessionRepository
class DriftConcessionRepository implements ConcessionRepository {
  final AppDatabase _db;

  DriftConcessionRepository(this._db);

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  @override
  Future<Concession?> getById(int id) async {
    return await (_db.select(
      _db.concessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<int> create(ConcessionsCompanion concession) async {
    return await _db.into(_db.concessions).insert(concession);
  }

  @override
  Future<bool> update(int id, ConcessionsCompanion concession) async {
    final updated = concession.copyWith(updatedAt: Value(DateTime.now()));
    return await (_db.update(
          _db.concessions,
        )..where((t) => t.id.equals(id))).write(updated) >
        0;
  }

  @override
  Future<bool> delete(int id) async {
    return await (_db.delete(
          _db.concessions,
        )..where((t) => t.id.equals(id))).go() >
        0;
  }

  // ============================================
  // QUERY OPERATIONS
  // ============================================

  @override
  Future<List<ConcessionWithDetails>> getConcessions(
    ConcessionFilters filters,
  ) async {
    final query = _db.select(_db.concessions).join([
      innerJoin(
        _db.students,
        _db.students.id.equalsExp(_db.concessions.studentId),
      ),
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.enrollments.classId)),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.enrollments.sectionId),
      ),
      leftOuterJoin(
        _db.feeTypes,
        _db.feeTypes.id.equalsExp(_db.concessions.feeTypeId),
      ),
    ]);

    Expression<bool>? whereCondition;

    if (filters.studentId != null) {
      whereCondition = _db.concessions.studentId.equals(filters.studentId!);
    }

    if (filters.classId != null) {
      final condition = _db.enrollments.classId.equals(filters.classId!);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (filters.feeTypeId != null) {
      final condition =
          _db.concessions.feeTypeId.equals(filters.feeTypeId!) |
          _db.concessions.feeTypeId.isNull();
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (filters.activeOnly) {
      final now = DateTime.now();
      final activeCondition =
          _db.concessions.isActive.equals(true) &
          (_db.concessions.startDate.isNull() |
              _db.concessions.startDate.isSmallerOrEqualValue(now)) &
          (_db.concessions.endDate.isNull() |
              _db.concessions.endDate.isBiggerOrEqualValue(now));
      whereCondition = whereCondition == null
          ? activeCondition
          : whereCondition & activeCondition;
    }

    if (whereCondition != null) {
      query.where(whereCondition);
    }

    query.orderBy([
      OrderingTerm.asc(_db.students.studentName),
      OrderingTerm.desc(_db.concessions.createdAt),
    ]);

    // Apply pagination (limit: 0 or negative means no limit)
    if (filters.limit > 0) {
      query.limit(filters.limit, offset: filters.offset);
    }

    final rows = await query.get();

    return rows.map((row) {
      return ConcessionWithDetails(
        concession: row.readTable(_db.concessions),
        student: row.readTable(_db.students),
        enrollment: row.readTable(_db.enrollments),
        schoolClass: row.readTable(_db.classes),
        section: row.readTableOrNull(_db.sections),
        feeType: row.readTableOrNull(_db.feeTypes),
      );
    }).toList();
  }

  @override
  Future<ConcessionWithDetails?> getConcessionWithDetails(int id) async {
    final query = _db.select(_db.concessions).join([
      innerJoin(
        _db.students,
        _db.students.id.equalsExp(_db.concessions.studentId),
      ),
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.enrollments.classId)),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.enrollments.sectionId),
      ),
      leftOuterJoin(
        _db.feeTypes,
        _db.feeTypes.id.equalsExp(_db.concessions.feeTypeId),
      ),
    ]);

    query.where(_db.concessions.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return ConcessionWithDetails(
      concession: row.readTable(_db.concessions),
      student: row.readTable(_db.students),
      enrollment: row.readTable(_db.enrollments),
      schoolClass: row.readTable(_db.classes),
      section: row.readTableOrNull(_db.sections),
      feeType: row.readTableOrNull(_db.feeTypes),
    );
  }

  @override
  Future<List<Concession>> getStudentConcessions(
    int studentId, {
    bool activeOnly = true,
  }) async {
    var query = _db.select(_db.concessions)
      ..where((t) => t.studentId.equals(studentId));

    if (activeOnly) {
      final now = DateTime.now();
      query = query
        ..where(
          (t) =>
              t.isActive.equals(true) &
              (t.startDate.isNull() | t.startDate.isSmallerOrEqualValue(now)) &
              (t.endDate.isNull() | t.endDate.isBiggerOrEqualValue(now)),
        );
    }

    return await query.get();
  }

  @override
  Future<StudentDiscountInfo> getStudentDiscountInfo(int studentId) async {
    final concessions = await getConcessions(
      ConcessionFilters(studentId: studentId, activeOnly: true),
    );

    return StudentDiscountInfo(studentId: studentId, concessions: concessions);
  }

  @override
  Future<Map<int, StudentDiscountInfo>> getBulkStudentDiscountInfo(
    List<int> studentIds,
  ) async {
    if (studentIds.isEmpty) return {};

    final result = <int, StudentDiscountInfo>{};

    // Initialize all students with empty concessions
    for (final id in studentIds) {
      result[id] = StudentDiscountInfo(studentId: id, concessions: []);
    }

    // Get all active concessions for these students
    final now = DateTime.now();
    final query = _db.select(_db.concessions).join([
      innerJoin(
        _db.students,
        _db.students.id.equalsExp(_db.concessions.studentId),
      ),
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.enrollments.classId)),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.enrollments.sectionId),
      ),
      leftOuterJoin(
        _db.feeTypes,
        _db.feeTypes.id.equalsExp(_db.concessions.feeTypeId),
      ),
    ]);

    query.where(
      _db.concessions.studentId.isIn(studentIds) &
          _db.concessions.isActive.equals(true) &
          (_db.concessions.startDate.isNull() |
              _db.concessions.startDate.isSmallerOrEqualValue(now)) &
          (_db.concessions.endDate.isNull() |
              _db.concessions.endDate.isBiggerOrEqualValue(now)),
    );

    final rows = await query.get();

    // Group by student
    final concessionsByStudent = <int, List<ConcessionWithDetails>>{};

    for (final row in rows) {
      final concession = row.readTable(_db.concessions);
      final detail = ConcessionWithDetails(
        concession: concession,
        student: row.readTable(_db.students),
        enrollment: row.readTable(_db.enrollments),
        schoolClass: row.readTable(_db.classes),
        section: row.readTableOrNull(_db.sections),
        feeType: row.readTableOrNull(_db.feeTypes),
      );

      concessionsByStudent.putIfAbsent(concession.studentId, () => []);
      concessionsByStudent[concession.studentId]!.add(detail);
    }

    // Update result
    for (final entry in concessionsByStudent.entries) {
      result[entry.key] = StudentDiscountInfo(
        studentId: entry.key,
        concessions: entry.value,
      );
    }

    return result;
  }

  // ============================================
  // CHECK OPERATIONS
  // ============================================

  @override
  Future<bool> hasActiveConcession(int studentId, {int? feeTypeId}) async {
    final now = DateTime.now();

    var query = _db.select(_db.concessions)
      ..where(
        (t) =>
            t.studentId.equals(studentId) &
            t.isActive.equals(true) &
            (t.startDate.isNull() | t.startDate.isSmallerOrEqualValue(now)) &
            (t.endDate.isNull() | t.endDate.isBiggerOrEqualValue(now)),
      );

    if (feeTypeId != null) {
      query = query
        ..where((t) => t.feeTypeId.equals(feeTypeId) | t.feeTypeId.isNull());
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  // ============================================
  // REPORTS
  // ============================================

  @override
  Future<ConcessionSummary> getConcessionSummary({
    String? academicYear,
    int? classId,
  }) async {
    final concessions = await getConcessions(
      ConcessionFilters(
        classId: classId,
        activeOnly: true,
        limit: 0, // No limit - get all for summary
      ),
    );

    final studentIds = <int>{};
    double totalPercentage = 0;
    double totalFixed = 0;
    final byType = <String, _TypeCountData>{};

    for (final c in concessions) {
      studentIds.add(c.student.id);

      if (c.concession.discountType == 'percentage') {
        totalPercentage += c.concession.discountValue;
      } else {
        totalFixed += c.concession.discountValue;
      }

      final type = c.concession.reason ?? 'Other';
      byType.putIfAbsent(type, () => _TypeCountData());
      byType[type]!.count++;
      byType[type]!.studentIds.add(c.student.id);
    }

    return ConcessionSummary(
      totalStudents: studentIds.length,
      totalConcessions: concessions.length,
      totalDiscountPercentage: totalPercentage,
      totalFixedDiscount: totalFixed,
      byConcessionType: byType.entries
          .map(
            (e) => ConcessionCategoryCount(
              concessionType: e.key,
              count: e.value.count,
              studentCount: e.value.studentIds.length,
            ),
          )
          .toList(),
    );
  }

  // ============================================
  // BULK OPERATIONS
  // ============================================

  @override
  Future<void> deactivateExpiredConcessions() async {
    final now = DateTime.now();

    await (_db.update(_db.concessions)..where(
          (t) =>
              t.isActive.equals(true) &
              t.endDate.isNotNull() &
              t.endDate.isSmallerThanValue(now),
        ))
        .write(const ConcessionsCompanion(isActive: Value(false)));
  }
}

/// Helper class for type counting
class _TypeCountData {
  int count = 0;
  final Set<int> studentIds = {};
}
