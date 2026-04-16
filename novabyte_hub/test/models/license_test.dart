/// Unit tests for License model
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:novabyte_hub/models/license.dart';

void main() {
  group('License', () {
    late License activeLicense;
    late License expiredLicense;
    late License expiringSoonLicense;
    late License revokedLicense;

    setUp(() {
      activeLicense = License(
        schoolId: 'school_001',
        approvedModules: ['students', 'guardians', 'academics'],
        grantedAt: DateTime.now().subtract(const Duration(days: 30)),
        expiresAt: DateTime.now().add(const Duration(days: 335)),
        isActive: true,
        grantedBy: 'admin_uid_1',
      );

      expiredLicense = License(
        schoolId: 'school_002',
        approvedModules: ['students'],
        grantedAt: DateTime.now().subtract(const Duration(days: 400)),
        expiresAt: DateTime.now().subtract(const Duration(days: 35)),
        isActive: true,
        grantedBy: 'admin_uid_1',
      );

      expiringSoonLicense = License(
        schoolId: 'school_003',
        approvedModules: ['students', 'fees'],
        grantedAt: DateTime.now().subtract(const Duration(days: 350)),
        expiresAt: DateTime.now().add(const Duration(days: 15)),
        isActive: true,
        grantedBy: 'admin_uid_1',
      );

      revokedLicense = License(
        schoolId: 'school_004',
        approvedModules: ['students'],
        grantedAt: DateTime.now().subtract(const Duration(days: 30)),
        expiresAt: DateTime.now().add(const Duration(days: 335)),
        isActive: false,
        grantedBy: 'admin_uid_1',
      );
    });

    group('isExpired', () {
      test('returns false for non-expired license', () {
        expect(activeLicense.isExpired, isFalse);
      });

      test('returns true for expired license', () {
        expect(expiredLicense.isExpired, isTrue);
      });
    });

    group('isValid', () {
      test('returns true for active and non-expired license', () {
        expect(activeLicense.isValid, isTrue);
      });

      test('returns false for expired license even if active flag is true', () {
        expect(expiredLicense.isValid, isFalse);
      });

      test('returns false for revoked license even if not expired', () {
        expect(revokedLicense.isValid, isFalse);
      });
    });

    group('daysRemaining', () {
      test('returns positive days for non-expired license', () {
        expect(activeLicense.daysRemaining, greaterThan(300));
      });

      test('returns 0 for expired license', () {
        expect(expiredLicense.daysRemaining, equals(0));
      });

      test('returns correct days for expiring soon license', () {
        expect(expiringSoonLicense.daysRemaining, lessThanOrEqualTo(15));
        expect(expiringSoonLicense.daysRemaining, greaterThanOrEqualTo(14));
      });
    });

    group('isExpiringSoon', () {
      test('returns false for license far from expiry', () {
        expect(activeLicense.isExpiringSoon, isFalse);
      });

      test('returns true for license within 30 days of expiry', () {
        expect(expiringSoonLicense.isExpiringSoon, isTrue);
      });

      test('returns false for expired license', () {
        expect(expiredLicense.isExpiringSoon, isFalse);
      });

      test('returns false for revoked license', () {
        expect(revokedLicense.isExpiringSoon, isFalse);
      });
    });

    group('expiryProgress', () {
      test('returns value between 0 and 1 for active license', () {
        expect(activeLicense.expiryProgress, greaterThanOrEqualTo(0.0));
        expect(activeLicense.expiryProgress, lessThanOrEqualTo(1.0));
      });

      test('returns 1.0 for fully expired license', () {
        expect(expiredLicense.expiryProgress, equals(1.0));
      });

      test('clamps to 1.0 for zero-duration license', () {
        final zeroDuration = License(
          schoolId: 'zero',
          approvedModules: ['students'],
          grantedAt: DateTime.now(),
          expiresAt: DateTime.now(),
          isActive: true,
          grantedBy: 'admin',
        );
        expect(zeroDuration.expiryProgress, equals(1.0));
      });
    });

    group('toFirestore / fromMap roundtrip', () {
      test('serializes and preserves all fields', () {
        final map = activeLicense.toFirestore();
        expect(map['schoolId'], equals('school_001'));
        expect(
          map['approvedModules'],
          equals(['students', 'guardians', 'academics']),
        );
        expect(map['isActive'], isTrue);
        expect(map['grantedBy'], equals('admin_uid_1'));
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final copy = activeLicense.copyWith(
          isActive: false,
          approvedModules: ['students', 'fees'],
        );
        expect(copy.isActive, isFalse);
        expect(copy.approvedModules, equals(['students', 'fees']));
        expect(copy.schoolId, equals(activeLicense.schoolId));
        expect(copy.grantedBy, equals(activeLicense.grantedBy));
      });

      test('preserves original when no changes', () {
        final copy = activeLicense.copyWith();
        expect(copy.schoolId, equals(activeLicense.schoolId));
        expect(copy.approvedModules, equals(activeLicense.approvedModules));
        expect(copy.isActive, equals(activeLicense.isActive));
      });
    });

    group('equality', () {
      test('two licenses with same schoolId are equal', () {
        final copy = activeLicense.copyWith(isActive: false);
        expect(copy, equals(activeLicense));
      });

      test('two licenses with different schoolId are not equal', () {
        expect(activeLicense, isNot(equals(expiredLicense)));
      });
    });

    group('toString', () {
      test('contains relevant info', () {
        final str = activeLicense.toString();
        expect(str, contains('school_001'));
        expect(str, contains('3')); // module count
      });
    });
  });
}
