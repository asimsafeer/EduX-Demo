/// EduX School Management System
/// Application Router Configuration using go_router
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/rbac_service.dart';

import '../providers/auth_provider.dart';

import '../features/splash/splash_screen.dart';
import '../features/setup/school_setup_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/account_recovery_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings.dart';
import '../features/settings/screens/print_settings_screen.dart';
import '../features/setup/license_request_screen.dart';

import '../screens/students/student_list_screen.dart';
import '../screens/students/student_form_screen.dart';
import '../screens/students/student_profile_screen.dart';
import '../screens/students/bulk_import_screen.dart';
import '../screens/students/student_promotion_screen.dart';
import '../screens/guardians/guardian_form_screen.dart';
import '../screens/guardians/guardian_list_screen.dart';
import '../screens/guardians/guardian_profile_screen.dart';
import '../screens/academics/academics_screen.dart';
import '../screens/academics/class_subject_assignment_screen.dart';
import '../screens/academics/timetable_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/attendance/mark_attendance_screen.dart';
import '../screens/attendance/attendance_report_screen.dart';
import '../screens/attendance/student_attendance_history_screen.dart';
import '../screens/exams/exams_screen.dart';
import '../screens/exams/exam_form_screen.dart';
import '../screens/exams/marks_entry_screen.dart';
import '../screens/exams/result_analysis_screen.dart';
import '../screens/exams/report_card_screen.dart';
import '../screens/exams/grade_settings_screen.dart';
import '../providers/exam_provider.dart';

import '../screens/fees/fee_dashboard_screen.dart';
import '../screens/fees/fee_structure_screen.dart';
import '../screens/fees/invoices_list_screen.dart';
import '../screens/fees/invoice_details_screen.dart';
import '../screens/fees/invoice_generation_screen.dart';
import '../screens/fees/payment_collection_screen.dart';
import '../screens/fees/payments_list_screen.dart';
import '../screens/fees/payment_details_screen.dart';
import '../screens/fees/defaulters_screen.dart';
import '../screens/fees/fee_reports_screen.dart';

import '../features/reports/reports_screen.dart';
import '../sync/sync.dart';

import '../screens/staff/staff_list_screen.dart';
import '../screens/staff/staff_form_screen.dart';
import '../screens/staff/staff_import_screen.dart';
import '../screens/staff/staff_profile_screen.dart';
import '../screens/staff/staff_attendance_screen.dart';
import '../screens/staff/staff_leave_screen.dart';
import '../screens/staff/staff_payroll_screen.dart';
import '../screens/staff/staff_assignments_screen.dart';
import '../screens/expenses/expense_screen.dart';
import '../screens/canteen/canteen_list_screen.dart';

/// Application route paths
class AppRoutes {
  AppRoutes._();

  // Initial routes
  static const String splash = '/';
  static const String requestLicense = '/request-license';
  static const String setup = '/setup';

  static const String login = '/login';
  static const String accountRecovery = '/login/account-recovery';

  // Main app routes
  static const String dashboard = '/dashboard';
  static const String students = '/students';
  static const String guardians = '/guardians';
  static const String studentDetails = '/students/:id';
  static const String studentAdd = '/students/add';
  static const String studentEdit = '/students/:id/edit';

  static const String staff = '/staff';
  static const String staffDetails = '/staff/:id';
  static const String staffAdd = '/staff/add';
  static const String staffEdit = '/staff/:id/edit';

  static const String academics = '/academics';
  static const String classes = '/academics'; // Alias for sidebar navigation
  static const String classDetails = '/academics/classes/:id';

  static const String attendance = '/attendance';
  static const String attendanceMark = '/attendance/mark/:classId/:sectionId';
  static const String attendanceReports = '/attendance/reports';
  static const String studentAttendanceHistory =
      '/attendance/student/:studentId';

  static const String exams = '/exams';
  static const String examDetails = '/exams/:id';
  static const String examMarks = '/exams/:id/marks';

  static const String fees = '/fees';
  static const String expenses = '/expenses';
  static const String canteen = '/canteen';
  static const String feeStructure = '/fees/structure';
  static const String invoices = '/fees/invoices';
  static const String invoiceGenerate = '/fees/invoices/generate';
  static const String invoiceDetails = '/fees/invoices/:id';
  static const String payments = '/fees/payments';
  static const String paymentDetails = '/fees/payments/:id';
  static const String paymentCollect = '/fees/collect-payment';
  static const String defaulters = '/fees/defaulters';
  static const String feeReports = '/fees/reports';

