/// EduX School Management System
/// Leave Repository - Data access layer for leave management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../core/constants/app_constants.dart';

/// Data class for leave request with type and staff information
class LeaveRequestWithDetails {
  final LeaveRequest request;
  final LeaveType leaveType;
  final StaffData staff;
  final User? approver;

  const LeaveRequestWithDetails({
    required this.request,
    required this.leaveType,
    required this.staff,
    this.approver,
  });

  String get staffName => '${staff.firstName} ${staff.lastName}'.trim();
  bool get isPending => request.status == LeaveConstants.statusPending;
  bool get isApproved => request.status == 'approved';
  bool get isRejected => request.status == 'rejected';
}

/// Leave balance for a staff member
class LeaveBalance {
  final int leaveTypeId;
  final String leaveTypeName;
  final int allocated;
  final int used;
  final int pending;
  final bool isPaid;

  const LeaveBalance({
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.allocated,
    required this.used,
    required this.pending,
    required this.isPaid,
  });

  int get remaining => allocated - used - pending;
  bool get hasBalance => remaining > 0;
}

/// Abstract leave repository interface
abstract class LeaveRepository {
  // Leave Types
  Future<List<LeaveType>> getAllLeaveTypes();
  Future<LeaveType?> getLeaveTypeById(int id);
  Future<int> createLeaveType(LeaveTypesCompanion leaveType);
  Future<bool> updateLeaveType(int id, LeaveTypesCompanion leaveType);
  Future<bool> deleteLeaveType(int id);

  // Leave Requests
  Future<List<LeaveRequestWithDetails>> getAllRequests({
    String? status,
    int? staffId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });
  Future<LeaveRequestWithDetails?> getRequestById(int id);
  Future<int> createRequest(LeaveRequestsCompanion request);
  Future<bool> updateRequest(int id, LeaveRequestsCompanion request);
  Future<bool> deleteRequest(int id);

  Future<List<LeaveRequestWithDetails>> getPendingRequests({int? limit});
  Future<List<LeaveRequestWithDetails>> getStaffLeaves(
    int staffId, {
    String? academicYear,
  });

  // Leave Balance
  Future<List<LeaveBalance>> getLeaveBalance(int staffId, {String? year});
  Future<int> getUsedLeaveDays(int staffId, int leaveTypeId, {String? year});
  Future<int> getPendingLeaveDays(int staffId, int leaveTypeId, {String? year});

  // Validation
  Future<bool> hasOverlappingLeave(
    int staffId,
    DateTime startDate,
    DateTime endDate, {
    int? excludeRequestId,
  });
}

/// Implementation of LeaveRepository using Drift database
class LeaveRepositoryImpl implements LeaveRepository {
  final AppDatabase _db;

  LeaveRepositoryImpl(this._db);

  // ============================================
  // LEAVE TYPES
  // ============================================

