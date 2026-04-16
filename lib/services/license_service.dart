/// License Service — License storage, Firestore REST API
///
/// Handles: license activation, module gating,
/// and sending license requests to Firestore (for NovaByte Hub to process).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/demo/demo_config.dart';

// ─────────────────────────────────────────────────────────────
//  Enums & Models
// ─────────────────────────────────────────────────────────────

/// Current app-wide license status.
enum AppLicenseStatus {
  /// A license has been approved — only approved modules are active.
  licensed,

  /// License has expired and no active license exists.
  expired,

  /// A license request has been submitted and is awaiting admin approval.
  pendingRequest,
}

/// Local representation of an approved license.
class LicenseData {
  final String schoolId;
  final String schoolName;
  final String packageType;
  final List<String> approvedModules;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final String integrityHash; // NEW: Added integrity hash

  LicenseData({
    required this.schoolId,
    required this.schoolName,
    required this.packageType,
    required this.approvedModules,
    required this.grantedAt,
    required this.expiresAt,
    required this.integrityHash,
  });

  bool isExpiredWithTime(DateTime currentTime) =>
      currentTime.isAfter(expiresAt);

  bool get isExpired => isExpiredWithTime(DateTime.now());

  int daysRemainingWithTime(DateTime currentTime) =>
      expiresAt.difference(currentTime).inDays;

  int get daysRemaining => daysRemainingWithTime(DateTime.now());

  int get hoursRemaining => expiresAt.difference(DateTime.now()).inHours;

  int get minutesRemaining => expiresAt.difference(DateTime.now()).inMinutes;

  bool hasModule(String moduleId) => approvedModules.contains(moduleId);

  bool get isValid {
    final computedHash = _computeIntegrityHash(
      schoolId: schoolId,
      expiresAt: expiresAt,
      modules: approvedModules,
    );
    return integrityHash == computedHash;
  }