  static const String reports = '/reports';

  static const String settings = '/settings';
  static const String printSettings = '/settings/print';
  static const String users = '/settings/users';
  static const String backup = '/settings/backup';
  static const String schoolProfile = '/settings/school';
  static const String emailSettings = '/settings/email';
  static const String syncDevices = '/settings/sync-devices';
}

/// Global router key for navigation from outside BuildContext
final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

/// Application router configuration
class AppRouter {
  AppRouter._();

  /// The router instance
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      // 1. Check if public route
      final isPublicRoute =
          state.uri.path == AppRoutes.splash ||
          state.uri.path == AppRoutes.login ||
          state.uri.path == AppRoutes.requestLicense ||
          state.uri.path == AppRoutes.setup ||
          state.uri.path.startsWith('/login/');

      if (isPublicRoute) return null;

      // 2. Check authentication
      if (!context.mounted) return null;
      final container = ProviderScope.containerOf(context);
      final user = container.read(currentUserProvider);

      if (user == null) {
        return AppRoutes.login;
      }

      // 3. Check RBAC permissions
      final rbacService = container.read(rbacServiceProvider);

      // Define route -> permission mapping
      // This could be moved to a static map or helper method
      String? requiredPermission;

      final path = state.uri.path;
      if (path.startsWith(AppRoutes.students)) {
        if (path.contains('/add') ||
            path.contains('/edit') ||
            path.contains('/import') ||
            path.contains('/promotion')) {
          requiredPermission = RbacService.manageStudents;
        } else {
          requiredPermission = RbacService.viewStudents;
        }
      } else if (path.startsWith(AppRoutes.staff)) {
        if (path.contains('/add') ||
            path.contains('/edit') ||
            path.contains('/import')) {
          requiredPermission = RbacService.manageStaff;
        } else {
          requiredPermission = RbacService.viewStaff;
        }
      } else if (path.startsWith(AppRoutes.academics)) {
        // Technically, modifying academics requires manageAcademics,
        // but currently we don't have dedicated edit routes in the URL for most,
        // except maybe subject-assignment, but we'll secure the base for now.
        requiredPermission = RbacService.viewAcademics;
      } else if (path.startsWith(AppRoutes.attendance)) {
        if (path.contains('/mark')) {
          requiredPermission = RbacService.manageAttendance;
        } else {
          requiredPermission = RbacService.viewAttendance;
        }
      } else if (path.startsWith(AppRoutes.exams)) {
        if (path.contains('/edit') ||
            path.contains('/new') ||
            path.contains('/marks') ||
            path.contains('/grades')) {
          requiredPermission = RbacService.manageExams;
        } else {
          requiredPermission = RbacService.viewExams;
        }
      } else if (path.startsWith(AppRoutes.fees)) {
        if (path.contains('/collect-payment') ||
            path.contains('/generate') ||
            path.contains('/structure')) {
          requiredPermission = RbacService.manageFees;
        } else {
          requiredPermission = RbacService.viewFees;
        }
      } else if (path.startsWith(AppRoutes.expenses)) {
        requiredPermission = RbacService.viewExpenses;
      } else if (path.startsWith(AppRoutes.canteen)) {
        requiredPermission = RbacService.viewCanteen;
      } else if (path.startsWith(AppRoutes.reports)) {
        requiredPermission = RbacService.viewReports;
      } else if (path.startsWith(AppRoutes.settings)) {
        requiredPermission = RbacService.viewSettings;
      }

