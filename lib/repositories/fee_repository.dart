/// EduX School Management System
/// Fee Repository - Data access layer for fee types and structures
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Fee type with usage statistics
class FeeTypeWithUsage {
  final FeeType feeType;
  final int structureCount;
  final int invoiceItemCount;

  const FeeTypeWithUsage({
    required this.feeType,
    required this.structureCount,
    required this.invoiceItemCount,
  });

  /// Whether fee type is in use and cannot be deleted
  bool get isInUse => structureCount > 0 || invoiceItemCount > 0;
}

/// Fee structure with class details
class FeeStructureWithDetails {
  final FeeStructure structure;
  final FeeType feeType;
  final SchoolClass schoolClass;

  const FeeStructureWithDetails({
    required this.structure,
    required this.feeType,
    required this.schoolClass,
  });
}

/// Class fee summary - total fees for a class
class ClassFeeSummary {
  final int classId;
  final String className;
  final int classOrder;
  final List<FeeStructureWithDetails> structures;
  final double totalMonthlyFee;
  final double totalOneTimeFee;

  const ClassFeeSummary({
    required this.classId,
    required this.className,
    required this.classOrder,
    required this.structures,
    required this.totalMonthlyFee,
    required this.totalOneTimeFee,
  });

  double get totalFee => totalMonthlyFee + totalOneTimeFee;
}

/// Abstract fee repository interface
abstract class FeeRepository {
  // Fee type operations
  Future<List<FeeType>> getAllFeeTypes({bool activeOnly = true});
  Future<List<FeeTypeWithUsage>> getFeeTypesWithUsage();
  Future<FeeType?> getFeeTypeById(int id);
  Future<int> createFeeType(FeeTypesCompanion feeType);
  Future<bool> updateFeeType(int id, FeeTypesCompanion feeType);
  Future<bool> deleteFeeType(int id);
  Future<bool> isFeeTypeNameUnique(String name, {int? excludeId});

  // Fee structure operations
  Future<List<FeeStructure>> getFeeStructures({
    int? classId,
    int? feeTypeId,
    String? academicYear,
    bool activeOnly = true,
  });
  Future<List<FeeStructureWithDetails>> getFeeStructuresWithDetails({
    int? classId,
    String? academicYear,
    bool activeOnly = true,
  });
  Future<FeeStructure?> getFeeStructureById(int id);
  Future<int> createFeeStructure(FeeStructuresCompanion structure);
  Future<bool> updateFeeStructure(int id, FeeStructuresCompanion structure);
  Future<bool> deleteFeeStructure(int id);

  // Batch operations
  Future<void> upsertFeeStructures(
    List<FeeStructuresCompanion> structures,
    int classId,
    String academicYear,
  );

  // Summary queries
  Future<List<ClassFeeSummary>> getClassFeeSummaries(String academicYear);
  Future<double> calculateTotalFees({
    required int classId,
    required String academicYear,
    bool monthlyOnly = false,
  });
  Future<List<FeeStructureWithDetails>> getStudentApplicableFees({
    required int classId,
    required String academicYear,
    bool monthlyOnly = true,
  });
}

/// Drift implementation of FeeRepository
class DriftFeeRepository implements FeeRepository {
  final AppDatabase _db;

  DriftFeeRepository(this._db);

  // ============================================
  // FEE TYPE OPERATIONS
  // ============================================

