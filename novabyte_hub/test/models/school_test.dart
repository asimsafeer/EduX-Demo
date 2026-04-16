/// Unit tests for School model
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:novabyte_hub/models/school.dart';

void main() {
  group('School', () {
    late School school;
    late School minimalSchool;

    setUp(() {
      school = School(
        schoolId: 'SCH-001',
        schoolName: 'Test Academy',
        city: 'Lahore',
        phone: '+923001234567',
        email: 'test@academy.edu',
        deviceId: 'device_abc123',
        installedAt: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 2),
      );

      minimalSchool = School(
        schoolId: 'SCH-002',
        schoolName: 'Minimal School',
        deviceId: 'device_xyz',
        installedAt: DateTime(2025, 3, 1),
        createdAt: DateTime(2025, 3, 1),
      );
    });

    group('construction', () {
      test('all fields are set correctly', () {
        expect(school.schoolId, equals('SCH-001'));
        expect(school.schoolName, equals('Test Academy'));
        expect(school.city, equals('Lahore'));
        expect(school.phone, equals('+923001234567'));
        expect(school.email, equals('test@academy.edu'));
        expect(school.deviceId, equals('device_abc123'));
        expect(school.installedAt, equals(DateTime(2025, 1, 1)));
        expect(school.createdAt, equals(DateTime(2025, 1, 2)));
      });

      test('optional fields default to null', () {
        expect(minimalSchool.city, isNull);
        expect(minimalSchool.phone, isNull);
        expect(minimalSchool.email, isNull);
      });
    });

    group('toFirestore', () {
      test('serializes all fields including nulls', () {
        final map = school.toFirestore();
        expect(map['schoolId'], equals('SCH-001'));
        expect(map['schoolName'], equals('Test Academy'));
        expect(map['city'], equals('Lahore'));
        expect(map['phone'], equals('+923001234567'));
        expect(map['email'], equals('test@academy.edu'));
        expect(map['deviceId'], equals('device_abc123'));
      });

      test('serializes null optional fields', () {
        final map = minimalSchool.toFirestore();
        expect(map['city'], isNull);
        expect(map['phone'], isNull);
        expect(map['email'], isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final copy = school.copyWith(
          schoolName: 'Updated Academy',
          city: 'Islamabad',
        );
        expect(copy.schoolName, equals('Updated Academy'));
        expect(copy.city, equals('Islamabad'));
        expect(copy.schoolId, equals(school.schoolId));
        expect(copy.deviceId, equals(school.deviceId));
      });

      test('preserves original when no changes', () {
        final copy = school.copyWith();
        expect(copy.schoolId, equals(school.schoolId));
        expect(copy.schoolName, equals(school.schoolName));
        expect(copy.city, equals(school.city));
      });
    });

    group('equality', () {
      test('two schools with same schoolId are equal', () {
        final copy = school.copyWith(schoolName: 'Different Name');
        expect(copy, equals(school));
      });

      test('two schools with different schoolId are not equal', () {
        expect(school, isNot(equals(minimalSchool)));
      });

      test('hashCode is based on schoolId', () {
        final copy = school.copyWith(schoolName: 'Different Name');
        expect(copy.hashCode, equals(school.hashCode));
      });
    });

    group('toString', () {
      test('contains school id and name', () {
        final str = school.toString();
        expect(str, contains('SCH-001'));
        expect(str, contains('Test Academy'));
      });
    });
  });
}
