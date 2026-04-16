/// EduX School Management System
/// School Settings Service - Manages school configuration
library;

import 'package:drift/drift.dart';

import '../core/demo/demo_config.dart';
import '../database/database.dart';

/// School settings management service
class SchoolSettingsService {
  final AppDatabase _db;

  SchoolSettingsService(this._db);

  /// Factory constructor using singleton database
  factory SchoolSettingsService.instance() =>
      SchoolSettingsService(AppDatabase.instance);

  // ============================================
  // SCHOOL SETTINGS
  // ============================================

  /// Get current school settings
  Future<SchoolSetting?> getSettings() async {
    return await _db.select(_db.schoolSettings).getSingleOrNull();
  }

  /// Check if school is set up
  Future<bool> isSchoolSetup() async {
    final settings = await getSettings();
    return settings?.isSetupComplete ?? false;
  }

  /// Update school settings
  Future<SchoolSetting> updateSettings({
    String? schoolName,
    String? institutionType,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phone,
    String? alternatePhone,
    String? email,
    String? website,
    String? principalName,
    String? currencySymbol,
    String? workingDays,
    String? schoolStartTime,
    String? schoolEndTime,
    String? bankName,
    String? accountTitle,
    String? accountNumber,
    String? onlinePaymentInfo,
  }) async {
    final existing = await getSettings();
    if (existing == null) {
      throw Exception('School settings not found. Please run setup first.');
    }

    await (_db.update(
      _db.schoolSettings,
    )..where((s) => s.id.equals(existing.id))).write(
      SchoolSettingsCompanion(
        schoolName: schoolName != null
            ? Value(schoolName.trim())
            : const Value.absent(),
        institutionType: institutionType != null
            ? Value(institutionType.trim())
            : const Value.absent(),
        address: address != null ? Value(address.trim()) : const Value.absent(),
        city: city != null ? Value(city.trim()) : const Value.absent(),
        state: state != null ? Value(state.trim()) : const Value.absent(),
        postalCode: postalCode != null
            ? Value(postalCode.trim())
            : const Value.absent(),
        country: country != null ? Value(country.trim()) : const Value.absent(),
        phone: phone != null ? Value(phone.trim()) : const Value.absent(),
        alternatePhone: alternatePhone != null
            ? Value(alternatePhone.trim())
            : const Value.absent(),
        email: email != null ? Value(email.trim()) : const Value.absent(),
        website: website != null ? Value(website.trim()) : const Value.absent(),
        principalName: principalName != null
            ? Value(principalName.trim())
            : const Value.absent(),
        currencySymbol: currencySymbol != null
            ? Value(currencySymbol.trim())
            : const Value.absent(),
        workingDays: workingDays != null
            ? Value(workingDays)
            : const Value.absent(),
        schoolStartTime: schoolStartTime != null
            ? Value(schoolStartTime)
            : const Value.absent(),
        schoolEndTime: schoolEndTime != null
            ? Value(schoolEndTime)
            : const Value.absent(),
        bankName: bankName != null
            ? Value(bankName.trim().isEmpty ? null : bankName.trim())
            : const Value.absent(),
        accountTitle: accountTitle != null
            ? Value(accountTitle.trim().isEmpty ? null : accountTitle.trim())
            : const Value.absent(),
        accountNumber: accountNumber != null
            ? Value(accountNumber.trim().isEmpty ? null : accountNumber.trim())
            : const Value.absent(),
        onlinePaymentInfo: onlinePaymentInfo != null
            ? Value(
                onlinePaymentInfo.trim().isEmpty
                    ? null
                    : onlinePaymentInfo.trim(),
              )
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return (await getSettings())!;
  }

  /// Update school logo
  Future<SchoolSetting> updateLogo(List<int> logoBytes) async {
    final existing = await getSettings();
    if (existing == null) {
      throw Exception('School settings not found. Please run setup first.');
    }

    await (_db.update(
      _db.schoolSettings,
    )..where((s) => s.id.equals(existing.id))).write(
      SchoolSettingsCompanion(
        logo: Value(Uint8List.fromList(logoBytes)),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return (await getSettings())!;
  }

  /// Remove school logo
  Future<SchoolSetting> removeLogo() async {
    final existing = await getSettings();
    if (existing == null) {
      throw Exception('School settings not found. Please run setup first.');
    }

    await (_db.update(_db.schoolSettings)
          ..where((s) => s.id.equals(existing.id)))
        .write(const SchoolSettingsCompanion(logo: Value(null)));

    return (await getSettings())!;
  }

  // ============================================
  // ACADEMIC YEARS
  // ============================================

  /// Get all academic years
  Future<List<AcademicYear>> getAcademicYears() async {
    return await (_db.select(
      _db.academicYears,
    )..orderBy([(y) => OrderingTerm.desc(y.startDate)])).get();
  }

  /// Get current academic year
  Future<AcademicYear?> getCurrentAcademicYear() async {
    return await (_db.select(
      _db.academicYears,
    )..where((y) => y.isCurrent.equals(true))).getSingleOrNull();
  }

  /// Get academic year by ID
  Future<AcademicYear?> getAcademicYearById(int id) async {
    return await (_db.select(
      _db.academicYears,
    )..where((y) => y.id.equals(id))).getSingleOrNull();
  }

  /// Create a new academic year
  Future<AcademicYear> createAcademicYear({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool setAsCurrent = false,
  }) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    // Validate dates
    if (endDate.isBefore(startDate)) {
      throw Exception('End date must be after start date');
    }

    // Check for duplicate name
    final existing = await (_db.select(
      _db.academicYears,
    )..where((y) => y.name.equals(name))).getSingleOrNull();
    if (existing != null) {
      throw Exception('Academic year "$name" already exists');
    }

    // If setting as current, unset any existing current year
    if (setAsCurrent) {
      await (_db.update(_db.academicYears)
            ..where((y) => y.isCurrent.equals(true)))
          .write(const AcademicYearsCompanion(isCurrent: Value(false)));
    }

    final yearId = await _db
        .into(_db.academicYears)
        .insert(
          AcademicYearsCompanion.insert(
            name: name.trim(),
            startDate: startDate,
            endDate: endDate,
            isCurrent: Value(setAsCurrent),
          ),
        );

    // Update school settings with current academic year
    if (setAsCurrent) {
      final settings = await getSettings();
      if (settings != null) {
        await (_db.update(
          _db.schoolSettings,
        )..where((s) => s.id.equals(settings.id))).write(
          SchoolSettingsCompanion(
            currentAcademicYear: Value(name),
            academicYearStart: Value(startDate),
            academicYearEnd: Value(endDate),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }

    return (await getAcademicYearById(yearId))!;
  }

  /// Set an academic year as current
  Future<AcademicYear> setCurrentAcademicYear(int yearId) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final year = await getAcademicYearById(yearId);
    if (year == null) {
      throw Exception('Academic year not found');
    }

    // Unset any existing current year
    await (_db.update(_db.academicYears)
          ..where((y) => y.isCurrent.equals(true)))
        .write(const AcademicYearsCompanion(isCurrent: Value(false)));

    // Set the new current year
    await (_db.update(_db.academicYears)..where((y) => y.id.equals(yearId)))
        .write(const AcademicYearsCompanion(isCurrent: Value(true)));

    // Update school settings
    final settings = await getSettings();
    if (settings != null) {
      await (_db.update(
        _db.schoolSettings,
      )..where((s) => s.id.equals(settings.id))).write(
        SchoolSettingsCompanion(
          currentAcademicYear: Value(year.name),
          academicYearStart: Value(year.startDate),
          academicYearEnd: Value(year.endDate),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    return (await getAcademicYearById(yearId))!;
  }

  /// Archive an academic year
  Future<AcademicYear> archiveAcademicYear(int yearId) async {
    final year = await getAcademicYearById(yearId);
    if (year == null) {
      throw Exception('Academic year not found');
    }

    if (year.isCurrent) {
      throw Exception('Cannot archive the current academic year');
    }

    await (_db.update(_db.academicYears)..where((y) => y.id.equals(yearId)))
        .write(const AcademicYearsCompanion(isArchived: Value(true)));

    return (await getAcademicYearById(yearId))!;
  }

  /// Delete an academic year (only if no data associated)
  Future<void> deleteAcademicYear(int yearId) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final year = await getAcademicYearById(yearId);
    if (year == null) {
      throw Exception('Academic year not found');
    }

    if (year.isCurrent) {
      throw Exception('Cannot delete the current academic year');
    }

    // Check if there are any enrollments for this year
    // Note: In a full implementation, you'd check all related tables
    // For now, we'll allow deletion if it's archived

    await (_db.delete(
      _db.academicYears,
    )..where((y) => y.id.equals(yearId))).go();
  }

  // ============================================
  // WORKING DAYS HELPERS
  // ============================================

  /// Get working days as a list
  List<String> getWorkingDaysList(String workingDays) {
    if (workingDays.isEmpty) return [];
    return workingDays.split(',').map((d) => d.trim()).toList();
  }

  /// Format working days list to string
  String formatWorkingDays(List<String> days) {
    return days.join(',');
  }

  /// All possible days
  static const allDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  /// Day display names
  static const dayDisplayNames = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };
}