  static String _computeIntegrityHash({
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

  Map<String, dynamic> toJson() => {
    'schoolId': schoolId,
    'schoolName': schoolName,
    'packageType': packageType,
    'approvedModules': approvedModules,
    'grantedAt': grantedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'integrityHash': integrityHash,
  };

  factory LicenseData.fromJson(Map<String, dynamic> json) => LicenseData(
    schoolId: json['schoolId'] as String,
    schoolName: json['schoolName'] as String,
    packageType: json['packageType'] as String,
    approvedModules: List<String>.from(json['approvedModules'] as List),
    grantedAt: DateTime.parse(json['grantedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    integrityHash:
        json['integrityHash'] as String? ??
        '', // Default for backward compatibility validation
  );

  /// Creates a LicenseData with a locally computed integrity hash.
  /// Use this when saving license data fetched from Firestore to ensure
  /// the hash always matches what `isValid` will compute locally.
  factory LicenseData.withComputedHash({
    required String schoolId,
    required String schoolName,
    required String packageType,
    required List<String> approvedModules,
    required DateTime grantedAt,
    required DateTime expiresAt,
  }) {
    final hash = _computeIntegrityHash(
      schoolId: schoolId,
      expiresAt: expiresAt,
      modules: approvedModules,
    );
    return LicenseData(
      schoolId: schoolId,
      schoolName: schoolName,
      packageType: packageType,
      approvedModules: approvedModules,
      grantedAt: grantedAt,
      expiresAt: expiresAt,
      integrityHash: hash,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  License Service
// ─────────────────────────────────────────────────────────────

class LicenseService {
  LicenseService._();

  static final LicenseService instance = LicenseService._();

  static const _firestoreBase =
      'https://firestore.googleapis.com/v1/projects/${AppConstants.firestoreProjectId}/databases/(default)/documents';

  // Security constants
  static const int _maxTimeDriftMinutes = 5;

  // Helper to get true time from NTP server
  DateTime? _cachedTrueTime;
  DateTime? _lastTrueTimeFetch;

  Future<DateTime> _getTrueTime() async {
    // Cache true time for a short period to avoid excessive NTP calls
    if (_cachedTrueTime != null &&
        _lastTrueTimeFetch != null &&
        DateTime.now().difference(_lastTrueTimeFetch!).inMinutes < 1) {
      return _cachedTrueTime!.add(
        DateTime.now().difference(_lastTrueTimeFetch!),
      );
    }

    try {
      final ntpTime = await NTP.now();
      _cachedTrueTime = ntpTime;
      _lastTrueTimeFetch = DateTime.now();
      return ntpTime;
    } catch (e) {
      debugPrint('NTP time sync failed: $e. Falling back to device time.');
      return DateTime.now();
    }
  }

  /// Detects if the device time has been tampered with by comparing it to NTP time.
  /// Returns true if tampering is detected, false otherwise.
  Future<bool> detectTimeTampering() async {
    final deviceTime = DateTime.now();
    final trueTime = await _getTrueTime();

    // If NTP sync failed, we can't reliably detect tampering.
    // For security, we might want to assume tampering or at least be cautious.
    // For now, if NTP fails, we can't detect tampering, so return false.
    // A more robust solution might involve persistent storage of last known good NTP time.
    if (_cachedTrueTime == null) {
      debugPrint(
        'WARNING: NTP time not available for tampering check. Cannot detect tampering.',
      );
      return false;
    }

    final difference = deviceTime.difference(trueTime).abs();
    if (difference.inMinutes > _maxTimeDriftMinutes) {
      debugPrint(
        'SECURITY ALERT: Device time drift detected! Device time: $deviceTime, NTP time: $trueTime, Difference: $difference',
      );
      return true;
    }
    return false;
  }

  // ── Legacy Trial (for migration) ──

  /// Records the first launch date if not already set.
  Future<void> recordInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(AppConstants.prefInstallDate)) {
      await prefs.setString(
        AppConstants.prefInstallDate,
        (await _getTrueTime()).toIso8601String(),
      );
    }
  }

  /// Returns the install / trial-start date, or null if never launched.
  Future<DateTime?> getInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(AppConstants.prefInstallDate);
    return str != null ? DateTime.parse(str) : null;
  }

  // ── License Data ──

  /// Persists approved license data locally.
  Future<void> saveLicenseData(LicenseData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefLicenseData,
      jsonEncode(data.toJson()),
    );
  }

  /// Reads the locally stored license (null if none) with integrity check.
  Future<LicenseData?> getLicenseData() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(AppConstants.prefLicenseData);
    if (str == null) return null;

    try {
      final licenseData = LicenseData.fromJson(
        jsonDecode(str) as Map<String, dynamic>,
      );

      // Verify integrity
      if (!licenseData.isValid) {
        debugPrint(
          'SECURITY: License tampering detected or invalid signature. Invalidating local license.',
        );
        await clearLicenseData();
        return null;
      }

      return licenseData;
    } catch (e) {
      debugPrint('Failed to parse license data: $e');
      return null;
    }
  }

  /// Removes the cached license.
  Future<void> clearLicenseData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefLicenseData);
  }

  // ── School ID ──

  /// Generates and stores a UUID School ID (called once during setup).
  Future<String> generateSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(AppConstants.prefSchoolId);
    if (existing != null) return existing;

