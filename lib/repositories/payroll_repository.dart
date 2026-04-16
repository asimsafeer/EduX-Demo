/// EduX School Management System
/// Payroll Repository - Data access layer for payroll management
library;

import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../core/constants/app_constants.dart';

/// Data class for payroll with staff information
class PayrollWithStaff {
  final PayrollData payroll;
  final StaffData staff;

  const PayrollWithStaff({required this.payroll, required this.staff});

  String get staffName => '${staff.firstName} ${staff.lastName}'.trim();

  Map<String, double> get allowancesMap {
    if (payroll.allowancesBreakdown == null) return {};
    try {
      final decoded = jsonDecode(payroll.allowancesBreakdown!);
      return Map<String, double>.from(
        decoded.map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
    } catch (_) {
      return {};
    }
  }

  Map<String, double> get deductionsMap {
    if (payroll.deductionsBreakdown == null) return {};
    try {
      final decoded = jsonDecode(payroll.deductionsBreakdown!);
      return Map<String, double>.from(
        decoded.map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
    } catch (_) {
      return {};
    }
  }
}

/// Payroll summary for a month
class PayrollMonthlySummary {
  final String month;
  final int totalStaff;
  final int pending;
  final int paid;
  final double totalBasicSalary;
  final double totalAllowances;
  final double totalDeductions;
  final double totalNetSalary;

  const PayrollMonthlySummary({
    required this.month,
    required this.totalStaff,
    required this.pending,
    required this.paid,
    required this.totalBasicSalary,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.totalNetSalary,
  });
}

/// Abstract payroll repository interface
abstract class PayrollRepository {
  Future<PayrollData?> getById(int id);
  Future<PayrollWithStaff?> getByIdWithStaff(int id);
  Future<PayrollData?> getByStaffAndMonth(int staffId, String month);

  Future<int> create(PayrollCompanion payroll);
  Future<bool> update(int id, PayrollCompanion payroll);
  Future<bool> delete(int id);

  Future<List<PayrollWithStaff>> getByMonth(String month);
  Future<List<PayrollWithStaff>> getByStaff(int staffId);
  Future<List<PayrollWithStaff>> getPending({String? month});

  Future<bool> markAsPaid(
    int id, {
    required DateTime paidDate,
    required String paymentMode,
    String? referenceNumber,
    required int processedBy,
  });

  Future<PayrollMonthlySummary> getMonthlySummary(String month);

  Future<bool> generateMonthlyPayroll({
    required String month,
    required int workingDays,
    required int generatedBy,
  });

  Future<bool> payrollExistsForMonth(String month);
}

/// Implementation of PayrollRepository using Drift database
class PayrollRepositoryImpl implements PayrollRepository {
  final AppDatabase _db;

  PayrollRepositoryImpl(this._db);

  @override
  Future<PayrollData?> getById(int id) async {
    return await (_db.select(
      _db.payroll,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<PayrollWithStaff?> getByIdWithStaff(int id) async {
    final query = _db.select(_db.payroll).join([
      innerJoin(_db.staff, _db.staff.id.equalsExp(_db.payroll.staffId)),
    ])..where(_db.payroll.id.equals(id));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    return PayrollWithStaff(
      payroll: result.readTable(_db.payroll),
      staff: result.readTable(_db.staff),
    );
  }

  @override
  Future<PayrollData?> getByStaffAndMonth(int staffId, String month) async {
    return await (_db.select(_db.payroll)
          ..where((t) => t.staffId.equals(staffId) & t.month.equals(month)))
        .getSingleOrNull();
  }

  @override
  Future<int> create(PayrollCompanion payroll) async {
    return await _db.into(_db.payroll).insert(payroll);
  }

  @override
  Future<bool> update(int id, PayrollCompanion payroll) async {
    final updated = payroll.copyWith(updatedAt: Value(DateTime.now()));
    final rowsAffected = await (_db.update(
      _db.payroll,
    )..where((t) => t.id.equals(id))).write(updated);
    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final rowsAffected = await (_db.delete(
      _db.payroll,
    )..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  @override
  Future<List<PayrollWithStaff>> getByMonth(String month) async {
    final query =
        _db.select(_db.payroll).join([
            innerJoin(_db.staff, _db.staff.id.equalsExp(_db.payroll.staffId)),
          ])
          ..where(_db.payroll.month.equals(month))
          ..orderBy([OrderingTerm.asc(_db.staff.firstName)]);

    final results = await query.get();
    return results.map((row) {
      return PayrollWithStaff(
        payroll: row.readTable(_db.payroll),
        staff: row.readTable(_db.staff),
      );
    }).toList();
  }

  @override
  Future<List<PayrollWithStaff>> getByStaff(int staffId) async {
    final query =
        _db.select(_db.payroll).join([
            innerJoin(_db.staff, _db.staff.id.equalsExp(_db.payroll.staffId)),
          ])
          ..where(_db.payroll.staffId.equals(staffId))
          ..orderBy([OrderingTerm.desc(_db.payroll.month)]);

    final results = await query.get();
    return results.map((row) {
      return PayrollWithStaff(
        payroll: row.readTable(_db.payroll),
        staff: row.readTable(_db.staff),
      );
    }).toList();
  }

  @override
  Future<List<PayrollWithStaff>> getPending({String? month}) async {
    final query =
        _db.select(_db.payroll).join([
            innerJoin(_db.staff, _db.staff.id.equalsExp(_db.payroll.staffId)),
          ])
          ..where(_db.payroll.status.equals('pending'))
          ..orderBy([OrderingTerm.asc(_db.staff.firstName)]);

    if (month != null) {
      query.where(_db.payroll.month.equals(month));
    }

    final results = await query.get();
    return results.map((row) {
      return PayrollWithStaff(
        payroll: row.readTable(_db.payroll),
        staff: row.readTable(_db.staff),
      );
    }).toList();
  }

  @override
  Future<bool> markAsPaid(
    int id, {
    required DateTime paidDate,
    required String paymentMode,
    String? referenceNumber,
    required int processedBy,
  }) async {
    final rowsAffected =
        await (_db.update(_db.payroll)..where((t) => t.id.equals(id))).write(
          PayrollCompanion(
            status: const Value('paid'),
            paidDate: Value(paidDate),
            paymentMode: Value(paymentMode),
            referenceNumber: Value(referenceNumber),
            processedBy: Value(processedBy),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return rowsAffected > 0;
  }

  @override
  Future<PayrollMonthlySummary> getMonthlySummary(String month) async {
    final payrolls = await getByMonth(month);

    int pending = 0;
    int paid = 0;
    double totalBasicSalary = 0;
    double totalAllowances = 0;
    double totalDeductions = 0;
    double totalNetSalary = 0;

    for (final payroll in payrolls) {
      if (payroll.payroll.status == LeaveConstants.statusPending) {
        pending++;
      } else {
        paid++;
      }
      totalBasicSalary += payroll.payroll.basicSalary;
      totalAllowances += payroll.payroll.allowances;
      totalDeductions += payroll.payroll.deductions;
      totalNetSalary += payroll.payroll.netSalary;
    }

    return PayrollMonthlySummary(
      month: month,
      totalStaff: payrolls.length,
      pending: pending,
      paid: paid,
      totalBasicSalary: totalBasicSalary,
      totalAllowances: totalAllowances,
      totalDeductions: totalDeductions,
      totalNetSalary: totalNetSalary,
    );
  }

  @override
  Future<bool> generateMonthlyPayroll({
    required String month,
    required int workingDays,
    required int generatedBy,
  }) async {
    // Get all active staff
    final activeStaff = await (_db.select(
      _db.staff,
    )..where((t) => t.status.equals('active'))).get();

    if (activeStaff.isEmpty) return false;

    // Parse month for date range
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);
    final startDate = DateTime(year, monthNum, 1);
    final endDate = DateTime(year, monthNum + 1, 0);

    await _db.batch((batch) async {
      for (final staff in activeStaff) {
        // Check if payroll already exists
        final existing = await getByStaffAndMonth(staff.id, month);
        if (existing != null) continue;

        // Get attendance stats for the month
        final attendanceRecords =
            await (_db.select(_db.staffAttendance)..where(
                  (t) =>
                      t.staffId.equals(staff.id) &
                      t.date.isBiggerOrEqualValue(startDate) &
                      t.date.isSmallerOrEqualValue(endDate),
                ))
                .get();

        int daysPresent = 0;
        int daysAbsent = 0;
        int leaveDays = 0;

        for (final record in attendanceRecords) {
          switch (record.status) {
            case 'present':
            case 'late':
              daysPresent++;
              break;
            case 'half_day':
              daysPresent++;
              break;
            case 'absent':
              daysAbsent++;
              break;
            case 'leave':
              leaveDays++;
              break;
          }
        }

        // Calculate salary
        final perDaySalary = staff.basicSalary / workingDays;
        final absentDeduction = daysAbsent * perDaySalary;

        // Net salary = basic - absent deductions
        final netSalary = staff.basicSalary - absentDeduction;

        final deductionsBreakdown = absentDeduction > 0
            ? {'Absent Days': absentDeduction}
            : null;

        batch.insert(
          _db.payroll,
          PayrollCompanion.insert(
            staffId: staff.id,
            month: month,
            basicSalary: staff.basicSalary,
            allowances: const Value(0),
            deductions: Value(absentDeduction),
            deductionsBreakdown: Value(
              deductionsBreakdown != null
                  ? jsonEncode(deductionsBreakdown)
                  : null,
            ),
            netSalary: netSalary,
            workingDays: workingDays,
            daysPresent: daysPresent,
            daysAbsent: daysAbsent,
            leaveDays: Value(leaveDays),
            status: const Value('pending'),
            processedBy: Value(generatedBy),
          ),
        );
      }
    });

    return true;
  }

  @override
  Future<bool> payrollExistsForMonth(String month) async {
    final query = _db.selectOnly(_db.payroll)
      ..addColumns([_db.payroll.id.count()])
      ..where(_db.payroll.month.equals(month));

    final result = await query.getSingle();
    final count = result.read(_db.payroll.id.count()) ?? 0;
    return count > 0;
  }
}
