/// EduX School Management System
/// Demo Mode Configuration
library;

/// Master demo mode configuration.
/// Set [isDemo] to `true` to build the demo version.
class DemoConfig {
  DemoConfig._();

  /// Master flag — controls all demo behavior across the app.
  static const bool isDemo = true;

  /// Demo login credentials
  static const String demoUsername = 'demo';
  static const String demoPassword = 'demo123';

  /// Demo school info
  static const String demoSchoolName = 'Springfield Public School';
  static const String demoAcademicYear = '2025-2026';

  /// Contact info shown in restriction messages
  static const String contactWhatsApp = '+923098842698';

  /// Message shown when a demo-restricted action is attempted
  static String get restrictionMessage =>
      'This feature is restricted in the Demo version.\n'
      'Contact Nova Byte at $contactWhatsApp for the full version.';
}

/// Exception thrown when a demo-restricted operation is attempted.
/// The [toString] returns a user-friendly message that flows through
/// existing error handling to be displayed in the UI.
class DemoRestrictionException implements Exception {
  @override
  String toString() => DemoConfig.restrictionMessage;
}
