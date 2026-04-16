/// NovaByte Hub — Firestore Service (Phase 5 — Security Hardened)
/// All Firestore CRUD with validation, audit logging, and duplicate guards.
library;

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/module_constants.dart';
import '../models/school.dart';
import '../models/license_request.dart';
import '../models/license.dart';
import '../models/dashboard_stats.dart';
import 'security_service.dart';

/// Audit log entry types
class AuditAction {
  AuditAction._();

  static const String approved = 'license_approved';
  static const String rejected = 'request_rejected';
  static const String revoked = 'license_revoked';
  static const String extended = 'license_extended';
  static const String modulesUpdated = 'modules_updated';
  static const String licenseGranted = 'license_granted';
  static const String requestDeleted = 'request_deleted';
}

/// Service for all Firestore database operations (security-hardened)
class FirestoreService {
  final FirebaseFirestore _firestore;
  final SecurityService _security;

  FirestoreService({
    FirebaseFirestore? firestore,
    SecurityService? securityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _security = securityService ?? const SecurityService();

  // ============================================================
  // SECURITY HELPERS
  // ============================================================

  String _computeIntegrityHash({
    required String schoolId,
    required DateTime expiresAt,
    required List<String> modules,
  }) {
    // Sort modules to ensure consistent hash
    final sortedModules = List<String>.from(modules)..sort();
    final data =
        '$schoolId|${expiresAt.toIso8601String()}|${sortedModules.join(', ')}|EDX_LICENSE_SECRET_V1';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 32);
  }

  // ============================================================
  // COLLECTION REFERENCES
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _schoolsRef =>
      _firestore.collection(FirestoreCollections.schools);

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection(FirestoreCollections.licenseRequests);

  CollectionReference<Map<String, dynamic>> get _licensesRef =>
      _firestore.collection(FirestoreCollections.licenses);

  // ============================================================
  // AUDIT LOGGING
  // ============================================================

  /// Write an immutable audit log entry for a school
  Future<void> _writeAuditLog({
    required String schoolId,
    required String action,
    required String adminUid,
    Map<String, dynamic>? details,
  }) async {
    await _schoolsRef.doc(schoolId).collection('audit_log').add({
      'action': action,
      'adminUid': adminUid,
      'timestamp': FieldValue.serverTimestamp(),
      'details': details ?? {},
    });
  }

  /// Stream audit log entries for a school (newest first)
  Stream<List<Map<String, dynamic>>> getAuditLog(String schoolId) {
    return _schoolsRef
        .doc(schoolId)
        .collection('audit_log')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  // ============================================================
  // LICENSE REQUESTS — Real-time streams & CRUD
  // ============================================================

  /// Stream of all license requests, ordered by date (newest first)
  /// Excludes superseded/rejected requests to reduce noise
  Stream<List<LicenseRequest>> getAllRequests() {
    return _requestsRef
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LicenseRequest.fromFirestore(doc))
              .where(
                (req) =>
                    req.rejectionReason !=
                    'Superseded by another approved request',
              )
              .toList(),
        );
  }

