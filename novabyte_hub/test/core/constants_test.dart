/// Unit tests for app constants and module definitions
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:novabyte_hub/core/constants/app_constants.dart';
import 'package:novabyte_hub/core/constants/module_constants.dart';

void main() {
  group('AppConstants', () {
    test('app name is set', () {
      expect(AppConstants.appName, isNotEmpty);
    });

    test('app version follows semver pattern', () {
      expect(
        RegExp(r'^\d+\.\d+\.\d+$').hasMatch(AppConstants.appVersion),
        isTrue,
      );
    });

    test('default license duration is positive', () {
      expect(AppConstants.defaultLicenseDurationDays, greaterThan(0));
    });

    test('expiry warning days is positive', () {
      expect(AppConstants.expiryWarningDays, greaterThan(0));
    });

    test('items per page is positive', () {
      expect(AppConstants.itemsPerPage, greaterThan(0));
    });

    test('request check cooldown is positive', () {
      expect(AppConstants.requestCheckCooldown.inSeconds, greaterThan(0));
    });
  });

  group('FirestoreCollections', () {
    test('all collection names are non-empty', () {
      expect(FirestoreCollections.schools, isNotEmpty);
      expect(FirestoreCollections.licenseRequests, isNotEmpty);
      expect(FirestoreCollections.licenses, isNotEmpty);
      expect(FirestoreCollections.admins, isNotEmpty);
      expect(FirestoreCollections.adminConfig, isNotEmpty);
    });

    test('collection names contain only valid Firestore paths', () {
      final validPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
      expect(validPattern.hasMatch(FirestoreCollections.schools), isTrue);
      expect(validPattern.hasMatch(FirestoreCollections.admins), isTrue);
    });
  });

  group('RequestStatus', () {
    test('all statuses defined', () {
      expect(RequestStatus.pending, equals('pending'));
      expect(RequestStatus.approved, equals('approved'));
      expect(RequestStatus.rejected, equals('rejected'));
    });

    test('all list contains all statuses', () {
      expect(RequestStatus.all, contains('pending'));
      expect(RequestStatus.all, contains('approved'));
      expect(RequestStatus.all, contains('rejected'));
      expect(RequestStatus.all, hasLength(3));
    });

    test('getDisplayName returns capitalized names', () {
      expect(RequestStatus.getDisplayName('pending'), equals('Pending'));
      expect(RequestStatus.getDisplayName('approved'), equals('Approved'));
      expect(RequestStatus.getDisplayName('rejected'), equals('Rejected'));
    });

    test('getDisplayName returns unknown status as-is', () {
      expect(RequestStatus.getDisplayName('unknown'), equals('unknown'));
    });
  });

  group('PackageType', () {
    test('all package types defined', () {
      expect(PackageType.basic, equals('basic'));
      expect(PackageType.standard, equals('standard'));
      expect(PackageType.premium, equals('premium'));
      expect(PackageType.custom, equals('custom'));
    });

    test('all list contains all types', () {
      expect(PackageType.all, hasLength(4));
      expect(PackageType.all, contains('basic'));
      expect(PackageType.all, contains('standard'));
      expect(PackageType.all, contains('premium'));
      expect(PackageType.all, contains('custom'));
    });

    test('getDisplayName returns capitalized names', () {
      expect(PackageType.getDisplayName('basic'), equals('Basic'));
      expect(PackageType.getDisplayName('premium'), equals('Premium'));
    });

    test('getDisplayName returns unknown type as-is', () {
      expect(PackageType.getDisplayName('enterprise'), equals('enterprise'));
    });
  });

  group('EduXModules', () {
    test('allIds has 11 modules', () {
      expect(EduXModules.allIds, hasLength(11));
    });

    test('allModules has 11 ModuleInfo entries', () {
      expect(EduXModules.allModules, hasLength(11));
    });

    test('allIds and allModules are in sync', () {
      final moduleInfoIds = EduXModules.allModules.map((m) => m.id).toList();
      expect(moduleInfoIds, equals(EduXModules.allIds));
    });

    test('each module has a non-empty name and description', () {
      for (final mod in EduXModules.allModules) {
        expect(mod.name, isNotEmpty, reason: 'Module ${mod.id} has empty name');
        expect(
          mod.description,
          isNotEmpty,
          reason: 'Module ${mod.id} has empty description',
        );
      }
    });

    test('getById returns correct module', () {
      final mod = EduXModules.getById('student_management');
      expect(mod, isNotNull);
      expect(mod!.name, equals('Student Management'));
    });

    test('getById returns null for unknown module', () {
      final mod = EduXModules.getById('nonexistent');
      expect(mod, isNull);
    });

    test('getModuleName returns name for valid module', () {
      expect(EduXModules.getModuleName('fee_management'),
          equals('Fee Management'));
    });

    test('getModuleName returns id for unknown module', () {
      expect(EduXModules.getModuleName('nonexistent'), equals('nonexistent'));
    });

    test('no duplicate module IDs', () {
      final ids = EduXModules.allIds.toSet();
      expect(ids.length, equals(EduXModules.allIds.length));
    });

    test('module constants match allIds', () {
      expect(EduXModules.allIds, contains(EduXModules.students));
      expect(EduXModules.allIds, contains(EduXModules.guardians));
      expect(EduXModules.allIds, contains(EduXModules.staff));
      expect(EduXModules.allIds, contains(EduXModules.academics));
      expect(EduXModules.allIds, contains(EduXModules.attendance));
      expect(EduXModules.allIds, contains(EduXModules.exams));
      expect(EduXModules.allIds, contains(EduXModules.fees));
      expect(EduXModules.allIds, contains(EduXModules.expenses));
      expect(EduXModules.allIds, contains(EduXModules.canteen));
      expect(EduXModules.allIds, contains(EduXModules.reports));
      expect(EduXModules.allIds, contains(EduXModules.teacherApp));
    });
  });

  group('ModuleInfo', () {
    test('constructs with all fields', () {
      final mod = EduXModules.allModules.first;
      expect(mod.id, isNotEmpty);
      expect(mod.name, isNotEmpty);
      expect(mod.description, isNotEmpty);
      expect(mod.icon, isNotNull);
      expect(mod.color, isNotNull);
    });
  });
}