  @override
  Future<List<FeeType>> getAllFeeTypes({bool activeOnly = true}) async {
    var query = _db.select(_db.feeTypes)
      ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]);

    if (activeOnly) {
      query = query..where((t) => t.isActive.equals(true));
    }

    return await query.get();
  }

  @override
  Future<List<FeeTypeWithUsage>> getFeeTypesWithUsage() async {
    final feeTypes = await getAllFeeTypes(activeOnly: false);
    final results = <FeeTypeWithUsage>[];

    for (final feeType in feeTypes) {
      // Count structures using this fee type
      final structureCount = await _countFeeStructuresForType(feeType.id);

      // Count invoice items using this fee type
      final invoiceItemCount = await _countInvoiceItemsForType(feeType.id);

      results.add(
        FeeTypeWithUsage(
          feeType: feeType,
          structureCount: structureCount,
          invoiceItemCount: invoiceItemCount,
        ),
      );
    }

    return results;
  }

  @override
  Future<FeeType?> getFeeTypeById(int id) async {
    return await (_db.select(
      _db.feeTypes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<int> createFeeType(FeeTypesCompanion feeType) async {
    return await _db.into(_db.feeTypes).insert(feeType);
  }

  @override
  Future<bool> updateFeeType(int id, FeeTypesCompanion feeType) async {
    final updated = feeType.copyWith(updatedAt: Value(DateTime.now()));
    return await (_db.update(
          _db.feeTypes,
        )..where((t) => t.id.equals(id))).write(updated) >
        0;
  }

  @override
  Future<bool> deleteFeeType(int id) async {
    // Check if fee type is in use
    final structureCount = await _countFeeStructuresForType(id);
    final invoiceItemCount = await _countInvoiceItemsForType(id);

    if (structureCount > 0 || invoiceItemCount > 0) {
      // Soft delete - just mark as inactive
      return await updateFeeType(
        id,
        const FeeTypesCompanion(isActive: Value(false)),
      );
    }

    // Hard delete if not in use
    return await (_db.delete(
          _db.feeTypes,
        )..where((t) => t.id.equals(id))).go() >
        0;
  }

  @override
  Future<bool> isFeeTypeNameUnique(String name, {int? excludeId}) async {
    var query = _db.select(_db.feeTypes)
      ..where((t) => t.name.lower().equals(name.toLowerCase()));

    if (excludeId != null) {
      query = query..where((t) => t.id.equals(excludeId).not());
    }

    final existing = await query.getSingleOrNull();
    return existing == null;
  }

  // ============================================
  // FEE STRUCTURE OPERATIONS
  // ============================================

  @override
  Future<List<FeeStructure>> getFeeStructures({
    int? classId,
    int? feeTypeId,
    String? academicYear,
    bool activeOnly = true,
  }) async {
    var query = _db.select(_db.feeStructures);

    Expression<bool>? whereCondition;

    if (classId != null) {
      whereCondition = _db.feeStructures.classId.equals(classId);
    }

    if (feeTypeId != null) {
      final condition = _db.feeStructures.feeTypeId.equals(feeTypeId);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (academicYear != null) {
      final condition = _db.feeStructures.academicYear.equals(academicYear);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (activeOnly) {
      final condition = _db.feeStructures.isActive.equals(true);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (whereCondition != null) {
      query = query..where((t) => whereCondition!);
    }

    return await query.get();
  }

  @override
  Future<List<FeeStructureWithDetails>> getFeeStructuresWithDetails({
    int? classId,
    String? academicYear,
    bool activeOnly = true,
  }) async {
    final query = _db.select(_db.feeStructures).join([
      innerJoin(
        _db.feeTypes,
        _db.feeTypes.id.equalsExp(_db.feeStructures.feeTypeId),
      ),
      innerJoin(
        _db.classes,
        _db.classes.id.equalsExp(_db.feeStructures.classId),
      ),
    ]);

    Expression<bool>? whereCondition;

    if (classId != null) {
      whereCondition = _db.feeStructures.classId.equals(classId);
    }

    if (academicYear != null) {
      final condition = _db.feeStructures.academicYear.equals(academicYear);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (activeOnly) {
      final condition =
          _db.feeStructures.isActive.equals(true) &
          _db.feeTypes.isActive.equals(true);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (whereCondition != null) {
      query.where(whereCondition);
    }

    query.orderBy([
      OrderingTerm.asc(_db.classes.displayOrder),
      OrderingTerm.asc(_db.feeTypes.displayOrder),
    ]);

    final rows = await query.get();

    return rows.map((row) {
      return FeeStructureWithDetails(
        structure: row.readTable(_db.feeStructures),
        feeType: row.readTable(_db.feeTypes),
        schoolClass: row.readTable(_db.classes),
      );
    }).toList();
  }

  @override
  Future<FeeStructure?> getFeeStructureById(int id) async {
    return await (_db.select(
      _db.feeStructures,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<int> createFeeStructure(FeeStructuresCompanion structure) async {
    return await _db.into(_db.feeStructures).insert(structure);
  }

  @override
  Future<bool> updateFeeStructure(
    int id,
    FeeStructuresCompanion structure,
  ) async {
    final updated = structure.copyWith(updatedAt: Value(DateTime.now()));
    return await (_db.update(
          _db.feeStructures,
        )..where((t) => t.id.equals(id))).write(updated) >
        0;
  }

  @override
  Future<bool> deleteFeeStructure(int id) async {
    return await (_db.delete(
          _db.feeStructures,
        )..where((t) => t.id.equals(id))).go() >
        0;
  }

  @override
  Future<void> upsertFeeStructures(
    List<FeeStructuresCompanion> structures,
    int classId,
    String academicYear,
  ) async {
    await _db.transaction(() async {
      // Deactivate existing structures for this class and year
      await (_db.update(_db.feeStructures)..where(
            (t) =>
                t.classId.equals(classId) & t.academicYear.equals(academicYear),
          ))
          .write(const FeeStructuresCompanion(isActive: Value(false)));

      // Insert or update new structures
      for (final structure in structures) {
        // Check if structure exists
        final existing =
            await (_db.select(_db.feeStructures)..where(
                  (t) =>
                      t.classId.equals(classId) &
                      t.feeTypeId.equals(structure.feeTypeId.value) &
                      t.academicYear.equals(academicYear),
                ))
                .getSingleOrNull();

        if (existing != null) {
          // Update existing
          await (_db.update(
            _db.feeStructures,
          )..where((t) => t.id.equals(existing.id))).write(
            FeeStructuresCompanion(
              amount: structure.amount,
              isActive: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
        } else {
          // Insert new
          await _db.into(_db.feeStructures).insert(structure);
        }
      }
    });
  }

  // ============================================
  // SUMMARY QUERIES
  // ============================================

  @override
  Future<List<ClassFeeSummary>> getClassFeeSummaries(
    String academicYear,
  ) async {
    // Get all classes with their structures
    final classes = await (_db.select(
      _db.classes,
    )..orderBy([(t) => OrderingTerm.asc(t.displayOrder)])).get();

    final summaries = <ClassFeeSummary>[];

    for (final schoolClass in classes) {
      var structures = await getFeeStructuresWithDetails(
        classId: schoolClass.id,
        academicYear: academicYear,
      );

      // Check if a default tuition fee type is already in the list
      // Uses case-insensitive matching to handle variations like "Tuition Fee", "Tuition fee", etc.
      final hasTuitionFee = structures.any(
        (s) => s.feeType.name.toLowerCase().trim() == 'tuition fee',
      );

      // If class has a monthly fee and it's not already in structures, add it to the count
      if (!hasTuitionFee && schoolClass.monthlyFee > 0) {
        // Try to find a fee type with name matching "Tuition Fee" (case-insensitive)
        final tuitionFeeType = await (_db.select(
          _db.feeTypes,
        )..where((t) => t.name.lower().equals('tuition fee'))).getSingleOrNull();
        if (tuitionFeeType != null) {
          structures = [
            ...structures,
            FeeStructureWithDetails(
              feeType: tuitionFeeType,
              schoolClass: schoolClass,
              structure: FeeStructure(
                id: -1,
                classId: schoolClass.id,
                feeTypeId: tuitionFeeType.id,
                amount: schoolClass.monthlyFee,
                academicYear: academicYear,
                effectiveFrom: DateTime.now(),
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ];
        }
      }

      double monthlyTotal = 0;
      double oneTimeTotal = 0;

      for (final s in structures) {
        if (s.feeType.isMonthly) {
          monthlyTotal += s.structure.amount;
        } else {
          oneTimeTotal += s.structure.amount;
        }
      }

      summaries.add(
        ClassFeeSummary(
          classId: schoolClass.id,
          className: schoolClass.name,
          classOrder: schoolClass.displayOrder,
          structures: structures,
          totalMonthlyFee: monthlyTotal,
          totalOneTimeFee: oneTimeTotal,
        ),
      );
    }

    return summaries;
  }

  @override
  Future<double> calculateTotalFees({
    required int classId,
    required String academicYear,
    bool monthlyOnly = false,
  }) async {
    final structures = await getFeeStructuresWithDetails(
      classId: classId,
      academicYear: academicYear,
    );

    // Get the class monthly fee
    final schoolClass = await (_db.select(
      _db.classes,
    )..where((t) => t.id.equals(classId))).getSingleOrNull();
    final classMonthlyFee = schoolClass?.monthlyFee ?? 0;

    double total = 0;
    bool tuitionFeeFound = false;

    for (final s in structures) {
      if (monthlyOnly && !s.feeType.isMonthly) continue;
      total += s.structure.amount;
      if (s.feeType.name.toLowerCase().trim() == 'tuition fee') {
        tuitionFeeFound = true;
      }
    }

    // If no tuition fee in structures, add the class monthly fee
    if (!tuitionFeeFound && classMonthlyFee > 0) {
      total += classMonthlyFee;
    }

    return total;
  }

  @override
  Future<List<FeeStructureWithDetails>> getStudentApplicableFees({
    required int classId,
    required String academicYear,
    bool monthlyOnly = true,
  }) async {
    final structures = await getFeeStructuresWithDetails(
      classId: classId,
      academicYear: academicYear,
    );

    // Get the class info to check for monthly fee
    final schoolClass = await (_db.select(
      _db.classes,
    )..where((t) => t.id.equals(classId))).getSingleOrNull();

    List<FeeStructureWithDetails> result = [];

    if (monthlyOnly) {
      result = structures.where((s) => s.feeType.isMonthly).toList();
    } else {
      result = List.from(structures);
    }

    // Check if a default tuition fee type is already in the list
    final hasTuitionFee = result.any(
      (s) => s.feeType.name.toLowerCase().trim() == 'tuition fee',
    );

    // If class has a monthly fee and it's not already in structures, add it
    if (!hasTuitionFee && schoolClass != null && schoolClass.monthlyFee > 0) {
      // Find the Tuition Fee type (case-insensitive)
      final tuitionFeeType = await (_db.select(
        _db.feeTypes,
      )..where((t) => t.name.lower().equals('tuition fee'))).getSingleOrNull();

      if (tuitionFeeType != null) {
        result.add(
          FeeStructureWithDetails(
            feeType: tuitionFeeType,
            schoolClass: schoolClass,
            structure: FeeStructure(
              id: -1, // Virtual ID
              classId: classId,
              feeTypeId: tuitionFeeType.id,
              amount: schoolClass.monthlyFee,
              academicYear: academicYear,
              effectiveFrom: DateTime.now(),
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );
      }
    }

    return result;
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  Future<int> _countFeeStructuresForType(int feeTypeId) async {
    final count = _db.feeStructures.id.count();
    final query = _db.selectOnly(_db.feeStructures)
      ..addColumns([count])
      ..where(_db.feeStructures.feeTypeId.equals(feeTypeId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> _countInvoiceItemsForType(int feeTypeId) async {
    final count = _db.invoiceItems.id.count();
    final query = _db.selectOnly(_db.invoiceItems)
      ..addColumns([count])
      ..where(_db.invoiceItems.feeTypeId.equals(feeTypeId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
