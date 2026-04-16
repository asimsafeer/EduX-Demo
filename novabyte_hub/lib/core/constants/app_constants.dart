/// NovaByte Hub — Application Constants
library;

/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// Application name
  static const String appName = 'NovaByte Hub';

  /// Application tagline
  static const String appTagline = 'EduX License Management';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Company name
  static const String companyName = 'NovaByte';

  /// Default license duration in days
  static const int defaultLicenseDurationDays = 365;

  /// License expiry warning threshold in days
  static const int expiryWarningDays = 30;

  /// Request cooldown period
  static const Duration requestCheckCooldown = Duration(minutes: 1);

  /// Items per page for paginated lists
  static const int itemsPerPage = 20;
}

/// Firestore collection names
class FirestoreCollections {
  FirestoreCollections._();

  static const String schools = 'schools';
  static const String licenseRequests = 'license_requests';
  static const String licenses = 'licenses';
  static const String admins = 'admins';
  static const String adminConfig = 'admin_config';
}

/// License request status constants
class RequestStatus {
  RequestStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const List<String> all = [pending, approved, rejected];

  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      default:
        return status;
    }
  }
}

/// Package type constants
class PackageType {
  PackageType._();

  static const String basic = 'basic';
  static const String standard = 'standard';
  static const String premium = 'premium';
  static const String custom = 'custom';

  static const List<String> all = [basic, standard, premium, custom];

  static String getDisplayName(String type) {
    switch (type) {
      case basic:
        return 'Basic';
      case standard:
        return 'Standard';
      case premium:
        return 'Premium';
      case custom:
        return 'Custom';
      default:
        return type;
    }
  }
}
