/// Unit tests for SecurityService
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:novabyte_hub/services/security_service.dart';

void main() {
  late SecurityService service;

  setUp(() {
    service = const SecurityService();
  });

  group('SecurityService', () {
    // ════════════════════════════════════════════════════════════
    // INPUT SANITIZATION
    // ════════════════════════════════════════════════════════════

    group('sanitizeInput', () {
      test('trims whitespace', () {
        expect(service.sanitizeInput('  hello  '), equals('hello'));
      });

      test('removes control characters', () {
        expect(service.sanitizeInput('hello\x00world'), equals('helloworld'));
        expect(service.sanitizeInput('test\x1F'), equals('test'));
      });

      test('collapses multiple spaces', () {
        expect(service.sanitizeInput('hello  world'), equals('hello world'));
      });

      test('handles empty string', () {
        expect(service.sanitizeInput(''), equals(''));
      });

      test('handles normal string', () {
        expect(service.sanitizeInput('Hello World'), equals('Hello World'));
      });
    });

    group('sanitizeSchoolId', () {
      test('allows alphanumeric characters', () {
        expect(service.sanitizeSchoolId('SCH001'), equals('SCH001'));
      });

      test('allows hyphens and underscores', () {
        expect(service.sanitizeSchoolId('SCH-001_A'), equals('SCH-001_A'));
      });

      test('removes special characters', () {
        expect(service.sanitizeSchoolId('SCH@001!'), equals('SCH001'));
      });

      test('trims whitespace', () {
        expect(service.sanitizeSchoolId('  SCH001  '), equals('SCH001'));
      });

      test('removes spaces within ID', () {
        expect(service.sanitizeSchoolId('SCH 001'), equals('SCH001'));
      });
    });

    // ════════════════════════════════════════════════════════════
    // MODULE VALIDATION
    // ════════════════════════════════════════════════════════════

    group('validateModules', () {
      test('accepts valid module list when it contains only valid modules', () {
        final result = service.validateModules([
          'student_management',
          'guardian_management',
          'fee_management',
        ]);
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test('rejects empty module list', () {
        final result = service.validateModules([]);
        expect(result.isValid, isFalse);
        expect(result.error, contains('At least one module'));
      });

      test('rejects if all module IDs are unknown', () {
        final result = service.validateModules([
          'nonexistent_module',
        ]);
        expect(result.isValid, isFalse);
        expect(result.error, contains('No valid modules'));
      });

      test('rejects duplicate module IDs', () {
        final result = service.validateModules([
          'student_management',
          'student_management',
          'fee_management',
        ]);
        expect(result.isValid, isFalse);
        expect(result.error, contains('Duplicate'));
      });

      test('accepts all valid modules at once', () {
        final result = service.validateModules([
          'student_management',
          'guardian_management',
          'staff_management',
          'academic_management',
          'attendance_tracking',
          'exam_management',
          'fee_management',
          'expense_tracking',
          'canteen_management',
          'reporting',
          'teacher_app'
        ]);
        expect(result.isValid, isTrue);
      });

      test('accepts single module', () {
        final result = service.validateModules(['student_management']);
        expect(result.isValid, isTrue);
      });
    });

    // ════════════════════════════════════════════════════════════
    // EXPIRY DATE VALIDATION
    // ════════════════════════════════════════════════════════════

    group('validateExpiryDate', () {
      test('accepts future date', () {
        final future = DateTime.now().add(const Duration(days: 365));
        final result = service.validateExpiryDate(future);
        expect(result.isValid, isTrue);
      });

      test('rejects past date', () {
        final past = DateTime.now().subtract(const Duration(days: 1));
        final result = service.validateExpiryDate(past);
        expect(result.isValid, isFalse);
        expect(result.error, contains('future'));
      });

      test('rejects date more than 10 years out', () {
        final farFuture = DateTime.now().add(const Duration(days: 3700));
        final result = service.validateExpiryDate(farFuture);
        expect(result.isValid, isFalse);
        expect(result.error, contains('10 years'));
      });

      test('accepts date exactly 10 years out', () {
        final tenYears = DateTime.now().add(const Duration(days: 3649));
        final result = service.validateExpiryDate(tenYears);
        expect(result.isValid, isTrue);
      });

      test('accepts date 1 day from now', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final result = service.validateExpiryDate(tomorrow);
        expect(result.isValid, isTrue);
      });
    });

    // ════════════════════════════════════════════════════════════
    // STATUS TRANSITION VALIDATION (State Machine)
    // ════════════════════════════════════════════════════════════

    group('validateRequestTransition', () {
      test('allows pending → approved', () {
        final result = service.validateRequestTransition('pending', 'approved');
        expect(result.isValid, isTrue);
      });

      test('allows pending → rejected', () {
        final result = service.validateRequestTransition('pending', 'rejected');
        expect(result.isValid, isTrue);
      });

      test('rejects approved → pending', () {
        final result = service.validateRequestTransition('approved', 'pending');
        expect(result.isValid, isFalse);
        expect(result.error, contains('finalized'));
      });

      test('rejects approved → rejected', () {
        final result = service.validateRequestTransition(
          'approved',
          'rejected',
        );
        expect(result.isValid, isFalse);
      });

      test('rejects rejected → approved', () {
        final result = service.validateRequestTransition(
          'rejected',
          'approved',
        );
        expect(result.isValid, isFalse);
      });

      test('rejects rejected → pending', () {
        final result = service.validateRequestTransition('rejected', 'pending');
        expect(result.isValid, isFalse);
      });

      test('rejects same status transition', () {
        final result = service.validateRequestTransition('pending', 'pending');
        expect(result.isValid, isFalse);
        expect(result.error, contains('already'));
      });

      test('rejects unknown status', () {
        final result = service.validateRequestTransition('unknown', 'approved');
        expect(result.isValid, isFalse);
      });
    });

    // ════════════════════════════════════════════════════════════
    // COMPOUND VALIDATIONS
    // ════════════════════════════════════════════════════════════

    group('validateLicenseGrant', () {
      test('accepts valid grant parameters', () {
        final result = service.validateLicenseGrant(
          schoolId: 'school_001',
          modules: ['student_management', 'fee_management'],
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          adminUid: 'admin_uid_1',
        );
        expect(result.isValid, isTrue);
      });

      test('rejects empty school ID', () {
        final result = service.validateLicenseGrant(
          schoolId: '',
          modules: ['student_management'],
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          adminUid: 'admin_uid',
        );
        expect(result.isValid, isFalse);
        expect(result.error, contains('School ID'));
      });

      test('rejects empty admin UID', () {
        final result = service.validateLicenseGrant(
          schoolId: 'school_001',
          modules: ['student_management'],
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          adminUid: '',
        );
        expect(result.isValid, isFalse);
        expect(result.error, contains('Admin UID'));
      });

      test('rejects if all modules are invalid', () {
        final result = service.validateLicenseGrant(
          schoolId: 'school_001',
          modules: ['invalid_module'],
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          adminUid: 'admin_uid',
        );
        expect(result.isValid, isFalse);
        expect(result.error, contains('No valid modules'));
      });

      test('rejects past expiry date', () {
        final result = service.validateLicenseGrant(
          schoolId: 'school_001',
          modules: ['student_management'],
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
          adminUid: 'admin_uid',
        );
        expect(result.isValid, isFalse);
        expect(result.error, contains('future'));
      });

      test('rejects whitespace-only school ID', () {
        final result = service.validateLicenseGrant(
          schoolId: '   ',
          modules: ['student_management'],
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          adminUid: 'admin_uid',
        );
        expect(result.isValid, isFalse);
      });
    });

    group('validateRejection', () {
      test('accepts valid rejection', () {
        final result = service.validateRejection(
          requestId: 'req_001',
          adminUid: 'admin_uid',
          rejectionReason: 'Payment not received',
        );
        expect(result.isValid, isTrue);
      });

      test('accepts rejection without reason', () {
        final result = service.validateRejection(
          requestId: 'req_001',
          adminUid: 'admin_uid',
        );
        expect(result.isValid, isTrue);
      });

      test('rejects empty request ID', () {
        final result = service.validateRejection(
          requestId: '',
          adminUid: 'admin_uid',
        );
        expect(result.isValid, isFalse);
        expect(result.error, contains('Request ID'));
      });

      test('rejects empty admin UID', () {
        final result = service.validateRejection(
          requestId: 'req_001',
          adminUid: '',
        );
        expect(result.isValid, isFalse);
        expect(result.error, contains('Admin UID'));
      });

      test('rejects too-short rejection reason', () {
        final result = service.validateRejection(
          requestId: 'req_001',
          adminUid: 'admin_uid',
          rejectionReason: 'No',
        );
        expect(result.isValid, isFalse);
        expect(result.error, contains('at least 3'));
      });
    });

    group('validateLicenseExtension', () {
      test('accepts valid extension', () {
        final currentExpiry = DateTime.now().add(const Duration(days: 30));
        final newExpiry = DateTime.now().add(const Duration(days: 365));
        final result = service.validateLicenseExtension(
          schoolId: 'school_001',
          newExpiryDate: newExpiry,
          currentExpiryDate: currentExpiry,
        );
        expect(result.isValid, isTrue);
      });

      test('rejects new expiry before current expiry', () {
        final currentExpiry = DateTime.now().add(const Duration(days: 365));
        final newExpiry = DateTime.now().add(const Duration(days: 30));
        final result = service.validateLicenseExtension(
          schoolId: 'school_001',
          newExpiryDate: newExpiry,
          currentExpiryDate: currentExpiry,
        );
        expect(result.isValid, isFalse);
        expect(result.error, contains('after the current'));
      });

      test('rejects empty school ID', () {
        final result = service.validateLicenseExtension(
          schoolId: '',
          newExpiryDate: DateTime.now().add(const Duration(days: 365)),
          currentExpiryDate: DateTime.now().add(const Duration(days: 30)),
        );
        expect(result.isValid, isFalse);
      });
    });

    // ════════════════════════════════════════════════════════════
    // ValidationResult
    // ════════════════════════════════════════════════════════════

    group('ValidationResult', () {
      test('success result is valid with no error', () {
        const result = ValidationResult.success();
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
        expect(result.toString(), equals('Valid'));
      });

      test('failure result is invalid with error message', () {
        const result = ValidationResult.failure('Something went wrong');
        expect(result.isValid, isFalse);
        expect(result.error, equals('Something went wrong'));
        expect(result.toString(), contains('Something went wrong'));
      });
    });
  });
}
