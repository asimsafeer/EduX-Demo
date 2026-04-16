import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novabyte_hub/services/firestore_service.dart';

void main() {
  group('FirestoreService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreService firestoreService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreService = FirestoreService(firestore: fakeFirestore);
    });

    test('grantLicense creates license with integrity hash', () async {
      await firestoreService.grantLicense(
        schoolId: 'school_1',
        modules: ['attendance_tracking'],
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        adminUid: 'admin_1',
      );

      final licenseDoc = await fakeFirestore
          .collection('licenses')
          .doc('school_1')
          .get();
      expect(licenseDoc.exists, true);

      final data = licenseDoc.data()!;
      expect(data['schoolId'], 'school_1');
      expect(data['approvedModules'], ['attendance_tracking']);
      expect(data['isActive'], true);

      // Ensure integrity hash is generated
      expect(data['integrityHash'], isNotNull);
      expect(data['integrityHash'].toString().isNotEmpty, true);
    });

    test('updateLicenseModules updates modules and rebuilds hash', () async {
      await firestoreService.grantLicense(
        schoolId: 'school_2',
        modules: ['attendance_tracking'],
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        adminUid: 'admin_1',
      );

      final licenseDocInitial = await fakeFirestore
          .collection('licenses')
          .doc('school_2')
          .get();
      final initialHash = licenseDocInitial.data()!['integrityHash'];

      await firestoreService.updateLicenseModules(
        schoolId: 'school_2',
        modules: ['attendance_tracking', 'student_management'],
        adminUid: 'admin_1',
      );

      final licenseDocUpdated = await fakeFirestore
          .collection('licenses')
          .doc('school_2')
          .get();
      final updatedData = licenseDocUpdated.data()!;
      expect(updatedData['approvedModules'], [
        'attendance_tracking',
        'student_management',
      ]);

      // Ensure integrity hash is updated
      expect(updatedData['integrityHash'], isNotNull);
      expect(updatedData['integrityHash'], isNot(initialHash));
    });
  });
}
