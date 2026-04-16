/// EduX School Management System
/// Staff Repository - Data access layer for staff management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for staff with role information
class StaffWithRole {
  final StaffData staff;
  final StaffRole role;

  const StaffWithRole({required this.staff, required this.role});

  String get fullName => '${staff.firstName} ${staff.lastName}'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : staff.employeeId;
}

/// Staff filter parameters
class StaffFilters {
  final String? searchQuery;
  final int? roleId;
  final String? department;
  final String? designation;
  final String? status;
  final String sortBy;
  final bool ascending;
  final int limit;
  final int offset;

  const StaffFilters({
    this.searchQuery,
    this.roleId,
    this.department,
    this.designation,
    this.status,
    this.sortBy = 'firstName',
    this.ascending = true,
    this.limit = 25,
    this.offset = 0,
  });

  bool get hasFilters =>
      searchQuery != null ||
      roleId != null ||
      department != null ||
      designation != null ||
      status != null;

  StaffFilters copyWith({
    String? searchQuery,
    int? roleId,
    String? department,
    String? designation,
    String? status,
    String? sortBy,
    bool? ascending,
    int? limit,
    int? offset,
    bool clearSearch = false,
    bool clearRoleId = false,
    bool clearDepartment = false,
    bool clearDesignation = false,
    bool clearStatus = false,
  }) {
    return StaffFilters(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      roleId: clearRoleId ? null : (roleId ?? this.roleId),
      department: clearDepartment ? null : (department ?? this.department),
      designation: clearDesignation ? null : (designation ?? this.designation),
      status: clearStatus ? null : (status ?? this.status),
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  StaffFilters clearAll() {
    return StaffFilters(
      sortBy: sortBy,
      ascending: ascending,
      limit: limit,
      offset: 0,
    );
  }
}

/// Abstract staff repository interface
abstract class StaffRepository {
  Future<List<StaffWithRole>> getAll({int? limit, int? offset});
  Future<StaffWithRole?> getById(int id);
  Future<StaffWithRole?> getByUuid(String uuid);
  Future<StaffWithRole?> getByEmployeeId(String employeeId);
  Future<int> create(StaffCompanion staff);
  Future<bool> update(int id, StaffCompanion staff);
  Future<bool> delete(int id);
  Future<int> deleteMultiple(List<int> ids);

  Future<List<StaffWithRole>> search(StaffFilters filters);
  Future<int> count({int? roleId, String? department, String? status});

  Future<List<StaffWithRole>> getTeachers();
  Future<List<StaffWithRole>> getUnassignedStaff();
  Future<List<StaffWithRole>> getByRole(int roleId);
  Future<List<String>> getDistinctDepartments();
  Future<List<String>> getDistinctDesignations();

  Future<String> generateEmployeeId();
  Future<bool> isEmployeeIdUnique(String employeeId, {int? excludeId});

  Future<List<StaffRole>> getAllRoles();
  Future<StaffRole?> getRoleById(int id);
}

/// Implementation of StaffRepository using Drift database
class StaffRepositoryImpl implements StaffRepository {
  final AppDatabase _db;

  StaffRepositoryImpl(this._db);

  @override
  Future<List<StaffWithRole>> getAll({int? limit, int? offset}) async {
    final query = _db.select(_db.staff).join([
      innerJoin(_db.staffRoles, _db.staffRoles.id.equalsExp(_db.staff.roleId)),
    ]);

    query.orderBy([OrderingTerm.asc(_db.staff.firstName)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    final results = await query.get();
    return results.map((row) {
      return StaffWithRole(
        staff: row.readTable(_db.staff),
        role: row.readTable(_db.staffRoles),
      );
    }).toList();
  }

  @override
  Future<StaffWithRole?> getById(int id) async {
    final query = _db.select(_db.staff).join([
      innerJoin(_db.staffRoles, _db.staffRoles.id.equalsExp(_db.staff.roleId)),
    ])..where(_db.staff.id.equals(id));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    return StaffWithRole(
      staff: result.readTable(_db.staff),
      role: result.readTable(_db.staffRoles),
    );
  }

  @override
  Future<StaffWithRole?> getByUuid(String uuid) async {
    final query = _db.select(_db.staff).join([
      innerJoin(_db.staffRoles, _db.staffRoles.id.equalsExp(_db.staff.roleId)),
    ])..where(_db.staff.uuid.equals(uuid));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    return StaffWithRole(
      staff: result.readTable(_db.staff),
      role: result.readTable(_db.staffRoles),
    );
  }

  @override
  Future<StaffWithRole?> getByEmployeeId(String employeeId) async {
    final query = _db.select(_db.staff).join([
      innerJoin(_db.staffRoles, _db.staffRoles.id.equalsExp(_db.staff.roleId)),
    ])..where(_db.staff.employeeId.equals(employeeId));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    return StaffWithRole(
      staff: result.readTable(_db.staff),
      role: result.readTable(_db.staffRoles),
    );
  }

  @override
  Future<int> create(StaffCompanion staff) async {
    return await _db.into(_db.staff).insert(staff);
  }

  @override
  Future<bool> update(int id, StaffCompanion staff) async {
    final updated = staff.copyWith(updatedAt: Value(DateTime.now()));
    final rowsAffected = await (_db.update(
      _db.staff,
    )..where((t) => t.id.equals(id))).write(updated);
    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final rowsAffected = await (_db.delete(
      _db.staff,
    )..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  @override
  Future<int> deleteMultiple(List<int> ids) async {
    return await (_db.delete(_db.staff)..where((t) => t.id.isIn(ids))).go();
  }

  @override
  Future<List<StaffWithRole>> search(StaffFilters filters) async {
    final query = _db.select(_db.staff).join([
      innerJoin(_db.staffRoles, _db.staffRoles.id.equalsExp(_db.staff.roleId)),
    ]);

    // Build where conditions
    final conditions = <Expression<bool>>[];

    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final searchPattern = '%${filters.searchQuery}%';
      conditions.add(
        _db.staff.firstName.like(searchPattern) |
            _db.staff.lastName.like(searchPattern) |
            _db.staff.employeeId.like(searchPattern) |
            _db.staff.phone.like(searchPattern) |
            _db.staff.email.like(searchPattern),
      );
    }

    if (filters.roleId != null) {
      conditions.add(_db.staff.roleId.equals(filters.roleId!));
    }

    if (filters.department != null && filters.department!.isNotEmpty) {
      conditions.add(_db.staff.department.equals(filters.department!));
    }

    if (filters.designation != null && filters.designation!.isNotEmpty) {
      conditions.add(_db.staff.designation.equals(filters.designation!));
    }

    if (filters.status != null && filters.status!.isNotEmpty) {
      conditions.add(_db.staff.status.equals(filters.status!));
    }

    if (conditions.isNotEmpty) {
      query.where(conditions.reduce((a, b) => a & b));
    }

    // Sorting
    final sortColumn = switch (filters.sortBy) {
      'lastName' => _db.staff.lastName,
      'employeeId' => _db.staff.employeeId,
      'designation' => _db.staff.designation,
      'joiningDate' => _db.staff.joiningDate,
      'createdAt' => _db.staff.createdAt,
      _ => _db.staff.firstName,
    };

    query.orderBy([
      if (filters.ascending)
        OrderingTerm.asc(sortColumn)
      else
        OrderingTerm.desc(sortColumn),
    ]);

    // Apply pagination (limit: 0 or negative means no limit)
    if (filters.limit > 0) {
      query.limit(filters.limit, offset: filters.offset);
    }

    final results = await query.get();
    return results.map((row) {
      return StaffWithRole(
        staff: row.readTable(_db.staff),
        role: row.readTable(_db.staffRoles),
      );
    }).toList();
  }

  @override
  Future<int> count({int? roleId, String? department, String? status}) async {
    final query = _db.selectOnly(_db.staff)..addColumns([_db.staff.id.count()]);

    final conditions = <Expression<bool>>[];

    if (roleId != null) {
      conditions.add(_db.staff.roleId.equals(roleId));
    }

    if (department != null && department.isNotEmpty) {
      conditions.add(_db.staff.department.equals(department));
    }

    if (status != null && status.isNotEmpty) {
      conditions.add(_db.staff.status.equals(status));
    }

    if (conditions.isNotEmpty) {
      query.where(conditions.reduce((a, b) => a & b));
    }

    final result = await query.getSingle();
    return result.read(_db.staff.id.count()) ?? 0;
  }

  @override
  Future<List<StaffWithRole>> getUnassignedStaff() async {
    final query =
        _db.select(_db.staff).join([
            innerJoin(
              _db.staffRoles,
              _db.staffRoles.id.equalsExp(_db.staff.roleId),
            ),
          ])
          ..where(_db.staff.userId.isNull() & _db.staff.status.equals('active'))
          ..orderBy([OrderingTerm.asc(_db.staff.firstName)]);

    final results = await query.get();
    return results.map((row) {
      return StaffWithRole(
        staff: row.readTable(_db.staff),
        role: row.readTable(_db.staffRoles),
      );
    }).toList();
  }

  @override
  Future<List<StaffWithRole>> getTeachers() async {
    final query =
        _db.select(_db.staff).join([
            innerJoin(
              _db.staffRoles,
              _db.staffRoles.id.equalsExp(_db.staff.roleId),
            ),
          ])
          ..where(
            _db.staffRoles.canTeach.equals(true) &
                _db.staff.status.equals('active'),
          )
          ..orderBy([OrderingTerm.asc(_db.staff.firstName)]);

    final results = await query.get();
    return results.map((row) {
      return StaffWithRole(
        staff: row.readTable(_db.staff),
        role: row.readTable(_db.staffRoles),
      );
    }).toList();
  }

  @override
  Future<List<StaffWithRole>> getByRole(int roleId) async {
    final query =
        _db.select(_db.staff).join([
            innerJoin(
              _db.staffRoles,
              _db.staffRoles.id.equalsExp(_db.staff.roleId),
            ),
          ])
          ..where(_db.staff.roleId.equals(roleId))
          ..orderBy([OrderingTerm.asc(_db.staff.firstName)]);

    final results = await query.get();
    return results.map((row) {
      return StaffWithRole(
        staff: row.readTable(_db.staff),
        role: row.readTable(_db.staffRoles),
      );
    }).toList();
  }

  @override
  Future<List<String>> getDistinctDepartments() async {
    final query = _db.selectOnly(_db.staff, distinct: true)
      ..addColumns([_db.staff.department])
      ..where(_db.staff.department.isNotNull());

    final results = await query.get();
    return results
        .map((row) => row.read(_db.staff.department))
        .where((dept) => dept != null && dept.isNotEmpty)
        .cast<String>()
        .toList();
  }

  @override
  Future<List<String>> getDistinctDesignations() async {
    final query = _db.selectOnly(_db.staff, distinct: true)
      ..addColumns([_db.staff.designation]);

    final results = await query.get();
    return results
        .map((row) => row.read(_db.staff.designation))
        .where((des) => des != null && des.isNotEmpty)
        .cast<String>()
        .toList();
  }

  @override
  Future<String> generateEmployeeId() async {
    // Get the employee sequence
    final seq = await (_db.select(
      _db.numberSequences,
    )..where((t) => t.name.equals('employee'))).getSingleOrNull();

    if (seq == null) {
      // Create sequence if not exists
      await _db
          .into(_db.numberSequences)
          .insert(
            NumberSequencesCompanion.insert(
              name: 'employee',
              prefix: const Value('EMP-'),
              currentNumber: const Value(1),
              minDigits: const Value(4),
            ),
          );
      return 'EMP-0001';
    }

    // Increment sequence
    final nextNumber = seq.currentNumber + 1;
    await (_db.update(_db.numberSequences)
          ..where((t) => t.name.equals('employee')))
        .write(NumberSequencesCompanion(currentNumber: Value(nextNumber)));

    // Format with padding
    final paddedNumber = nextNumber.toString().padLeft(seq.minDigits, '0');
    return '${seq.prefix}$paddedNumber';
  }

  @override
  Future<bool> isEmployeeIdUnique(String employeeId, {int? excludeId}) async {
    final query = _db.select(_db.staff)
      ..where((t) => t.employeeId.equals(employeeId));

    if (excludeId != null) {
      query.where((t) => t.id.equals(excludeId).not());
    }

    final results = await query.get();
    return results.isEmpty;
  }

  @override
  Future<List<StaffRole>> getAllRoles() async {
    return await (_db.select(
      _db.staffRoles,
    )..orderBy([(t) => OrderingTerm.asc(t.displayOrder)])).get();
  }

  @override
  Future<StaffRole?> getRoleById(int id) async {
    return await (_db.select(
      _db.staffRoles,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}