    final id = const Uuid().v4().substring(0, 8).toUpperCase();
    final schoolId = 'EDX-$id';
    await prefs.setString(AppConstants.prefSchoolId, schoolId);
    return schoolId;
  }

  /// Returns the stored School ID.
  Future<String?> getSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefSchoolId);
  }

  /// Stores the school name locally (used for Firestore registration).
  Future<void> saveSchoolName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefSchoolName, name);
  }

  /// Returns the stored school name.
  Future<String?> getSchoolName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefSchoolName);
  }

  // ── Composite Status ──

  /// Determines the overall app license status used by splash / shell.
  Future<AppLicenseStatus> getAppStatus() async {
    if (DemoConfig.isDemo) return AppLicenseStatus.licensed;

    // Get true time for expiry checks
    final trueTime = await _getTrueTime();

    // Check time tampering
    if (await detectTimeTampering()) {
      return AppLicenseStatus.expired; // Lock them out if tampered
    }

    // 1. Check for an active license first
    final license = await getLicenseData();
    if (license != null && !license.isExpiredWithTime(trueTime)) {
      return AppLicenseStatus.licensed;
    }

    // 2. Check for a pending request
    final prefs = await SharedPreferences.getInstance();
    final reqStatus = prefs.getString(AppConstants.prefRequestStatus);
    if (reqStatus == 'pending') {
      return AppLicenseStatus.pendingRequest;
    }

    // 3. Default to expired
    return AppLicenseStatus.expired;
  }

  /// Whether a specific module is currently accessible.
  Future<bool> isModuleAccessible(String moduleId) async {
    if (DemoConfig.isDemo) return true;

    final status = await getAppStatus();

    // With valid license, only approved modules are accessible
    if (status == AppLicenseStatus.licensed) {
      final license = await getLicenseData();
      return license?.hasModule(moduleId) ?? false;
    }

    // Pending requests get full access (grace period while waiting)
    if (status == AppLicenseStatus.pendingRequest) {
      return true;
    }

    return false;
  }

  // ── Firestore REST API ──

  /// Gets an authentication token using Firebase Identity Toolkit (Anonymous Auth)
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we have a valid cached token
    final cachedToken = prefs.getString('edux_auth_token');
    final tokenExpiryStr = prefs.getString('edux_auth_token_expiry');

    if (cachedToken != null && tokenExpiryStr != null) {
      final expiry = DateTime.parse(tokenExpiryStr);
      // Give 5 minutes buffer before actual expiry
      if (DateTime.now().isBefore(
        expiry.subtract(const Duration(minutes: 5)),
      )) {
        return cachedToken;
      }
    }

    try {
      // Authenticate anonymously via REST API
      final url =
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${AppConstants.firestoreApiKey}';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'returnSecureToken': true}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final idToken = data['idToken'] as String;
        final expiresIn = int.parse(data['expiresIn'] as String);

        // Cache token
        await prefs.setString('edux_auth_token', idToken);
        await prefs.setString(
          'edux_auth_token_expiry',
          DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
        );

        return idToken;
      } else {
        debugPrint('Failed to get auth token: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Auth token error: $e');
      return null;
    }
  }

  /// Appends auth token to headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await _getAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Registers the school in Firestore (called once during setup).
  Future<void> registerSchoolInFirestore({
    required String schoolId,
    required String schoolName,
    required String city,
    required String email,
    required String phone,
  }) async {
    final url =
        '$_firestoreBase/schools/$schoolId?key=${AppConstants.firestoreApiKey}';

    final body = {
      'fields': {
        'schoolId': {'stringValue': schoolId},
        'schoolName': {'stringValue': schoolName},
        'city': {'stringValue': city},
        'email': {'stringValue': email},
        'phone': {'stringValue': phone},
        'registeredAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
        'isActive': {'booleanValue': true},
        'deviceFingerprint': {'stringValue': await _getDeviceFingerprint()},
      },
    };

    debugPrint('Registering school in Firestore: $schoolId');
    debugPrint('URL: $url');

    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    debugPrint('Firestore response status: ${response.statusCode}');
    debugPrint('Firestore response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to register school: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Checks if there's already a pending request for this school
  Future<bool> hasPendingRequest() async {
    final schoolId = await getSchoolId();
    if (schoolId == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final localStatus = prefs.getString(AppConstants.prefRequestStatus);
    if (localStatus == 'pending') return true;

    // Also check Firestore
    try {
      final url =
          '$_firestoreBase:runQuery?key=${AppConstants.firestoreApiKey}';

      final query = {
        'structuredQuery': {
          'from': [
            {'collectionId': 'license_requests'},
          ],
          'where': {
            'compositeFilter': {
              'op': 'AND',
              'filters': [
                {
                  'fieldFilter': {
                    'field': {'fieldPath': 'schoolId'},
                    'op': 'EQUAL',
                    'value': {'stringValue': schoolId},
                  },
                },
                {
                  'fieldFilter': {
                    'field': {'fieldPath': 'status'},
                    'op': 'EQUAL',
                    'value': {'stringValue': 'pending'},
                  },
                },
              ],
            },
          },
          'limit': 1,
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: await _getAuthHeaders(),
        body: jsonEncode(query),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results =
            jsonDecode(response.body) as List<dynamic>;
        if (results.isNotEmpty) {
          final firstResult = results.first as Map<String, dynamic>;
          if (firstResult.containsKey('document')) {
            // Update local status to match
            await prefs.setString(AppConstants.prefRequestStatus, 'pending');
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking pending request: $e');
    }

    return false;
  }

  /// Submits a license request to Firestore.
  Future<void> submitLicenseRequest({
    required String schoolId,
    required String schoolName,
    required String packageType,
    required List<String> requestedModules,
    String? contactEmail,
    String? contactPhone,
    String? notes,
  }) async {
    // First check if there's already a pending request
    final alreadyPending = await hasPendingRequest();
    if (alreadyPending) {
      throw Exception(
        'You already have a pending license request. Please wait for approval.',
      );
    }

    final url =
        '$_firestoreBase/license_requests?key=${AppConstants.firestoreApiKey}';

    final moduleValues = requestedModules
        .map((m) => {'stringValue': m})
        .toList();

    final fields = <String, dynamic>{
      'schoolId': {'stringValue': schoolId},
      'schoolName': {'stringValue': schoolName},
      'packageType': {'stringValue': packageType},
      'requestedModules': {
        'arrayValue': {'values': moduleValues},
      },
      'status': {'stringValue': 'pending'},
      'requestedAt': {
        'timestampValue': DateTime.now().toUtc().toIso8601String(),
      },
      'deviceFingerprint': {'stringValue': await _getDeviceFingerprint()},
    };

    if (contactEmail != null && contactEmail.isNotEmpty) {
      fields['contactEmail'] = {'stringValue': contactEmail};
    }
    if (contactPhone != null && contactPhone.isNotEmpty) {
      fields['contactPhone'] = {'stringValue': contactPhone};
    }
    if (notes != null && notes.isNotEmpty) {
      fields['notes'] = {'stringValue': notes};
    }

    debugPrint('Submitting license request for: $schoolId');
    debugPrint('URL: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'fields': fields}),
    );

    debugPrint('License request response status: ${response.statusCode}');
    debugPrint('License request response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to submit request: ${response.statusCode} - ${response.body}',
      );
    }

    // Mark status locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefRequestStatus, 'pending');
  }

  /// Checks the latest license status from Firestore and updates local state.
  /// Returns `true` if a new license was found and saved.
  Future<bool> refreshLicenseFromFirestore() async {
    final schoolId = await getSchoolId();
    if (schoolId == null) return false;

    // Query Firestore for an active license for this school
    final url = '$_firestoreBase:runQuery?key=${AppConstants.firestoreApiKey}';

    final query = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'licenses'},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'schoolId'},
            'op': 'EQUAL',
            'value': {'stringValue': schoolId},
          },
        },
        'limit': 1,
      },
    };

    final response = await http.post(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
      body: jsonEncode(query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to check license: ${response.body}');
    }

    final List<dynamic> results = jsonDecode(response.body) as List<dynamic>;

    // Firestore returns [{"readTime": "..."} ] when no docs match
    if (results.isEmpty) return false;

    final firstResult = results.first as Map<String, dynamic>;
    if (!firstResult.containsKey('document')) return false;

    final doc = firstResult['document'] as Map<String, dynamic>;
    final fields = doc['fields'] as Map<String, dynamic>;

    // Check if license is active
    final isActive = fields['isActive']?['booleanValue'] == true;
    if (!isActive) return false;

    // Parse approved modules
    final modulesArray =
        fields['approvedModules']?['arrayValue']?['values'] as List<dynamic>?;
    final approvedModules =
        modulesArray
            ?.map((v) => (v as Map<String, dynamic>)['stringValue'] as String)
            .toList() ??
        [];

    // Parse dates
    final grantedAtStr =
        fields['grantedAt']?['timestampValue'] as String? ??
        DateTime.now().toIso8601String();
    final expiresAtStr =
        fields['expiresAt']?['timestampValue'] as String? ??
        DateTime.now().add(const Duration(days: 365)).toIso8601String();

    // Recompute integrity hash locally to ensure consistency.
    // The Firestore hash may have been computed with a different DateTime
    // format (local vs UTC), causing validation failures on read-back.
    final license = LicenseData.withComputedHash(
      schoolId: schoolId,
      schoolName: fields['schoolName']?['stringValue'] as String? ?? '',
      packageType: fields['packageType']?['stringValue'] as String? ?? 'custom',
      approvedModules: approvedModules,
      grantedAt: DateTime.parse(grantedAtStr),
      expiresAt: DateTime.parse(expiresAtStr),
    );

    await saveLicenseData(license);

    // Update request status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefRequestStatus, 'approved');

    return true;
  }

  /// Checks the status of the most recent license request for this school.
  Future<String?> checkRequestStatus() async {
    final schoolId = await getSchoolId();
    if (schoolId == null) return null;

    final url = '$_firestoreBase:runQuery?key=${AppConstants.firestoreApiKey}';

    final query = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'license_requests'},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'schoolId'},
            'op': 'EQUAL',
            'value': {'stringValue': schoolId},
          },
        },
        'orderBy': [
          {
            'field': {'fieldPath': 'requestedAt'},
            'direction': 'DESCENDING',
          },
        ],
        'limit': 1,
      },
    };

    final response = await http.post(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
      body: jsonEncode(query),
    );

    if (response.statusCode != 200) return null;

    final List<dynamic> results = jsonDecode(response.body) as List<dynamic>;
    if (results.isEmpty) return null;

    final firstResult = results.first as Map<String, dynamic>;
    if (!firstResult.containsKey('document')) return null;

    final doc = firstResult['document'] as Map<String, dynamic>;
    final fields = doc['fields'] as Map<String, dynamic>;

    final status = fields['status']?['stringValue'] as String?;

    // Persist locally
    if (status != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefRequestStatus, status);
    }

    return status;
  }

  // ── Security Methods ──

  /// Get device fingerprint for integrity checks
  Future<String> _getDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    var fingerprint = prefs.getString('edux_device_fingerprint_v2');

    if (fingerprint == null) {
      // Generate new hardware-bound fingerprint
      final deviceInfo = DeviceInfoPlugin();
      String hardwareId = '';

      try {
        if (kIsWeb) {
          final webBrowserInfo = await deviceInfo.webBrowserInfo;
          hardwareId = webBrowserInfo.userAgent ?? 'unknown-web-agent';
        } else {
          switch (defaultTargetPlatform) {
            case TargetPlatform.android:
              final androidInfo = await deviceInfo.androidInfo;
              hardwareId = androidInfo.id; // Unique hardware ID
              break;
            case TargetPlatform.iOS:
              final iosInfo = await deviceInfo.iosInfo;
              hardwareId = iosInfo.identifierForVendor ?? const Uuid().v4();
              break;
            case TargetPlatform.macOS:
              final macOsInfo = await deviceInfo.macOsInfo;
              hardwareId = macOsInfo.systemGUID ?? const Uuid().v4();
              break;
            case TargetPlatform.windows:
              final windowsInfo = await deviceInfo.windowsInfo;
              hardwareId = windowsInfo.deviceId;
              break;
            case TargetPlatform.linux:
              final linuxInfo = await deviceInfo.linuxInfo;
              hardwareId = linuxInfo.machineId ?? const Uuid().v4();
              break;
            default:
              hardwareId = const Uuid().v4();
          }
        }
      } catch (e) {
        // Fallback to UUID if device info fails
        hardwareId = const Uuid().v4();
      }

      fingerprint = sha256
          .convert(utf8.encode(hardwareId))
          .toString()
          .substring(0, 32);

      await prefs.setString('edux_device_fingerprint_v2', fingerprint);
    }

    return fingerprint;
  }
}