  @override
  Future<List<LeaveType>> getAllLeaveTypes() async {
    return await (_db.select(_db.leaveTypes)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  @override
  Future<LeaveType?> getLeaveTypeById(int id) async {
    return await (_db.select(
      _db.leaveTypes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<int> createLeaveType(LeaveTypesCompanion leaveType) async {
    return await _db.into(_db.leaveTypes).insert(leaveType);
  }

  @override
  Future<bool> updateLeaveType(int id, LeaveTypesCompanion leaveType) async {
    final rowsAffected = await (_db.update(
      _db.leaveTypes,
    )..where((t) => t.id.equals(id))).write(leaveType);
    return rowsAffected > 0;
  }

  @override
  Future<bool> deleteLeaveType(int id) async {
    // Soft delete by setting isActive to false
    final rowsAffected =
        await (_db.update(_db.leaveTypes)..where((t) => t.id.equals(id))).write(
          const LeaveTypesCompanion(isActive: Value(false)),
        );
    return rowsAffected > 0;
  }

  // ============================================
  // LEAVE REQUESTS
  // ============================================

  @override
  Future<List<LeaveRequestWithDetails>> getAllRequests({
    String? status,
    int? staffId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final query = _db.select(_db.leaveRequests).join([
      innerJoin(
        _db.leaveTypes,
        _db.leaveTypes.id.equalsExp(_db.leaveRequests.leaveTypeId),
      ),
      innerJoin(_db.staff, _db.staff.id.equalsExp(_db.leaveRequests.staffId)),
      leftOuterJoin(
        _db.users,
        _db.users.id.equalsExp(_db.leaveRequests.approvedBy),
      ),
    ]);

    final conditions = <Expression<bool>>[];

    if (status != null && status.isNotEmpty) {
      conditions.add(_db.leaveRequests.status.equals(status));
    }

    if (staffId != null) {
      conditions.add(_db.leaveRequests.staffId.equals(staffId));
    }

    if (startDate != null) {
      conditions.add(
        _db.leaveRequests.startDate.isBiggerOrEqualValue(startDate),
      );
    }

    if (endDate != null) {
      conditions.add(_db.leaveRequests.endDate.isSmallerOrEqualValue(endDate));
    }

    if (conditions.isNotEmpty) {
      query.where(conditions.reduce((a, b) => a & b));
    }

    query.orderBy([OrderingTerm.desc(_db.leaveRequests.createdAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    final results = await query.get();
    return results.map((row) {
      return LeaveRequestWithDetails(
        request: row.readTable(_db.leaveRequests),
        leaveType: row.readTable(_db.leaveTypes),
        staff: row.readTable(_db.staff),
        approver: row.readTableOrNull(_db.users),
      );
    }).toList();
  }

  @override
  Future<LeaveRequestWithDetails?> getRequestById(int id) async {
    final query = _db.select(_db.leaveRequests).join([
      innerJoin(
        _db.leaveTypes,
        _db.leaveTypes.id.equalsExp(_db.leaveRequests.leaveTypeId),
      ),
      innerJoin(_db.staff, _db.staff.id.equalsExp(_db.leaveRequests.staffId)),
      leftOuterJoin(
        _db.users,
        _db.users.id.equalsExp(_db.leaveRequests.approvedBy),
      ),
    ])..where(_db.leaveRequests.id.equals(id));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    return LeaveRequestWithDetails(
      request: result.readTable(_db.leaveRequests),
      leaveType: result.readTable(_db.leaveTypes),
      staff: result.readTable(_db.staff),
      approver: result.readTableOrNull(_db.users),
    );
  }

  @override
  Future<int> createRequest(LeaveRequestsCompanion request) async {
    return await _db.into(_db.leaveRequests).insert(request);
  }

  @override
  Future<bool> updateRequest(int id, LeaveRequestsCompanion request) async {
    final updated = request.copyWith(updatedAt: Value(DateTime.now()));
    final rowsAffected = await (_db.update(
      _db.leaveRequests,
    )..where((t) => t.id.equals(id))).write(updated);
    return rowsAffected > 0;
  }

  @override
  Future<bool> deleteRequest(int id) async {
    final rowsAffected = await (_db.delete(
      _db.leaveRequests,
    )..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  @override
  Future<List<LeaveRequestWithDetails>> getPendingRequests({int? limit}) async {
    return await getAllRequests(status: 'pending', limit: limit);
  }

  @override
  Future<List<LeaveRequestWithDetails>> getStaffLeaves(
    int staffId, {
    String? academicYear,
  }) async {
    return await getAllRequests(staffId: staffId);
  }

  // ============================================
  // LEAVE BALANCE
  // ============================================

  @override
  Future<List<LeaveBalance>> getLeaveBalance(
    int staffId, {
    String? year,
  }) async {
    final leaveTypes = await getAllLeaveTypes();
    final balances = <LeaveBalance>[];

    for (final leaveType in leaveTypes) {
      final used = await getUsedLeaveDays(staffId, leaveType.id, year: year);
      final pending = await getPendingLeaveDays(
        staffId,
        leaveType.id,
        year: year,
      );

      balances.add(
        LeaveBalance(
          leaveTypeId: leaveType.id,
          leaveTypeName: leaveType.name,
          allocated: leaveType.maxDays,
          used: used,
          pending: pending,
          isPaid: leaveType.isPaid,
        ),
      );
    }

    return balances;
  }

  @override
  Future<int> getUsedLeaveDays(
    int staffId,
    int leaveTypeId, {
    String? year,
  }) async {
    final query = _db.selectOnly(_db.leaveRequests)
      ..addColumns([_db.leaveRequests.totalDays.sum()])
      ..where(
        _db.leaveRequests.staffId.equals(staffId) &
            _db.leaveRequests.leaveTypeId.equals(leaveTypeId) &
            _db.leaveRequests.status.equals('approved'),
      );

    if (year != null) {
      final startOfYear = DateTime(int.parse(year.split('-').first), 1, 1);
      final endOfYear = DateTime(int.parse(year.split('-').first) + 1, 1, 0);
      query.where(
        _db.leaveRequests.startDate.isBiggerOrEqualValue(startOfYear) &
            _db.leaveRequests.startDate.isSmallerOrEqualValue(endOfYear),
      );
    }

    final result = await query.getSingle();
    return result.read(_db.leaveRequests.totalDays.sum()) ?? 0;
  }

  @override
  Future<int> getPendingLeaveDays(
    int staffId,
    int leaveTypeId, {
    String? year,
  }) async {
    final query = _db.selectOnly(_db.leaveRequests)
      ..addColumns([_db.leaveRequests.totalDays.sum()])
      ..where(
        _db.leaveRequests.staffId.equals(staffId) &
            _db.leaveRequests.leaveTypeId.equals(leaveTypeId) &
            _db.leaveRequests.status.equals('pending'),
      );

    if (year != null) {
      final startOfYear = DateTime(int.parse(year.split('-').first), 1, 1);
      final endOfYear = DateTime(int.parse(year.split('-').first) + 1, 1, 0);
      query.where(
        _db.leaveRequests.startDate.isBiggerOrEqualValue(startOfYear) &
            _db.leaveRequests.startDate.isSmallerOrEqualValue(endOfYear),
      );
    }

    final result = await query.getSingle();
    return result.read(_db.leaveRequests.totalDays.sum()) ?? 0;
  }

  // ============================================
  // VALIDATION
  // ============================================

  @override
  Future<bool> hasOverlappingLeave(
    int staffId,
    DateTime startDate,
    DateTime endDate, {
    int? excludeRequestId,
  }) async {
    final query = _db.select(_db.leaveRequests)
      ..where(
        (t) =>
            t.staffId.equals(staffId) &
            t.status.isIn(['pending', 'approved']) &
            // Check for overlap: new start <= existing end AND new end >= existing start
            t.startDate.isSmallerOrEqualValue(endDate) &
            t.endDate.isBiggerOrEqualValue(startDate),
      );

    if (excludeRequestId != null) {
      query.where((t) => t.id.equals(excludeRequestId).not());
    }

    final results = await query.get();
    return results.isNotEmpty;
  }
}
