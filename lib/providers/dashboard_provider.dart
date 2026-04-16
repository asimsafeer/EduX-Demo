/// EduX School Management System
/// Dashboard Provider - State management for dashboard statistics
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../repositories/student_repository.dart';
import '../repositories/staff_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/exam_repository.dart';

import '../services/activity_log_service.dart';
import 'assigned_classes_provider.dart';

/// Dashboard statistics data class
class DashboardStats {
  final int totalStudents;
  final int newStudentsThisMonth;
  final int totalStaff;
  final int activeTeachers;
  final double feeCollectedThisMonth;
  final double feeCollectedLastMonth;
  final double attendanceToday;
  final int presentToday;
  final int totalEnrolledToday;
  final double outstandingFees;
  final int activeExams;
  final int pendingLeaveRequests;

  const DashboardStats({
    this.totalStudents = 0,
    this.newStudentsThisMonth = 0,
    this.totalStaff = 0,
    this.activeTeachers = 0,
    this.feeCollectedThisMonth = 0,
    this.feeCollectedLastMonth = 0,
    this.attendanceToday = 0,
    this.presentToday = 0,
    this.totalEnrolledToday = 0,
    this.outstandingFees = 0,
    this.activeExams = 0,
    this.pendingLeaveRequests = 0,
  });

  String get feeCollectedFormatted =>
      'PKR ${NumberFormat('#,###').format(feeCollectedThisMonth.round())}';

  String get outstandingFeesFormatted =>
      'PKR ${NumberFormat('#,###').format(outstandingFees.round())}';

  String get attendancePercentage => '${attendanceToday.toStringAsFixed(0)}%';

  double get feeCollectionTrend {
    if (feeCollectedLastMonth == 0) return 0;
    return ((feeCollectedThisMonth - feeCollectedLastMonth) /
            feeCollectedLastMonth) *
        100;
  }
}

/// Chart data point for trends
class ChartDataPoint {
  final String label;
  final double value;
  final DateTime? date;

  const ChartDataPoint({required this.label, required this.value, this.date});
}

/// Data point for profit vs loss
class ProfitLossDataPoint {
  final String label;
  final double income;
  final double expense;
  final DateTime? date;

  const ProfitLossDataPoint({
    required this.label,
    required this.income,
    required this.expense,
    this.date,
  });
}

/// Alert severity levels
enum AlertSeverity { info, warning, critical }

/// Dashboard alert
class DashboardAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final String? actionRoute;
  final DateTime createdAt;

  const DashboardAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.actionRoute,
    required this.createdAt,
  });
}

/// Dashboard state
class DashboardState {
  final DashboardStats stats;
  final List<ChartDataPoint> attendanceTrend;
  final List<ChartDataPoint> feeCollectionTrend;
  final List<ChartDataPoint> classDistribution;
  final List<ActivityLog> recentActivity;
  final List<DashboardAlert> alerts;
  final List<ChartDataPoint> monthlyExpenses;
  final List<ProfitLossDataPoint> profitLossData;
  final List<ChartDataPoint> admissionTrend;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.stats = const DashboardStats(),
    this.attendanceTrend = const [],
    this.feeCollectionTrend = const [],
    this.classDistribution = const [],
    this.recentActivity = const [],
    this.alerts = const [],
    this.monthlyExpenses = const [],
    this.profitLossData = const [],
    this.admissionTrend = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardStats? stats,
    List<ChartDataPoint>? attendanceTrend,
    List<ChartDataPoint>? feeCollectionTrend,
    List<ChartDataPoint>? classDistribution,
    List<ActivityLog>? recentActivity,
    List<DashboardAlert>? alerts,
    List<ChartDataPoint>? monthlyExpenses,
    List<ProfitLossDataPoint>? profitLossData,
    List<ChartDataPoint>? admissionTrend,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      attendanceTrend: attendanceTrend ?? this.attendanceTrend,
      feeCollectionTrend: feeCollectionTrend ?? this.feeCollectionTrend,
      classDistribution: classDistribution ?? this.classDistribution,
      recentActivity: recentActivity ?? this.recentActivity,
      alerts: alerts ?? this.alerts,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      profitLossData: profitLossData ?? this.profitLossData,
      admissionTrend: admissionTrend ?? this.admissionTrend,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Dashboard provider
class DashboardNotifier extends StateNotifier<DashboardState> {
  final AppDatabase _db;
  final StudentRepository _studentRepo;
  final StaffRepository _staffRepo;
  final PaymentRepository _paymentRepo;
  final AttendanceRepository _attendanceRepo;
  final InvoiceRepository _invoiceRepo;
  final ExamRepository _examRepo;
  final ActivityLogService _activityLogService;

  /// null means "all classes" (admin/principal), `List<int>` means restricted.
  final List<int>? _assignedClassIds;

