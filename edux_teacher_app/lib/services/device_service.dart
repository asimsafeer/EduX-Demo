/// EduX Teacher App - Device Service
library;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../database/app_database.dart';

/// Service for device-specific functionality
class DeviceService {
  final AppDatabase _db;
  final _uuid = const Uuid();
  final _localAuth = LocalAuthentication();

  DeviceService(this._db);

  // ===========================================================================
  // DEVICE ID
  // ===========================================================================

  /// Get or create device ID
  Future<String> getDeviceId() async {
    var deviceId = await _db.getConfig(ConfigKeys.deviceId);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await _db.setConfig(ConfigKeys.deviceId, deviceId);
    }
    return deviceId;
  }

  // ===========================================================================
  // DEVICE INFO
  // ===========================================================================

  /// Get device name (for display in main system)
  Future<String> getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      }
    } catch (e) {
      // Fall through to default
    }

    return 'Unknown Device';
  }

  /// Get detailed device info
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemVersion': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      // Fall through to default
    }

    return {'platform': 'unknown'};
  }

  // ===========================================================================
  // AUTHENTICATION
  // ===========================================================================

  /// Check if authenticated
  Future<bool> isAuthenticated() async {
    final token = await _db.getConfig(ConfigKeys.authToken);
    return token != null && token.isNotEmpty;
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isAvailable = await _localAuth.isDeviceSupported();
      return canCheck && isAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String localizedReason = 'Please authenticate to access the app',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with biometrics only (no device credentials)
  Future<bool> authenticateWithBiometricsOnly() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please verify your identity',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: false,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Stop authentication
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // BIOMETRIC SETTINGS
  // ===========================================================================

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _db.getConfig(ConfigKeys.biometricEnabled);
    return value == 'true';
  }

  /// Set biometric enabled
  Future<void> setBiometricEnabled(bool enabled) async {
    await _db.setConfig(ConfigKeys.biometricEnabled, enabled.toString());
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  /// Logout and clear all data
  Future<void> logout() async {
    await _db.clearAllData();
  }

  /// Clear only auth data (keep cache)
  Future<void> clearAuth() async {
    await _db.deleteConfig(ConfigKeys.authToken);
    await _db.deleteConfig(ConfigKeys.teacherId);
    await _db.deleteConfig(ConfigKeys.teacherName);
    await _db.deleteConfig(ConfigKeys.teacherEmail);
    await _db.deleteConfig(ConfigKeys.teacherPhoto);
  }

  // ===========================================================================
  // STORAGE INFO
  // ===========================================================================

  /// Get storage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = directory.statSync();

      return {
        'path': directory.path,
        'modified': stat.modified.toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