  /// Stream of license requests filtered by status
  Stream<List<LicenseRequest>> getRequestsByStatus(String status) {
    return _requestsRef
        .where('status', isEqualTo: status)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LicenseRequest.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream of pending requests (for badges and real-time updates)
  Stream<List<LicenseRequest>> getPendingRequests() {
    return getRequestsByStatus(RequestStatus.pending);
  }

  /// Get a single license request by ID
  Future<LicenseRequest?> getRequestById(String requestId) async {
    final doc = await _requestsRef.doc(requestId).get();
    if (!doc.exists) return null;
    return LicenseRequest.fromFirestore(doc);
  }

  /// Get all requests for a specific school
  Stream<List<LicenseRequest>> getRequestsForSchool(String schoolId) {
    return _requestsRef
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LicenseRequest.fromFirestore(doc))
              .toList(),
        );
  }

  /// Approve a license request (HARDENED)
  ///
  /// Validates inputs, checks current status (race condition guard),
  /// performs atomic batch write, and logs audit trail.
  /// Also updates any other pending requests for the same school to avoid duplicates.
  Future<void> approveRequest({
    required String requestId,
    required String schoolId,
    required List<String> approvedModules,
    required DateTime expiryDate,
    required String adminUid,
    String? notes,
  }) async {
    // Filter modules to only include valid ones
    final validModuleIds = EduXModules.allIds.toSet();
    final filteredModules = approvedModules
        .where((id) => validModuleIds.contains(id))
        .toList();

    // ── Validate inputs ──
    final validation = _security.validateLicenseGrant(
      schoolId: schoolId,
      modules: filteredModules,
      expiryDate: expiryDate,
      adminUid: adminUid,
    );
    if (!validation.isValid) {
      throw SecurityException(validation.error!);
    }

    // ── Race condition guard: re-read current status ──
    final currentDoc = await _requestsRef.doc(requestId).get();
    if (!currentDoc.exists) {
      throw SecurityException('Request not found');
    }
    final currentData = currentDoc.data()!;
    final currentStatus = currentData['status'] as String? ?? '';
    final schoolName = currentData['schoolName'] as String? ?? '';
    final packageType = currentData['packageType'] as String? ?? 'custom';

    // Allow approving from 'pending' status
    if (currentStatus != RequestStatus.pending) {
      final statusCheck = _security.validateRequestTransition(
        currentStatus,
        RequestStatus.approved,
      );
      if (!statusCheck.isValid) {
        throw SecurityException(statusCheck.error!);
      }
    }

    // ── Find and reject other pending requests for the same school ──
    final otherPendingRequests = await _requestsRef
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: RequestStatus.pending)
        .get();

    // ── Atomic batch write ──
    final batch = _firestore.batch();

    // Update this request status to approved
    batch.update(_requestsRef.doc(requestId), {
      'status': RequestStatus.approved,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'approvedModules': filteredModules,
      if (notes != null) 'notes': _security.sanitizeInput(notes),
    });

    // Reject other pending requests for the same school
    for (final doc in otherPendingRequests.docs) {
      if (doc.id != requestId) {
        batch.update(doc.reference, {
          'status': RequestStatus.rejected,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminUid,
          'rejectionReason': 'Superseded by another approved request',
        });
      }
    }

    // Compute integrity hash
    final integrityHash = _computeIntegrityHash(
      schoolId: schoolId,
      expiresAt: expiryDate,
      modules: filteredModules,
    );

    // Create or update license document
    batch.set(_licensesRef.doc(schoolId), {
      'schoolId': schoolId,
      'schoolName': schoolName,
      'packageType': packageType,
      'approvedModules': filteredModules,
      'grantedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryDate),
      'isActive': true,
      'grantedBy': adminUid,
      'lastCheckedAt': FieldValue.serverTimestamp(),
      'integrityHash': integrityHash,
    }, SetOptions(merge: true));

    await batch.commit();

    // ── Audit log (non-blocking) ──
    _writeAuditLog(
      schoolId: schoolId,
      action: AuditAction.approved,
      adminUid: adminUid,
      details: {
        'requestId': requestId,
        'modules': filteredModules,
        'expiresAt': expiryDate.toIso8601String(),
        'rejectedDuplicates': otherPendingRequests.docs.length - 1,
      },
    );
  }

  /// Reject a license request (HARDENED)
  Future<void> rejectRequest({
    required String requestId,
    required String adminUid,
    String? rejectionReason,
    String? notes,
  }) async {
    // ── Validate ──
    final validation = _security.validateRejection(
      requestId: requestId,
      adminUid: adminUid,
      rejectionReason: rejectionReason,
    );
    if (!validation.isValid) {
      throw SecurityException(validation.error!);
    }

    // ── Race condition guard ──
    final currentDoc = await _requestsRef.doc(requestId).get();
    if (!currentDoc.exists) {
      throw SecurityException('Request not found');
    }
    final currentStatus = currentDoc.data()!['status'] as String? ?? '';
    final statusCheck = _security.validateRequestTransition(
      currentStatus,
      RequestStatus.rejected,
    );
    if (!statusCheck.isValid) {
      throw SecurityException(statusCheck.error!);
    }

    final schoolId = currentDoc.data()!['schoolId'] as String? ?? '';

    await _requestsRef.doc(requestId).update({
      'status': RequestStatus.rejected,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      if (rejectionReason != null)
        'rejectionReason': _security.sanitizeInput(rejectionReason),
      if (notes != null) 'notes': _security.sanitizeInput(notes),
    });

    // ── Audit log ──
    if (schoolId.isNotEmpty) {
      _writeAuditLog(
        schoolId: schoolId,
        action: AuditAction.rejected,
        adminUid: adminUid,
        details: {
          'requestId': requestId,
          'reason': rejectionReason ?? 'No reason provided',
        },
      );
    }
  }

  /// Delete a license request (HARDENED)
  Future<void> deleteRequest(
    String requestId, {
    required String adminUid,
  }) async {
    final doc = await _requestsRef.doc(requestId).get();
    if (!doc.exists) return;

    final schoolId = doc.data()!['schoolId'] as String? ?? '';
    await _requestsRef.doc(requestId).delete();

    if (schoolId.isNotEmpty) {
      _writeAuditLog(
        schoolId: schoolId,
        action: AuditAction.requestDeleted,
        adminUid: adminUid,
        details: {'requestId': requestId},
      );
    }
  }

  // ============================================================
  // SCHOOLS — Read & query operations
  // ============================================================

  /// Stream of all registered schools
  Stream<List<School>> getAllSchools() {
    return _schoolsRef.snapshots().map((snapshot) {
      final schools = snapshot.docs
          .map((doc) => School.fromFirestore(doc))
          .toList();
      // Sort client-side because older docs may not have 'createdAt'
      schools.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return schools;
    });
  }

  /// Get a single school by ID
  Future<School?> getSchoolById(String schoolId) async {
    final doc = await _schoolsRef.doc(schoolId).get();
    if (!doc.exists) return null;
    return School.fromFirestore(doc);
  }

  /// Get total school count
  Future<int> getSchoolCount() async {
    final snapshot = await _schoolsRef.count().get();
    return snapshot.count ?? 0;
  }

  /// Get all schools as a one-time snapshot (for combining with license data)
  Future<List<School>> getAllSchoolsOnce() async {
    final snapshot = await _schoolsRef
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => School.fromFirestore(doc)).toList();
  }

  /// Search schools by name (case-insensitive prefix search)
  Stream<List<School>> searchSchools(String query) {
    if (query.isEmpty) return getAllSchools();

    final searchTerm = query.toLowerCase();
    return _schoolsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => School.fromFirestore(doc))
              .where(
                (school) =>
                    school.schoolName.toLowerCase().contains(searchTerm) ||
                    (school.city?.toLowerCase().contains(searchTerm) ??
                        false) ||
                    school.schoolId.toLowerCase().contains(searchTerm),
              )
              .toList(),
        );
  }

  // ============================================================
  // LICENSES — CRUD operations (HARDENED)
  // ============================================================

  /// Get license for a specific school
  Future<License?> getLicenseBySchoolId(String schoolId) async {
    final doc = await _licensesRef.doc(schoolId).get();
    if (!doc.exists) return null;
    return License.fromFirestore(doc);
  }

  /// Stream a school's license (for real-time updates on detail screen)
  Stream<License?> watchLicense(String schoolId) {
    return _licensesRef.doc(schoolId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return License.fromFirestore(doc);
    });
  }

  /// Grant a new license (HARDENED)
  Future<void> grantLicense({
    required String schoolId,
    required List<String> modules,
    required DateTime expiryDate,
    required String adminUid,
  }) async {
    // ── Validate ──
    final validation = _security.validateLicenseGrant(
      schoolId: schoolId,
      modules: modules,
      expiryDate: expiryDate,
      adminUid: adminUid,
    );
    if (!validation.isValid) {
      throw SecurityException(validation.error!);
    }

    final integrityHash = _computeIntegrityHash(
      schoolId: schoolId,
      expiresAt: expiryDate,
      modules: modules,
    );

    await _licensesRef.doc(schoolId).set({
      'schoolId': schoolId,
      'approvedModules': modules,
      'grantedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryDate),
      'isActive': true,
      'grantedBy': adminUid,
      'lastCheckedAt': FieldValue.serverTimestamp(),
      'integrityHash': integrityHash,
    });

    _writeAuditLog(
      schoolId: schoolId,
      action: AuditAction.licenseGranted,
      adminUid: adminUid,
      details: {'modules': modules, 'expiresAt': expiryDate.toIso8601String()},
    );
  }

  /// Update license modules (HARDENED)
  Future<void> updateLicenseModules({
    required String schoolId,
    required List<String> modules,
    required String adminUid,
  }) async {
    final moduleValidation = _security.validateModules(modules);
    if (!moduleValidation.isValid) {
      throw SecurityException(moduleValidation.error!);
    }

    // Get current license to rebuild hash
    final currentLicense = await getLicenseBySchoolId(schoolId);
    if (currentLicense == null) {
      throw SecurityException('No license found for school $schoolId');
    }

    final integrityHash = _computeIntegrityHash(
      schoolId: schoolId,
      expiresAt: currentLicense.expiresAt,
      modules: modules,
    );

    await _licensesRef.doc(schoolId).update({
      'approvedModules': modules,
      'lastCheckedAt': FieldValue.serverTimestamp(),
      'integrityHash': integrityHash,
    });

    _writeAuditLog(
      schoolId: schoolId,
      action: AuditAction.modulesUpdated,
      adminUid: adminUid,
      details: {'modules': modules},
    );
  }

  /// Extend a license expiry date (HARDENED)
  Future<void> extendLicense({
    required String schoolId,
    required DateTime newExpiryDate,
    required String adminUid,
  }) async {
    // Get current license to validate extension
    final currentLicense = await getLicenseBySchoolId(schoolId);
    if (currentLicense == null) {
      throw SecurityException('No license found for school $schoolId');
    }

    final validation = _security.validateLicenseExtension(
      schoolId: schoolId,
      newExpiryDate: newExpiryDate,
      currentExpiryDate: currentLicense.expiresAt,
    );
    if (!validation.isValid) {
      throw SecurityException(validation.error!);
    }

    final integrityHash = _computeIntegrityHash(
      schoolId: schoolId,
      expiresAt: newExpiryDate,
      modules: currentLicense.approvedModules,
    );

    await _licensesRef.doc(schoolId).update({
      'expiresAt': Timestamp.fromDate(newExpiryDate),
      'isActive': true,
      'lastCheckedAt': FieldValue.serverTimestamp(),
      'integrityHash': integrityHash,
    });

    _writeAuditLog(
      schoolId: schoolId,
      action: AuditAction.extended,
      adminUid: adminUid,
      details: {
        'oldExpiry': currentLicense.expiresAt.toIso8601String(),
        'newExpiry': newExpiryDate.toIso8601String(),
      },
    );
  }

  /// Revoke a license (HARDENED — prevents double-revoke)
  Future<void> revokeLicense(
    String schoolId, {
    required String adminUid,
  }) async {
    // Check current state
    final currentLicense = await getLicenseBySchoolId(schoolId);
    if (currentLicense == null) {
      throw SecurityException('No license found for school $schoolId');
    }
    if (!currentLicense.isActive) {
      throw SecurityException('License is already revoked');
    }

    await _licensesRef.doc(schoolId).update({
      'isActive': false,
      'lastCheckedAt': FieldValue.serverTimestamp(),
    });

    _writeAuditLog(
      schoolId: schoolId,
      action: AuditAction.revoked,
      adminUid: adminUid,
      details: {'previousExpiry': currentLicense.expiresAt.toIso8601String()},
    );
  }

  /// Delete a license entirely
  Future<void> deleteLicense(String schoolId) async {
    await _licensesRef.doc(schoolId).delete();
  }

  /// Stream of all active licenses
  Stream<List<License>> getActiveLicenses() {
    return _licensesRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => License.fromFirestore(doc)).toList(),
        );
  }

  // ============================================================
  // DASHBOARD STATS — Aggregated counts
  // ============================================================

  /// Stream of live dashboard statistics
  Stream<DashboardStats> getDashboardStats() {
    return _schoolsRef.snapshots().asyncMap((_) async {
      final results = await Future.wait([
        _schoolsRef.count().get(),
        _requestsRef
            .where('status', isEqualTo: RequestStatus.pending)
            .count()
            .get(),
        _licensesRef.where('isActive', isEqualTo: true).count().get(),
        _getExpiringSoonCount(),
      ]);

      return DashboardStats(
        totalSchools: (results[0] as AggregateQuerySnapshot).count ?? 0,
        pendingRequests: (results[1] as AggregateQuerySnapshot).count ?? 0,
        activeLicenses: (results[2] as AggregateQuerySnapshot).count ?? 0,
        expiringSoon: results[3] as int,
      );
    });
  }

  /// Get count of licenses expiring within the warning threshold
  Future<int> _getExpiringSoonCount() async {
    final warningDate = DateTime.now().add(
      Duration(days: AppConstants.expiryWarningDays),
    );

    final snapshot = await _licensesRef
        .where('isActive', isEqualTo: true)
        .where(
          'expiresAt',
          isLessThanOrEqualTo: Timestamp.fromDate(warningDate),
        )
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .get();

    return snapshot.docs.length;
  }

  /// Get a one-time snapshot of dashboard stats (for initial load)
  Future<DashboardStats> getDashboardStatsOnce() async {
    final results = await Future.wait([
      _schoolsRef.count().get(),
      _requestsRef
          .where('status', isEqualTo: RequestStatus.pending)
          .count()
          .get(),
      _licensesRef.where('isActive', isEqualTo: true).count().get(),
      _getExpiringSoonCount(),
    ]);

    return DashboardStats(
      totalSchools: (results[0] as AggregateQuerySnapshot).count ?? 0,
      pendingRequests: (results[1] as AggregateQuerySnapshot).count ?? 0,
      activeLicenses: (results[2] as AggregateQuerySnapshot).count ?? 0,
      expiringSoon: results[3] as int,
    );
  }
}

/// Exception thrown when security validation fails
class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
