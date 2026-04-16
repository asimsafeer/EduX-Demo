/// NovaByte Hub — Riverpod Providers
/// Centralized provider definitions for the entire app
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats.dart';
import '../models/license.dart';
import '../models/license_request.dart';
import '../models/school.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/security_service.dart';

// ============================================================
// SERVICE PROVIDERS
// ============================================================

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ============================================================
// AUTH PROVIDERS
// ============================================================

/// Stream of Firebase auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current admin display name
final adminNameProvider = FutureProvider<String>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getAdminName();
});

/// Current admin email
final adminEmailProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.getAdminEmail();
});

// ============================================================
// DASHBOARD PROVIDERS
// ============================================================

/// Real-time dashboard statistics
final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getDashboardStats();
});

// ============================================================
// REQUEST PROVIDERS
// ============================================================

/// All license requests (real-time stream)
final allRequestsProvider = StreamProvider<List<LicenseRequest>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllRequests();
});

/// Pending requests (real-time stream, for badges)
final pendingRequestsProvider = StreamProvider<List<LicenseRequest>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getPendingRequests();
});

/// Requests filtered by status
final filteredRequestsProvider =
    StreamProvider.family<List<LicenseRequest>, String?>((ref, status) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      if (status == null || status.isEmpty) {
        return firestoreService.getAllRequests();
      }
      return firestoreService.getRequestsByStatus(status);
    });

/// Single request by ID
final requestDetailProvider = FutureProvider.family<LicenseRequest?, String>((
  ref,
  requestId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getRequestById(requestId);
});

/// Requests for a specific school
final schoolRequestsProvider =
    StreamProvider.family<List<LicenseRequest>, String>((ref, schoolId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getRequestsForSchool(schoolId);
    });

// ============================================================
// SCHOOL PROVIDERS
// ============================================================

/// All registered schools (real-time stream)
final allSchoolsProvider = StreamProvider<List<School>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllSchools();
});

/// Single school by ID
final schoolDetailProvider = FutureProvider.family<School?, String>((
  ref,
  schoolId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSchoolById(schoolId);
});

/// Search schools
final schoolSearchProvider = StreamProvider.family<List<School>, String>((
  ref,
  query,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.searchSchools(query);
});

// ============================================================
// LICENSE PROVIDERS
// ============================================================

/// License for a specific school
final schoolLicenseProvider = FutureProvider.family<License?, String>((
  ref,
  schoolId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getLicenseBySchoolId(schoolId);
});

/// Real-time license stream for a school
final watchLicenseProvider = StreamProvider.family<License?, String>((
  ref,
  schoolId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchLicense(schoolId);
});

/// All active licenses
final activeLicensesProvider = StreamProvider<List<License>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getActiveLicenses();
});

// ============================================================
// PENDING REQUEST COUNT (for badges)
// ============================================================

/// Count of pending requests (derived from pendingRequestsProvider)
final pendingCountProvider = Provider<int>((ref) {
  final pending = ref.watch(pendingRequestsProvider);
  return pending.when(
    data: (requests) => requests.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ============================================================
// REQUEST COUNT BY STATUS (for filter chip badges)
// ============================================================

/// Map of status → count for filter chip badges
final requestCountByStatusProvider = Provider<Map<String, int>>((ref) {
  final allRequests = ref.watch(allRequestsProvider);
  return allRequests.when(
    data: (requests) {
      final counts = <String, int>{};
      for (final req in requests) {
        counts[req.status] = (counts[req.status] ?? 0) + 1;
      }
      counts['all'] = requests.length;
      return counts;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// ============================================================
// SCHOOL WITH LICENSE DATA (for school cards with status)
// ============================================================

/// Combines school list with their license data for status dots
final schoolWithLicenseProvider =
    FutureProvider<List<({School school, License? license})>>((ref) async {
      final firestoreService = ref.watch(firestoreServiceProvider);
      final schools = await firestoreService.getAllSchoolsOnce();
      final results = <({School school, License? license})>[];
      for (final school in schools) {
        final license = await firestoreService.getLicenseBySchoolId(
          school.schoolId,
        );
        results.add((school: school, license: license));
      }
      return results;
    });

// ============================================================
// NOTIFICATION PREFERENCES
// ============================================================

/// Notification toggle state provider
final notificationEnabledProvider = StateProvider<bool>((ref) => true);

/// Default license duration in days
final defaultLicenseDurationProvider = StateProvider<int>((ref) => 365);

// ============================================================
// SECURITY SERVICE
// ============================================================

/// Security service provider
final securityServiceProvider = Provider<SecurityService>((ref) {
  return const SecurityService();
});

// ============================================================
// AUDIT LOG
// ============================================================

/// Stream audit log for a specific school
final auditLogProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, schoolId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getAuditLog(schoolId);
    });