      if (requiredPermission != null &&
          !rbacService.hasPermission(user, requiredPermission)) {
        // User doesn't have permission, redirect to dashboard
        // Or show an access denied page if we had one.
        // For now, if they try to access a page they can't, send them to dashboard.
        // But what if they also don't have dashboard access? (Dashboard usually open to all logged in)
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // License Request Screen
      GoRoute(
        path: AppRoutes.requestLicense,
        name: 'request-license',
        builder: (context, state) => const LicenseRequestScreen(),
      ),

      // School setup wizard
      GoRoute(
        path: AppRoutes.setup,
        name: 'setup',
        builder: (context, state) => const SchoolSetupScreen(),
      ),

      // Login screen
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'account-recovery',
            name: 'account-recovery',
            builder: (context, state) => const AccountRecoveryScreen(),
          ),
        ],
      ),

      // Main app shell with sidebar navigation
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),

          // Guardians
          GoRoute(
            path: AppRoutes.guardians,
            name: 'guardians',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const GuardianListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                name: 'guardian-add',
                builder: (context, state) => const GuardianFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'guardian-details',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const _PlaceholderScreen(
                      title: 'Invalid Guardian ID',
                    );
                  }
                  return GuardianProfileScreen(guardianId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'guardian-edit',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _PlaceholderScreen(
                          title: 'Invalid Guardian ID',
                        );
                      }
                      return GuardianFormScreen(guardianId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Students
          GoRoute(
            path: AppRoutes.students,
            name: 'students',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const StudentListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'student-add',
                builder: (context, state) => const StudentFormScreen(),
              ),
              GoRoute(
                path: 'import',
                name: 'student-import',
                builder: (context, state) => const BulkImportScreen(),
              ),
              GoRoute(
                path: 'promotion',
                name: 'student-promotion',
                builder: (context, state) => const StudentPromotionScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'student-details',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const _PlaceholderScreen(
                      title: 'Invalid Student ID',
                    );
                  }
                  return StudentProfileScreen(studentId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'student-edit',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _PlaceholderScreen(
                          title: 'Invalid Student ID',
                        );
                      }
                      return StudentFormScreen(studentId: id);
                    },
                  ),
                  GoRoute(
                    path: 'guardians/add',
                    name: 'student-guardian-add',
                    builder: (context, state) {
                      final studentId = int.tryParse(
                        state.pathParameters['id'] ?? '',
                      );
                      return GuardianFormScreen(studentId: studentId);
                    },
                  ),
                  GoRoute(
                    path: 'guardians/:guardianId/edit',
                    name: 'student-guardian-edit',
                    builder: (context, state) {
                      final studentId = int.tryParse(
                        state.pathParameters['id'] ?? '',
                      );
                      final guardianId = int.tryParse(
                        state.pathParameters['guardianId'] ?? '',
                      );
                      return GuardianFormScreen(
                        studentId: studentId,
                        guardianId: guardianId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Staff
          GoRoute(
            path: AppRoutes.staff,
            name: 'staff',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const StaffListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'staff-add',
                builder: (context, state) => const StaffFormScreen(),
              ),
              GoRoute(
                path: 'import',
                name: 'staff-import',
                builder: (context, state) => const StaffImportScreen(),
              ),
              GoRoute(
                path: 'attendance',
                name: 'staff-attendance',
                builder: (context, state) => const StaffAttendanceScreen(),
              ),
              GoRoute(
                path: 'leave',
                name: 'staff-leave',
                builder: (context, state) => const StaffLeaveScreen(),
              ),
              GoRoute(
                path: 'payroll',
                name: 'staff-payroll',
                builder: (context, state) => const StaffPayrollScreen(),
              ),
              GoRoute(
                path: 'assignments',
                name: 'staff-assignments',
                builder: (context, state) => const StaffAssignmentsScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'staff-details',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const _PlaceholderScreen(title: 'Invalid Staff ID');
                  }
                  return StaffProfileScreen(staffId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'staff-edit',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _PlaceholderScreen(
                          title: 'Invalid Staff ID',
                        );
                      }
                      return StaffFormScreen(staffId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Academics (replacing Classes)
          GoRoute(
            path: AppRoutes.academics,
            name: 'academics',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AcademicsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'subjects/assign/:classId',
                name: 'subject-assignment',
                builder: (context, state) => ClassSubjectAssignmentScreen(
                  classId: int.parse(state.pathParameters['classId']!),
                ),
              ),
              GoRoute(
                path: 'timetable/:classId/:sectionId',
                name: 'timetable-edit',
                builder: (context, state) => TimetableScreen(
                  // Note: TimetableScreen state currently manages selection,
                  // but we can support deep linking later if we update TimetableScreen to accept arguments
                  // For now, this route might just open the screen or we can update TimetableScreen
                  // The current TimetableScreen implementation manages its own state via dropdowns
                  // So we might not strictly need this deep link yet, or we'd need to refactor.
                  // However, let's keep it simple and just route to the main screen or specific config if needed.
                  // Actually, TimetableScreen consumes its own state.
                  // Let's just return TimetableScreen() and it will show default or persisted state.
                  // But wait, the plan said "TimetableScreen" has dropdowns.
                  // Let's just point to AcademicsScreen with tab index if we want deep linking,
                  // or separate screens.
                  // The AcademicsScreen has tabs.
                  // So /academics opens the tabs.
                  // If we want a specific screen for subject assignment which is NOT in a tab, we add it here.
                  // ClassSubjectAssignmentScreen IS separate.
                ),
              ),
            ],
          ),
          // Alias for legacy /classes if needed, or remove

          // Attendance
          GoRoute(
            path: AppRoutes.attendance,
            name: 'attendance',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AttendanceScreen(),
            ),
            routes: [
              // Mark attendance for a class
              GoRoute(
                path: 'mark/:classId/:sectionId',
                name: 'attendance-mark',
                builder: (context, state) {
                  final classId = int.tryParse(
                    state.pathParameters['classId'] ?? '',
                  );
                  final sectionId = int.tryParse(
                    state.pathParameters['sectionId'] ?? '',
                  );
                  if (classId == null || sectionId == null) {
                    return const _PlaceholderScreen(
                      title: 'Invalid Class/Section',
                    );
                  }
                  return MarkAttendanceScreen(
                    classId: classId,
                    sectionId: sectionId,
                  );
                },
              ),
              // Attendance reports
              GoRoute(
                path: 'reports',
                name: 'attendance-reports',
                builder: (context, state) {
                  final reportType = state.uri.queryParameters['type'];
                  return AttendanceReportScreen(reportType: reportType);
                },
              ),
              // Student attendance history
              GoRoute(
                path: 'student/:studentId',
                name: 'student-attendance-history',
                builder: (context, state) {
                  final studentId = int.tryParse(
                    state.pathParameters['studentId'] ?? '',
                  );
                  if (studentId == null) {
                    return const _PlaceholderScreen(
                      title: 'Invalid Student ID',
                    );
                  }
                  return StudentAttendanceHistoryScreen(studentId: studentId);
                },
              ),
            ],
          ),

          // Exams
          GoRoute(
            path: AppRoutes.exams,
            name: 'exams',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ExamsScreen(),
            ),
            routes: [
              // Create new exam
              GoRoute(
                path: 'new',
                name: 'exam-new',
                builder: (context, state) => const ExamFormScreen(),
              ),
              // Grade settings
              GoRoute(
                path: 'grades',
                name: 'grade-settings',
                builder: (context, state) => const GradeSettingsScreen(),
              ),
              // Exam details and sub-routes
              GoRoute(
                path: ':id',
                name: 'exam-details',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const _PlaceholderScreen(title: 'Invalid Exam ID');
                  }
                  return _ExamDetailRouter(examId: id);
                },
                routes: [
                  // Edit exam
                  GoRoute(
                    path: 'edit',
                    name: 'exam-edit',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _PlaceholderScreen(
                          title: 'Invalid Exam ID',
                        );
                      }
                      return ExamFormScreen(examId: id);
                    },
                  ),
                  // Marks entry
                  GoRoute(
                    path: 'marks',
                    name: 'exam-marks',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _PlaceholderScreen(
                          title: 'Invalid Exam ID',
                        );
                      }
                      final subjectId = int.tryParse(
                        state.uri.queryParameters['subject'] ?? '',
                      );
                      return MarksEntryScreen(examId: id, subjectId: subjectId);
                    },
                  ),
                  // Results / analysis
                  GoRoute(
                    path: 'results',
                    name: 'exam-results',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _PlaceholderScreen(
                          title: 'Invalid Exam ID',
                        );
                      }
                      return ResultAnalysisScreen(examId: id);
                    },
                  ),
                  // Report cards
                  GoRoute(
                    path: 'report-cards',
                    name: 'exam-report-cards',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _PlaceholderScreen(
                          title: 'Invalid Exam ID',
                        );
                      }
                      return ReportCardScreen(examId: id);
                    },
                    routes: [
                      // Single student report card
                      GoRoute(
                        path: ':studentId',
                        name: 'student-report-card',
                        builder: (context, state) {
                          final examId = int.tryParse(
                            state.pathParameters['id'] ?? '',
                          );
                          final studentId = int.tryParse(
                            state.pathParameters['studentId'] ?? '',
                          );
                          if (examId == null || studentId == null) {
                            return const _PlaceholderScreen(
                              title: 'Invalid IDs',
                            );
                          }
                          return ReportCardScreen(
                            examId: examId,
                            studentId: studentId,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Fees
          GoRoute(
            path: AppRoutes.fees,
            name: 'fees',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const FeeDashboardScreen(),
            ),
            routes: [
              GoRoute(
                path: 'structure',
                name: 'fee-structure',
                builder: (context, state) => const FeeStructureScreen(),
              ),
              GoRoute(
                path: 'invoices',
                name: 'invoices',
                builder: (context, state) => const InvoicesListScreen(),
                routes: [
                  GoRoute(
                    path: 'generate',
                    name: 'invoice-generate',
                    builder: (context, state) {
                      final studentId = int.tryParse(
                        state.uri.queryParameters['studentId'] ?? '',
                      );
                      return InvoiceGenerationScreen(studentId: studentId);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'invoice-details',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _PlaceholderScreen(
                          title: 'Invalid Invoice ID',
                        );
                      }
                      return InvoiceDetailsScreen(invoiceId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'payments',
                name: 'payments',
                builder: (context, state) => const PaymentsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'payment-details',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _PlaceholderScreen(
                          title: 'Invalid Payment ID',
                        );
                      }
                      return PaymentDetailsScreen(paymentId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'collect-payment',
                name: 'collect-payment',
                builder: (context, state) {
                  final invoiceId = int.tryParse(
                    state.uri.queryParameters['invoiceId'] ?? '',
                  );
                  final studentId = int.tryParse(
                    state.uri.queryParameters['studentId'] ?? '',
                  );
                  return PaymentCollectionScreen(
                    invoiceId: invoiceId,
                    studentId: studentId,
                  );
                },
              ),
              GoRoute(
                path: 'defaulters',
                name: 'defaulters',
                builder: (context, state) => const DefaultersScreen(),
              ),
              GoRoute(
                path: 'reports',
                name: 'fee-reports',
                builder: (context, state) => const FeeReportsScreen(),
              ),
            ],
          ),

          // Expenses
          GoRoute(
            path: AppRoutes.expenses,
            name: 'expenses',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ExpenseScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.canteen,
            name: 'canteen',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CanteenListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ReportsScreen(),
            ),
          ),

          // Settings - UPDATED with actual screens
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
            routes: [
              // School Profile
              GoRoute(
                path: 'school',
                name: 'school-profile',
                builder: (context, state) => const SchoolProfileScreen(),
              ),
              // Academic Settings
              GoRoute(
                path: 'academic',
                name: 'academic-settings',
                builder: (context, state) => const AcademicSettingsScreen(),
              ),
              // User Management
              GoRoute(
                path: 'users',
                name: 'users',
                builder: (context, state) => const UserManagementScreen(),
                routes: [
                  // New user
                  GoRoute(
                    path: 'new',
                    name: 'user-new',
                    builder: (context, state) => const UserFormScreen(),
                  ),
                  // Edit user
                  GoRoute(
                    path: ':id',
                    name: 'user-edit',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      return UserFormScreen(userId: id);
                    },
                  ),
                ],
              ),
              // Activity Log
              GoRoute(
                path: 'activity-log',
                name: 'activity-log',
                builder: (context, state) => const ActivityLogScreen(),
              ),
              // Backup & Restore
              GoRoute(
                path: 'backup',
                name: 'backup',
                builder: (context, state) => const BackupScreen(),
              ),
              // Print Settings (NEW)
              GoRoute(
                path: 'print',
                name: 'print-settings',
                builder: (context, state) => const PrintSettingsScreen(),
              ),
              // Sync Devices (NEW)
              GoRoute(
                path: 'sync-devices',
                name: 'sync-devices',
                builder: (context, state) => const SyncManagementScreen(),
              ),
            ],
          ),
        ],
      ),
    ],

    // Error handler
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.uri.path}" does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'This screen will be implemented in the next phase.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smart router widget that checks exam status and shows the appropriate screen
/// Draft exams → Edit form, Active → Marks entry, Completed → Results
class _ExamDetailRouter extends ConsumerWidget {
  final int examId;

  const _ExamDetailRouter({required this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsListProvider);

    return examsAsync.when(
      data: (exams) {
        final exam = exams.where((e) => e.exam.id == examId).firstOrNull;
        if (exam == null) {
          return const _PlaceholderScreen(title: 'Exam Not Found');
        }

        switch (exam.exam.status) {
          case 'draft':
            return ExamFormScreen(examId: examId);
          case 'active':
            return MarksEntryScreen(examId: examId);
          case 'completed':
            return ResultAnalysisScreen(examId: examId);
          default:
            return ExamFormScreen(examId: examId);
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _PlaceholderScreen(title: 'Error: $error'),
    );
  }
}
