/// EduX School Management System
/// School Settings Provider - Manages school settings state
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../services/services.dart';

/// School settings service provider (singleton)
final schoolSettingsServiceProvider = Provider<SchoolSettingsService>((ref) {
  return SchoolSettingsService.instance();
});

/// School settings provider
final schoolSettingsProvider = FutureProvider<SchoolSetting?>((ref) async {
  final service = ref.watch(schoolSettingsServiceProvider);
  return await service.getSettings();
});

/// Is school setup complete provider
final isSchoolSetupProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(schoolSettingsServiceProvider);
  return await service.isSchoolSetup();
});

/// Academic years list provider
final academicYearsProvider = FutureProvider<List<AcademicYear>>((ref) async {
  final service = ref.watch(schoolSettingsServiceProvider);
  return await service.getAcademicYears();
});

/// Current academic year provider
final currentAcademicYearProvider = FutureProvider<AcademicYear?>((ref) async {
  final service = ref.watch(schoolSettingsServiceProvider);
  return await service.getCurrentAcademicYear();
});
