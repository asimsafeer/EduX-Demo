/// EduX School Management System
/// Subject Repository - Data access layer for subject management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Subject filter parameters
class SubjectFilters {
  final String? searchQuery;
  final String? type;
  final bool? isActive;
  final String sortBy;
  final bool ascending;

  const SubjectFilters({
    this.searchQuery,
    this.type,
    this.isActive,
    this.sortBy = 'name',
    this.ascending = true,
  });

  SubjectFilters copyWith({
    String? searchQuery,
    String? type,
    bool? isActive,
    String? sortBy,
    bool? ascending,
    bool clearSearch = false,
    bool clearType = false,
    bool clearIsActive = false,
  }) {
    return SubjectFilters(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      type: clearType ? null : (type ?? this.type),
      isActive: clearIsActive ? null : (isActive ?? this.isActive),
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  bool get hasFilters =>
      searchQuery != null || type != null || isActive != null;

  SubjectFilters clearAll() {
    return const SubjectFilters();
  }
}

/// Data class for subject with usage count
class SubjectWithUsage {
  final Subject subject;
  final int classCount;

  SubjectWithUsage({required this.subject, required this.classCount});

  String get displayName => '${subject.code} - ${subject.name}';
}

/// Abstract subject repository interface
abstract class SubjectRepository {
  /// Get all subjects
  Future<List<Subject>> getAll();

  /// Get all active subjects
  Future<List<Subject>> getAllActive();

  /// Get subjects by type
  Future<List<Subject>> getByType(String type);

  /// Get subject by ID
  Future<Subject?> getById(int id);

  /// Get subject by code
  Future<Subject?> getByCode(String code);

  /// Search subjects with filters
  Future<List<Subject>> search(SubjectFilters filters);

  /// Get all subjects with usage count
  Future<List<SubjectWithUsage>> getAllWithUsage();

  /// Get count of classes using this subject
  Future<int> getClassCount(int subjectId);

  /// Create a new subject
  Future<int> create(SubjectsCompanion subjectData);

  /// Update an existing subject
  Future<bool> update(int id, SubjectsCompanion subjectData);

  /// Soft delete a subject (set isActive = false)
  Future<bool> delete(int id);

  /// Hard delete a subject
  Future<bool> hardDelete(int id);

  /// Check if subject code is unique
  Future<bool> isCodeUnique(String code, {int? excludeId});
}

/// Implementation of SubjectRepository using Drift database
class SubjectRepositoryImpl implements SubjectRepository {
  final AppDatabase _db;

  SubjectRepositoryImpl(this._db);

  @override
  Future<List<Subject>> getAll() async {
    return await (_db.select(
      _db.subjects,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  @override
  Future<List<Subject>> getAllActive() async {
    return await (_db.select(_db.subjects)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  @override
  Future<List<Subject>> getByType(String type) async {
    return await (_db.select(_db.subjects)
          ..where((t) => t.type.equals(type) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  @override
  Future<Subject?> getById(int id) async {
    return await (_db.select(
      _db.subjects,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<Subject?> getByCode(String code) async {
    return await (_db.select(_db.subjects)
          ..where((t) => t.code.upper().equals(code.toUpperCase())))
        .getSingleOrNull();
  }

  @override
  Future<List<Subject>> search(SubjectFilters filters) async {
    var query = _db.select(_db.subjects);

    // Apply filters
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final searchLower = filters.searchQuery!.toLowerCase();
      query = query
        ..where(
          (t) =>
              t.name.lower().contains(searchLower) |
              t.code.lower().contains(searchLower),
        );
    }

    if (filters.type != null) {
      query = query..where((t) => t.type.equals(filters.type!));
    }

    if (filters.isActive != null) {
      query = query..where((t) => t.isActive.equals(filters.isActive!));
    }

    // Apply sorting
    switch (filters.sortBy) {
      case 'code':
        query = query
          ..orderBy([
            (t) => filters.ascending
                ? OrderingTerm.asc(t.code)
                : OrderingTerm.desc(t.code),
          ]);
        break;
      case 'type':
        query = query
          ..orderBy([
            (t) => filters.ascending
                ? OrderingTerm.asc(t.type)
                : OrderingTerm.desc(t.type),
          ]);
        break;
      default:
        query = query
          ..orderBy([
            (t) => filters.ascending
                ? OrderingTerm.asc(t.name)
                : OrderingTerm.desc(t.name),
          ]);
    }

    return await query.get();
  }

  @override
  Future<List<SubjectWithUsage>> getAllWithUsage() async {
    final subjects = await getAllActive();
    final List<SubjectWithUsage> result = [];

    for (final subject in subjects) {
      final classCount = await getClassCount(subject.id);
      result.add(SubjectWithUsage(subject: subject, classCount: classCount));
    }

    return result;
  }

  @override
  Future<int> getClassCount(int subjectId) async {
    final count =
        await (_db.selectOnly(_db.classSubjects)
              ..addColumns([_db.classSubjects.id.count()])
              ..where(_db.classSubjects.subjectId.equals(subjectId)))
            .map((row) => row.read(_db.classSubjects.id.count()))
            .getSingle();
    return count ?? 0;
  }

  @override
  Future<int> create(SubjectsCompanion subjectData) async {
    // Ensure code is uppercase
    final data = subjectData.copyWith(
      code: Value(subjectData.code.value.toUpperCase()),
    );
    return await _db.into(_db.subjects).insert(data);
  }

  @override
  Future<bool> update(int id, SubjectsCompanion subjectData) async {
    // Ensure code is uppercase if being updated
    var data = subjectData;
    if (subjectData.code.present) {
      data = subjectData.copyWith(
        code: Value(subjectData.code.value.toUpperCase()),
      );
    }

    final updated =
        await (_db.update(_db.subjects)..where((t) => t.id.equals(id))).write(
          data.copyWith(updatedAt: Value(DateTime.now())),
        );
    return updated > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final updated =
        await (_db.update(_db.subjects)..where((t) => t.id.equals(id))).write(
          const SubjectsCompanion(isActive: Value(false)),
        );
    return updated > 0;
  }

  @override
  Future<bool> hardDelete(int id) async {
    final deleted = await (_db.delete(
      _db.subjects,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  @override
  Future<bool> isCodeUnique(String code, {int? excludeId}) async {
    var query = _db.select(_db.subjects)
      ..where((t) => t.code.upper().equals(code.toUpperCase()));

    if (excludeId != null) {
      query = query..where((t) => t.id.equals(excludeId).not());
    }

    final existing = await query.getSingleOrNull();
    return existing == null;
  }
}
