/// EduX School Management System
/// Leave Service - Business logic for leave management
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../repositories/leave_repository.dart';

/// Leave request form data
class LeaveRequestFormData {
  final int staffId;
  final int leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isHalfDay;
  final String reason;

  const LeaveRequestFormData({
    required this.staffId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    this.isHalfDay = false,
    required this.reason,
  });

  int get totalDays {
    if (isHalfDay) return 1;
    return endDate.difference(startDate).inDays + 1;
  }
}

/// Leave validation result
class LeaveValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const LeaveValidationResult({required this.isValid, required this.errors});
}

/// Leave service for business logic
class LeaveService {
  final AppDatabase _db;
  final LeaveRepository _leaveRepository;

  LeaveService(this._db) : _leaveRepository = LeaveRepositoryImpl(_db);

  /// Validate leave request
  Future<LeaveValidationResult> validateLeaveRequest(
    LeaveRequestFormData data, {
    int? excludeRequestId,
  }) async {
    final errors = <String, String>{};

    // Validate staff exists and is active
    final staff = await (_db.select(
      _db.staff,
    )..where((t) => t.id.equals(data.staffId))).getSingleOrNull();
    if (staff == null) {
      errors['staffId'] = 'Staff member not found';
    } else if (staff.status != 'active') {
      errors['staffId'] = 'Staff member is not active';
    }

    // Validate leave type
    final leaveType = await _leaveRepository.getLeaveTypeById(data.leaveTypeId);
    if (leaveType == null) {
      errors['leaveTypeId'] = 'Invalid leave type';
    }

    // Validate dates
    if (data.startDate.isAfter(data.endDate)) {
      errors['dates'] = 'Start date cannot be after end date';
    }

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final startOnly = DateTime(
      data.startDate.year,
      data.startDate.month,
      data.startDate.day,
    );

    if (startOnly.isBefore(today)) {
      errors['startDate'] = 'Cannot request leave for past dates';
    }

    // Validate reason
    if (data.reason.trim().isEmpty) {
      errors['reason'] = 'Reason is required';
    } else if (data.reason.trim().length < 10) {
      errors['reason'] = 'Please provide a more detailed reason';
    }

    // Check leave balance
    if (leaveType != null && staff != null) {
      final balance = await _leaveRepository.getLeaveBalance(
        data.staffId,
        year: '${data.startDate.year}',
      );
      final typeBalance = balance.firstWhere(
        (b) => b.leaveTypeId == data.leaveTypeId,
        orElse: () => LeaveBalance(
          leaveTypeId: data.leaveTypeId,
          leaveTypeName: leaveType.name,
          allocated: leaveType.maxDays,
          used: 0,
          pending: 0,
          isPaid: leaveType.isPaid,
        ),
      );

      if (typeBalance.remaining < data.totalDays) {
        errors['balance'] =
            'Insufficient leave balance. Available: ${typeBalance.remaining} days';
      }
    }

    // Check for overlapping leave
    if (staff != null) {
      final hasOverlap = await _leaveRepository.hasOverlappingLeave(
        data.staffId,
        data.startDate,
        data.endDate,
        excludeRequestId: excludeRequestId,
      );
      if (hasOverlap) {
        errors['overlap'] = 'You already have leave during this period';
      }
    }

    return LeaveValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Submit a new leave request
  Future<int> submitLeaveRequest(LeaveRequestFormData data) async {
    // Validate
    final validation = await validateLeaveRequest(data);
    if (!validation.isValid) {
      throw LeaveValidationException(validation.errors);
    }

    final companion = LeaveRequestsCompanion.insert(
      staffId: data.staffId,
      leaveTypeId: data.leaveTypeId,
      startDate: data.startDate,
      endDate: data.endDate,
      totalDays: data.totalDays,
      isHalfDay: Value(data.isHalfDay),
      reason: data.reason.trim(),
      status: const Value('pending'),
    );

    final id = await _leaveRepository.createRequest(companion);

    await _logActivity(
      action: 'submit_leave',
      module: 'leave',
      details: 'Submitted leave request for ${data.totalDays} days',
    );

    return id;
  }

  /// Approve a leave request
  Future<bool> approveLeave({
    required int requestId,
    required int approvedBy,
    String? remarks,
  }) async {
    final request = await _leaveRepository.getRequestById(requestId);
    if (request == null) {
      throw LeaveNotFoundException('Leave request not found');
    }

    if (!request.isPending) {
      throw LeaveValidationException({
        'status': 'Request is already processed',
      });
    }

    final updated = LeaveRequestsCompanion(
      status: const Value('approved'),
      approvedBy: Value(approvedBy),
      actionDate: Value(DateTime.now()),
      remarks: Value(remarks),
    );

    final success = await _leaveRepository.updateRequest(requestId, updated);

    if (success) {
      await _logActivity(
        action: 'approve_leave',
        module: 'leave',
        details: 'Approved leave request for ${request.staffName}',
      );
    }

    return success;
  }

  /// Reject a leave request
  Future<bool> rejectLeave({
    required int requestId,
    required int rejectedBy,
    required String reason,
  }) async {
    final request = await _leaveRepository.getRequestById(requestId);
    if (request == null) {
      throw LeaveNotFoundException('Leave request not found');
    }

    if (!request.isPending) {
      throw LeaveValidationException({
        'status': 'Request is already processed',
      });
    }

    if (reason.trim().isEmpty) {
      throw LeaveValidationException({
        'reason': 'Rejection reason is required',
      });
    }

    final updated = LeaveRequestsCompanion(
      status: const Value('rejected'),
      approvedBy: Value(rejectedBy),
      actionDate: Value(DateTime.now()),
      remarks: Value(reason.trim()),
    );

    final success = await _leaveRepository.updateRequest(requestId, updated);

    if (success) {
      await _logActivity(
        action: 'reject_leave',
        module: 'leave',
        details: 'Rejected leave request for ${request.staffName}',
      );
    }

    return success;
  }

  /// Cancel a pending leave request
  Future<bool> cancelLeaveRequest(int requestId) async {
    final request = await _leaveRepository.getRequestById(requestId);
    if (request == null) {
      throw LeaveNotFoundException('Leave request not found');
    }

    if (!request.isPending) {
      throw LeaveValidationException({
        'status': 'Only pending requests can be cancelled',
      });
    }

    return await _leaveRepository.deleteRequest(requestId);
  }

  /// Get all pending requests
  Future<List<LeaveRequestWithDetails>> getPendingRequests({int? limit}) async {
    return await _leaveRepository.getPendingRequests(limit: limit);
  }

  /// Get requests with filters
  Future<List<LeaveRequestWithDetails>> getRequests({
    String? status,
    int? staffId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    return await _leaveRepository.getAllRequests(
      status: status,
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  /// Get leave balance for a staff member
  Future<List<LeaveBalance>> getLeaveBalance(
    int staffId, {
    String? year,
  }) async {
    return await _leaveRepository.getLeaveBalance(staffId, year: year);
  }

  /// Get all leave types
  Future<List<LeaveType>> getAllLeaveTypes() async {
    return await _leaveRepository.getAllLeaveTypes();
  }

  /// Get staff leaves
  Future<List<LeaveRequestWithDetails>> getStaffLeaves(int staffId) async {
    return await _leaveRepository.getStaffLeaves(staffId);
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  Future<void> _logActivity({
    required String action,
    required String module,
    required String details,
  }) async {
    await _db
        .into(_db.activityLogs)
        .insert(
          ActivityLogsCompanion.insert(
            action: action,
            module: module,
            description: details,
            userId: const Value(null),
          ),
        );
  }
}

/// Exception for leave validation errors
class LeaveValidationException implements Exception {
  final Map<String, String> errors;

  LeaveValidationException(this.errors);

  @override
  String toString() => 'LeaveValidationException: ${errors.values.join(', ')}';
}

/// Exception for leave not found
class LeaveNotFoundException implements Exception {
  final String message;

  LeaveNotFoundException(this.message);

  @override
  String toString() => 'LeaveNotFoundException: $message';
}
