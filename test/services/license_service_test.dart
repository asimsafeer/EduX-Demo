import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edux/services/license_service.dart';

void main() {
  group('LicenseData Tests', () {
    test('isValid returns true for valid LicenseData', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 365));
      final modules = ['attendance_tracking', 'student_management'];

      // Calculate valid hash
      final sortedModules = List<String>.from(modules)..sort();
      final data =
          'test-school-id|${expiresAt.toIso8601String()}|${sortedModules.join(', ')}|EDX_LICENSE_SECRET_V1';
      final validHash = sha256
          .convert(utf8.encode(data))
          .toString()
          .substring(0, 32);

      final licenseData = LicenseData(
        schoolId: 'test-school-id',
        schoolName: 'Test School',
        packageType: 'standard',
        approvedModules: modules,
        grantedAt: now,
        expiresAt: expiresAt,
        integrityHash: validHash,
      );

      expect(licenseData.isValid, true);
    });

    test('isValid returns false for tampered LicenseData', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 365));
      final modules = ['attendance_tracking', 'student_management'];

      final licenseData = LicenseData(
        schoolId: 'test-school-id',
        schoolName: 'Test School',
        packageType: 'standard',
        approvedModules: modules,
        grantedAt: now,
        expiresAt: expiresAt,
        integrityHash: 'invalid-hash-1234',
      );

      expect(licenseData.isValid, false);
    });
  });
}
