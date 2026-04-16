/// Unit tests for LicenseRequest model
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:novabyte_hub/models/license_request.dart';

void main() {
  group('LicenseRequest', () {
    late LicenseRequest pendingRequest;
    late LicenseRequest approvedRequest;
    late LicenseRequest rejectedRequest;

    setUp(() {
      pendingRequest = LicenseRequest(
        id: 'req_001',
        schoolId: 'school_001',
        schoolName: 'Test School',
        requestedModules: ['students', 'guardians', 'academics'],
        packageType: 'standard',
        status: 'pending',
        requestedAt: DateTime(2025, 1, 15),
      );

      approvedRequest = LicenseRequest(
        id: 'req_002',
        schoolId: 'school_002',
        schoolName: 'Approved School',
        requestedModules: ['students', 'fees'],
        packageType: 'basic',
        status: 'approved',
        requestedAt: DateTime(2025, 1, 10),
        reviewedAt: DateTime(2025, 1, 11),
        reviewedBy: 'admin_uid',
      );

      rejectedRequest = LicenseRequest(
        id: 'req_003',
        schoolId: 'school_003',
        schoolName: 'Rejected School',
        requestedModules: ['students'],
        packageType: 'premium',
        status: 'rejected',
        requestedAt: DateTime(2025, 1, 5),
        reviewedAt: DateTime(2025, 1, 6),
        reviewedBy: 'admin_uid',
        rejectionReason: 'Payment not received',
        notes: 'Contact school admin',
      );
    });

    group('status checks', () {
      test('isPending returns true for pending status', () {
        expect(pendingRequest.isPending, isTrue);
        expect(pendingRequest.isApproved, isFalse);
        expect(pendingRequest.isRejected, isFalse);
      });

      test('isApproved returns true for approved status', () {
        expect(approvedRequest.isPending, isFalse);
        expect(approvedRequest.isApproved, isTrue);
        expect(approvedRequest.isRejected, isFalse);
      });

      test('isRejected returns true for rejected status', () {
        expect(rejectedRequest.isPending, isFalse);
        expect(rejectedRequest.isApproved, isFalse);
        expect(rejectedRequest.isRejected, isTrue);
      });
    });

    group('construction', () {
      test('all required fields are set', () {
        expect(pendingRequest.id, equals('req_001'));
        expect(pendingRequest.schoolId, equals('school_001'));
        expect(pendingRequest.schoolName, equals('Test School'));
        expect(pendingRequest.requestedModules, hasLength(3));
        expect(pendingRequest.packageType, equals('standard'));
        expect(pendingRequest.status, equals('pending'));
        expect(pendingRequest.requestedAt, equals(DateTime(2025, 1, 15)));
      });

      test('optional fields default to null', () {
        expect(pendingRequest.reviewedAt, isNull);
        expect(pendingRequest.reviewedBy, isNull);
        expect(pendingRequest.rejectionReason, isNull);
        expect(pendingRequest.notes, isNull);
      });

      test('optional fields can be set', () {
        expect(rejectedRequest.reviewedAt, isNotNull);
        expect(rejectedRequest.reviewedBy, equals('admin_uid'));
        expect(rejectedRequest.rejectionReason, equals('Payment not received'));
        expect(rejectedRequest.notes, equals('Contact school admin'));
      });
    });

    group('toFirestore', () {
      test('serializes all required fields', () {
        final map = pendingRequest.toFirestore();
        expect(map['schoolId'], equals('school_001'));
        expect(map['schoolName'], equals('Test School'));
        expect(map['requestedModules'], hasLength(3));
        expect(map['packageType'], equals('standard'));
        expect(map['status'], equals('pending'));
      });

      test('excludes null optional fields', () {
        final map = pendingRequest.toFirestore();
        expect(map.containsKey('reviewedAt'), isFalse);
        expect(map.containsKey('reviewedBy'), isFalse);
        expect(map.containsKey('rejectionReason'), isFalse);
        expect(map.containsKey('notes'), isFalse);
      });

      test('includes non-null optional fields', () {
        final map = rejectedRequest.toFirestore();
        expect(map.containsKey('reviewedAt'), isTrue);
        expect(map.containsKey('reviewedBy'), isTrue);
        expect(map.containsKey('rejectionReason'), isTrue);
        expect(map.containsKey('notes'), isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with updated status', () {
        final copy = pendingRequest.copyWith(status: 'approved');
        expect(copy.status, equals('approved'));
        expect(copy.id, equals(pendingRequest.id));
        expect(copy.schoolId, equals(pendingRequest.schoolId));
        expect(copy.requestedModules, equals(pendingRequest.requestedModules));
      });

      test('creates copy with updated optional fields', () {
        final now = DateTime.now();
        final copy = pendingRequest.copyWith(
          reviewedAt: now,
          reviewedBy: 'admin_1',
          rejectionReason: 'Test reason',
        );
        expect(copy.reviewedAt, equals(now));
        expect(copy.reviewedBy, equals('admin_1'));
        expect(copy.rejectionReason, equals('Test reason'));
      });

      test('preserves original when no changes', () {
        final copy = rejectedRequest.copyWith();
        expect(copy.rejectionReason, equals(rejectedRequest.rejectionReason));
        expect(copy.notes, equals(rejectedRequest.notes));
      });
    });

    group('equality', () {
      test('two requests with same id are equal', () {
        final copy = pendingRequest.copyWith(status: 'approved');
        expect(copy, equals(pendingRequest));
      });

      test('two requests with different id are not equal', () {
        expect(pendingRequest, isNot(equals(approvedRequest)));
      });
    });

    group('toString', () {
      test('contains relevant info', () {
        final str = pendingRequest.toString();
        expect(str, contains('req_001'));
        expect(str, contains('school_001'));
        expect(str, contains('pending'));
      });
    });

    group('edge cases', () {
      test('empty modules list is valid', () {
        final req = LicenseRequest(
          id: 'edge_1',
          schoolId: 's1',
          schoolName: 'Edge School',
          requestedModules: [],
          packageType: 'custom',
          status: 'pending',
          requestedAt: DateTime.now(),
        );
        expect(req.requestedModules, isEmpty);
      });

      test('empty strings are accepted in construction', () {
        final req = LicenseRequest(
          id: '',
          schoolId: '',
          schoolName: '',
          requestedModules: [],
          packageType: '',
          status: '',
          requestedAt: DateTime.now(),
        );
        expect(req.id, isEmpty);
        expect(req.isPending, isFalse);
        expect(req.isApproved, isFalse);
        expect(req.isRejected, isFalse);
      });
    });
  });
}
