/// EduX School Management System
/// Working Days Service - Manages school working days consistency
library;

import 'package:drift/drift.dart';

import '../database/database.dart';

/// Service to handle working days across the application
/// Supports both school-wide and class-specific working days
class WorkingDaysService {
  final AppDatabase _db;
  
  WorkingDaysService(this._db);
  
  /// Factory constructor using singleton database
  factory WorkingDaysService.instance() => WorkingDaysService(AppDatabase.instance);

  /// Get school-wide default working days
  Future<List<String>> getWorkingDays() async {
    try {
      final settings = await _db.getSchoolSettings();
      if (settings == null || settings.workingDays.isEmpty) {
        // Default: Monday to Saturday
        return ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
      }
      
      final days = settings.workingDays
          .split(',')
          .map((d) => d.trim().toLowerCase())
          .where((d) => d.isNotEmpty)
          .toList();
      
      return days.isEmpty 
          ? ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
          : days;
    } catch (e) {
      // Fallback on error
      return ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    }
  }

  /// Get class-specific working days
  /// If class has custom working days configured, returns those
  /// Otherwise falls back to school-wide working days
  Future<List<String>> getClassWorkingDays(int classId, String academicYear) async {
    try {
      // Query class-specific working days
      final classWorkingDays = await (_db.select(_db.classWorkingDays)
        ..where((cwd) => cwd.classId.equals(classId) & cwd.academicYear.equals(academicYear) & cwd.isActive.equals(true)))
        .getSingleOrNull();
      
      if (classWorkingDays != null && classWorkingDays.workingDays != null && classWorkingDays.workingDays!.isNotEmpty) {
        final days = classWorkingDays.workingDays!
            .split(',')
            .map((d) => d.trim().toLowerCase())
            .where((d) => d.isNotEmpty)
            .toList();
        
        if (days.isNotEmpty) {
          return days;
        }
      }
      
      // Fall back to school-wide working days
      return await getWorkingDays();
    } catch (e) {
      // Fallback on error to school-wide working days
      return await getWorkingDays();
    }
  }

  /// Set class-specific working days
  Future<void> setClassWorkingDays({
    required int classId,
    required String academicYear,
    required List<String> workingDays,
  }) async {
    final daysString = workingDays.join(',');
    
    // Check if record exists
    final existing = await (_db.select(_db.classWorkingDays)
      ..where((cwd) => cwd.classId.equals(classId) & cwd.academicYear.equals(academicYear)))
      .getSingleOrNull();
    
    if (existing != null) {
      // Update existing
      await _db.update(_db.classWorkingDays).replace(
        existing.copyWith(
          workingDays: Value(daysString),
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      // Insert new
      await _db.into(_db.classWorkingDays).insert(
        ClassWorkingDaysCompanion.insert(
          classId: classId,
          academicYear: academicYear,
          workingDays: Value(daysString),
        ),
      );
    }
  }

  /// Clear class-specific working days (will use school default)
  Future<void> clearClassWorkingDays(int classId, String academicYear) async {
    await (_db.delete(_db.classWorkingDays)
      ..where((cwd) => cwd.classId.equals(classId) & cwd.academicYear.equals(academicYear)))
      .go();
  }

  /// Check if a specific day is a working day (school-wide)
  Future<bool> isWorkingDay(String day) async {
    final workingDays = await getWorkingDays();
    return workingDays.contains(day.toLowerCase());
  }

  /// Check if a specific day is a working day for a class
  Future<bool> isClassWorkingDay(int classId, String academicYear, String day) async {
    final workingDays = await getClassWorkingDays(classId, academicYear);
    return workingDays.contains(day.toLowerCase());
  }

  /// Check if a specific date is a working day (school-wide)
  Future<bool> isWorkingDate(DateTime date) async {
    final dayName = _getDayName(date.weekday);
    return isWorkingDay(dayName);
  }

  /// Check if a specific date is a working day for a class
  Future<bool> isClassWorkingDate(int classId, String academicYear, DateTime date) async {
    final dayName = _getDayName(date.weekday);
    return isClassWorkingDay(classId, academicYear, dayName);
  }

  /// Get list of working days for timetable display (school-wide)
  Future<List<String>> getTimetableDays() async {
    final allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final workingDays = await getWorkingDays();
    
    // Return only working days in order
    return allDays.where((day) => workingDays.contains(day)).toList();
  }

  /// Get list of working days for a specific class
  Future<List<String>> getClassTimetableDays(int classId, String academicYear) async {
    final allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final workingDays = await getClassWorkingDays(classId, academicYear);
    
    // Return only working days in order
    return allDays.where((day) => workingDays.contains(day)).toList();
  }

  /// Get display name for a day
  static String getDayDisplayName(String day) {
    final displayNames = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };
    return displayNames[day.toLowerCase()] ?? day;
  }

  /// Get short display name for a day
  static String getDayShortName(String day) {
    final shortNames = {
      'monday': 'Mon',
      'tuesday': 'Tue',
      'wednesday': 'Wed',
      'thursday': 'Thu',
      'friday': 'Fri',
      'saturday': 'Sat',
      'sunday': 'Sun',
    };
    return shortNames[day.toLowerCase()] ?? day;
  }

  /// Convert DateTime weekday to day name
  static String _getDayName(int weekday) {
    const days = ['', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday];
  }

  /// Public method to get day name from weekday number (1-7)
  static String getDayName(int weekday) {
    return _getDayName(weekday);
  }

  /// Calculate working days between two dates (school-wide)
  Future<int> calculateWorkingDays(DateTime start, DateTime end) async {
    final workingDays = await getWorkingDays();
    return _calculateWorkingDays(start, end, workingDays);
  }

  /// Calculate working days between two dates for a specific class
  Future<int> calculateClassWorkingDays(int classId, String academicYear, DateTime start, DateTime end) async {
    final workingDays = await getClassWorkingDays(classId, academicYear);
    return _calculateWorkingDays(start, end, workingDays);
  }

  /// Internal helper to calculate working days
  int _calculateWorkingDays(DateTime start, DateTime end, List<String> workingDays) {
    int count = 0;
    
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (!current.isAfter(endDate)) {
      final dayName = _getDayName(current.weekday);
      if (workingDays.contains(dayName)) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return count;
  }

  /// Get all dates that are working days in a range (school-wide)
  Future<List<DateTime>> getWorkingDatesInRange(DateTime start, DateTime end) async {
    final workingDays = await getWorkingDays();
    return _getWorkingDatesInRange(start, end, workingDays);
  }

  /// Get all dates that are working days in a range for a specific class
  Future<List<DateTime>> getClassWorkingDatesInRange(int classId, String academicYear, DateTime start, DateTime end) async {
    final workingDays = await getClassWorkingDays(classId, academicYear);
    return _getWorkingDatesInRange(start, end, workingDays);
  }

  /// Internal helper to get working dates in range
  List<DateTime> _getWorkingDatesInRange(DateTime start, DateTime end, List<String> workingDays) {
    final dates = <DateTime>[];
    
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (!current.isAfter(endDate)) {
      final dayName = _getDayName(current.weekday);
      if (workingDays.contains(dayName)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }

  /// Validate that at least one working day is selected
  static bool validateWorkingDays(List<String> days) {
    return days.isNotEmpty;
  }

  /// Get default working days (Monday-Saturday)
  static List<String> getDefaultWorkingDays() {
    return ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  }

  /// Get all available days
  static List<String> getAllDays() {
    return ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  }
}

/// Extension to check if date is weekend
extension DateTimeWorkingDays on DateTime {
  bool get isWeekend {
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }
  
  String get dayName {
    const days = ['', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday];
  }
}