  DashboardNotifier(this._db, {List<int>? assignedClassIds})
    : _studentRepo = StudentRepositoryImpl(_db),
      _staffRepo = StaffRepositoryImpl(_db),
      _paymentRepo = DriftPaymentRepository(_db),
      _attendanceRepo = AttendanceRepositoryImpl(_db),
      _invoiceRepo = DriftInvoiceRepository(_db),
      _examRepo = DriftExamRepository(_db),
      _activityLogService = ActivityLogService(_db),
      _assignedClassIds = assignedClassIds,
      super(const DashboardState(isLoading: true)) {
    loadDashboard();
  }

  bool get _isRestricted => _assignedClassIds != null;

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboard();
  }

  Future<DashboardStats> _loadStats() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);

    // --- Student count (filtered by assigned classes for teachers) ---
    int totalStudents;
    if (_isRestricted && _assignedClassIds!.isNotEmpty) {
      int sum = 0;
      for (final cid in _assignedClassIds) {
        sum += await _studentRepo.count(classId: cid, status: 'active');
      }
      totalStudents = sum;
    } else if (_isRestricted && _assignedClassIds!.isEmpty) {
      totalStudents = 0;
    } else {
      totalStudents = await _studentRepo.count(status: 'active');
    }

    final totalStaff = _isRestricted
        ? 0
        : await _staffRepo.count(status: 'active');

    // --- Fee data (only show for admin/principal/accountant) ---
    final feeCollected = _isRestricted
        ? 0.0
        : await _paymentRepo.getTotalCollectionForPeriod(
            from: startOfMonth,
            to: now,
          );

    final feeCollectedLast = _isRestricted
        ? 0.0
        : await _paymentRepo.getTotalCollectionForPeriod(
            from: lastMonthStart,
            to: lastMonthEnd,
          );

    final outstanding = _isRestricted
        ? 0.0
        : await _invoiceRepo.getTotalOutstanding();

    final activeExams = await _examRepo.countExamsByStatus('active');

    // Get real attendance data
    final attendanceTodayCount = await _attendanceRepo
        .getTotalAttendanceForDate(now);
    final presentToday = await _attendanceRepo.getTotalAttendanceForDate(
      now,
      status: 'present',
    );
    final lateToday = await _attendanceRepo.getTotalAttendanceForDate(
      now,
      status: 'late',
    );
    final presentCount = presentToday + lateToday;

    return DashboardStats(
      totalStudents: totalStudents,
      newStudentsThisMonth: 0,
      totalStaff: totalStaff,
      activeTeachers: totalStaff,
      feeCollectedThisMonth: feeCollected,
      feeCollectedLastMonth: feeCollectedLast,
      attendanceToday: attendanceTodayCount > 0
          ? (presentCount / attendanceTodayCount) * 100
          : 0.0,
      presentToday: presentCount,
      totalEnrolledToday: attendanceTodayCount > 0
          ? attendanceTodayCount
          : totalStudents,
      outstandingFees: outstanding,
      activeExams: activeExams,
      pendingLeaveRequests: 0,
    );
  }

  Future<List<ChartDataPoint>> _loadAttendanceTrend() async {
    // Return empty trend - getDailySummary requires classId/sectionId
    return <ChartDataPoint>[];
  }

  Future<List<ChartDataPoint>> _loadFeeCollectionTrend() async {
    final now = DateTime.now();
    final trend = <ChartDataPoint>[];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final endOfMonth = DateTime(now.year, now.month - i + 1, 0);

      final total = await _paymentRepo.getTotalCollectionForPeriod(
        from: date,
        to: endOfMonth,
      );

      trend.add(
        ChartDataPoint(
          label: DateFormat('MMM').format(date),
          value: total,
          date: date,
        ),
      );
    }

    return trend;
  }

  Future<List<ChartDataPoint>> _loadClassDistribution() async {
    final allClasses = await (_db.select(_db.classes)).get();
    final distribution = <ChartDataPoint>[];

    // Filter to only assigned classes for restricted users
    final classes = _isRestricted
        ? allClasses.where((c) => _assignedClassIds!.contains(c.id)).toList()
        : allClasses;

    for (final cls in classes) {
      final count = await _studentRepo.count(classId: cls.id);
      if (count > 0) {
        distribution.add(
          ChartDataPoint(label: cls.name, value: count.toDouble()),
        );
      }
    }

    return distribution;
  }

  Future<List<ActivityLog>> _loadRecentActivity() async {
    return _activityLogService.getRecentLogs(limit: 10);
  }

  Future<List<DashboardAlert>> _loadAlerts() async {
    final alerts = <DashboardAlert>[];

    // Check for low attendance students
    final lowAttendance = await _attendanceRepo.getLowAttendanceAlerts(
      threshold: 75.0,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );

    if (lowAttendance.isNotEmpty) {
      alerts.add(
        DashboardAlert(
          id: 'low_attendance',
          title: 'Low Attendance Alert',
          message: '${lowAttendance.length} students have attendance below 75%',
          severity: AlertSeverity.warning,
          actionRoute: '/reports/attendance',
          createdAt: DateTime.now(),
        ),
      );
    }

    // Check for large outstanding fees
    final outstanding = await _invoiceRepo.getTotalOutstanding();
    if (outstanding > 100000) {
      alerts.add(
        DashboardAlert(
          id: 'high_outstanding',
          title: 'High Outstanding Fees',
          message:
              'Total outstanding fees: PKR ${NumberFormat('#,###').format(outstanding)}',
          severity: AlertSeverity.critical,
          actionRoute: '/fees/reports',
          createdAt: DateTime.now(),
        ),
      );
    }
    return alerts;
  }

  Future<List<ChartDataPoint>> _loadMonthlyExpenses() async {
    final List<ChartDataPoint> trend = [];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = DateFormat('yyyy-MM').format(date);
      final monthLabel = DateFormat('MMM').format(date);

      final query = _db.select(_db.payroll)
        ..where((t) => t.month.equals(monthStr))
        ..where((t) => t.status.equals('paid'));

      final payrolls = await query.get();
      final totalExpense = payrolls.fold(
        0.0,
        (sum, item) => sum + item.netSalary,
      );

      trend.add(
        ChartDataPoint(label: monthLabel, value: totalExpense, date: date),
      );
    }

    return trend;
  }

  /// Load profit vs loss data (Daily - Last 30 days)
  Future<List<ProfitLossDataPoint>> _loadProfitLoss() async {
    final List<ProfitLossDataPoint> data = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Iterate through each day of the last 30 days
    for (int i = 0; i <= 30; i++) {
      final date = DateTime(
        thirtyDaysAgo.year,
        thirtyDaysAgo.month,
        thirtyDaysAgo.day + i,
      );
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final label = DateFormat('d MMM').format(date);

      // Income (Fees) - Collected on this day
      final feeCollection = await _paymentRepo.getTotalCollectionForPeriod(
        from: startOfDay,
        to: endOfDay,
      );

      // Expense (Payroll) - Paid on this day
      final payrolls =
          await (_db.select(_db.payroll)
                ..where((t) => t.paidDate.isBiggerOrEqualValue(startOfDay))
                ..where((t) => t.paidDate.isSmallerOrEqualValue(endOfDay))
                ..where((t) => t.status.equals('paid')))
              .get();

      final payrollExpense = payrolls.fold(
        0.0,
        (sum, item) => sum + item.netSalary,
      );

      // Expense (General) - Incurred on this day
      final expenses =
          await (_db.select(_db.expenses)
                ..where((t) => t.date.isBiggerOrEqualValue(startOfDay))
                ..where((t) => t.date.isSmallerOrEqualValue(endOfDay)))
              .get();

      final generalExpense = expenses.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );

      data.add(
        ProfitLossDataPoint(
          label: label,
          income: feeCollection,
          expense: payrollExpense + generalExpense,
          date: date,
        ),
      );
    }

    return data;
  }

  /// Load student admission trend
  Future<List<ChartDataPoint>> _loadAdmissionTrend() async {
    final List<ChartDataPoint> trend = [];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthLabel = DateFormat('MMM').format(date);
      final endOfMonth = DateTime(now.year, now.month - i + 1, 0);

      final count = await _studentRepo.count(
        admissionFrom: date,
        admissionTo: endOfMonth,
      );

      trend.add(
        ChartDataPoint(label: monthLabel, value: count.toDouble(), date: date),
      );
    }

    return trend;
  }

  Future<void> loadDashboard() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _loadStats(),
        _loadAttendanceTrend(),
        _loadFeeCollectionTrend(),
        _loadClassDistribution(),
        _loadRecentActivity(),
        _loadAlerts(),
        _loadMonthlyExpenses(),
        _loadProfitLoss(),
        _loadAdmissionTrend(),
      ]);

      if (!mounted) return;
      state = state.copyWith(
        stats: results[0] as DashboardStats,
        attendanceTrend: results[1] as List<ChartDataPoint>,
        feeCollectionTrend: results[2] as List<ChartDataPoint>,
        classDistribution: results[3] as List<ChartDataPoint>,
        recentActivity: results[4] as List<ActivityLog>,
        alerts: results[5] as List<DashboardAlert>,
        monthlyExpenses: results[6] as List<ChartDataPoint>,
        profitLossData: results[7] as List<ProfitLossDataPoint>,
        admissionTrend: results[8] as List<ChartDataPoint>,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard: $e',
      );
    }
  }
}

/// Provider instance
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      // Read assigned class IDs from the provider.
      // When loading or errored, default to null (show all, same as admin).
      final asyncClassIds = ref.watch(assignedClassIdsProvider);
      final classIds = asyncClassIds.whenOrNull(data: (ids) => ids);

      return DashboardNotifier(
        AppDatabase.instance,
        assignedClassIds: classIds,
      );
    });
