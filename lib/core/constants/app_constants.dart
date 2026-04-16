/// EduX School Management System
/// Core application constants used throughout the application
library;

import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// Application name
  static const String appName = 'EduX';

  /// Application full name
  static const String appFullName = 'EduX School Management System';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Default currency symbol
  static const String defaultCurrencySymbol = 'Rs.';

  /// Default currency name
  static const String defaultCurrencyName = 'Pakistani Rupee';

  /// Default currency locale for formatting
  static const String defaultCurrencyLocale = 'en_PK';

  // ── SharedPreferences Keys ──

  /// ISO 8601 timestamp of first app launch (trial start)
  static const String prefInstallDate = 'edux_install_date';

  /// Generated UUID for this school instance
  static const String prefSchoolId = 'edux_school_id';

  /// JSON-encoded license data (approved modules, expiry, etc.)
  static const String prefLicenseData = 'edux_license_data';

  /// Last submitted request status ('pending', 'approved', 'rejected')
  static const String prefRequestStatus = 'edux_request_status';

  /// School name stored for Firestore registration
  static const String prefSchoolName = 'edux_school_name';

  // ── Firestore REST API Config ──
  // EduX Desktop uses Firestore REST API (not Firebase SDK)
  // These values are from your Firebase Web App configuration
  //
  // Project: edux-licensing-b67ed
  // Note: The Web API Key is NOT a secret - security is enforced by Firestore Rules
  static const String firestoreProjectId = 'edux-licensing-b67ed';
  static const String firestoreApiKey =
      'AIzaSyDTSjoz5FsLPCisfvmpBHM6RLQlZyntvT8';

  /// Date format for display
  static const String displayDateFormat = 'dd MMM yyyy';

  /// Date format for database storage
  static const String dbDateFormat = 'yyyy-MM-dd';

  /// Time format for display
  static const String displayTimeFormat = 'hh:mm a';

  /// Time format for database storage
  static const String dbTimeFormat = 'HH:mm';

  /// DateTime format for display
  static const String displayDateTimeFormat = 'dd MMM yyyy, hh:mm a';

  /// Minimum password length
  static const int minPasswordLength = 6;

  /// Maximum password length
  static const int maxPasswordLength = 32;

  /// Default page size for pagination
  static const int defaultPageSize = 25;

  /// Maximum page size for pagination
  static const int maxPageSize = 100;

  /// Backup file extension
  static const String backupFileExtension = '.edux';

  /// Export PDF file extension
  static const String pdfFileExtension = '.pdf';

  /// Export Excel file extension
  static const String excelFileExtension = '.xlsx';

  /// Default academic year format
  static const String academicYearFormat = 'yyyy-yyyy';

  /// Window minimum width
  static const double windowMinWidth = 900;

  /// Window minimum height
  static const double windowMinHeight = 600;

  /// Window default width
  static const double windowDefaultWidth = 1400;

  /// Window default height
  static const double windowDefaultHeight = 900;
}

/// NovaByte support contact details
class NovaByteContact {
  NovaByteContact._();

  /// Company name
  static const String companyName = 'Nova Byte';

  /// Support email
  static const String email = 'info.novabyte@gmail.com';

  /// WhatsApp number (international format for wa.me link)
  static const String whatsApp = '+923098842698';

  /// Display-friendly phone number
  static const String phoneDisplay = '0309 8842698';

  /// Website URL
  static const String website = 'https://novabyte.studio';
}

/// Sync-related constants
class SyncConstants {
  SyncConstants._();

  /// Default sync server port
  static const int defaultSyncPort = 8181;

  /// mDNS service name for discovery
  static const String mdnsServiceName = '_edux-sync._tcp';

  /// Sync token validity duration (hours)
  static const int tokenValidityHours = 4;

  /// Max retry attempts for sync operations
  static const int maxSyncRetries = 3;

  /// Retry delays in seconds
  static const List<int> retryDelays = [2, 5, 10];

  /// Sync status values
  static const String syncStatusSuccess = 'success';
  static const String syncStatusPartial = 'partial';
  static const String syncStatusFailed = 'failed';

  /// Sync type values
  static const String syncTypeUpload = 'upload';
  static const String syncTypeDownload = 'download';
  static const String syncTypeFull = 'full';
}

/// Database-related constants
class DbConstants {
  DbConstants._();

  /// Database file name
  static const String dbFileName = 'edux_database_v2.db';

  /// Database version for migrations
  static const int dbVersion = 11;

  /// Backup directory name
  static const String backupDirName = 'backups';

  /// Auto-backup retention days
  static const int autoBackupRetentionDays = 30;

  /// Maximum backup files to keep
  static const int maxBackupFiles = 10;
}

/// User roles in the system
class UserRoles {
  UserRoles._();

  static const String admin = 'admin';
  static const String principal = 'principal';
  static const String teacher = 'teacher';
  static const String accountant = 'accountant';

  static const List<String> all = [admin, principal, teacher, accountant];

  static String getDisplayName(String role) {
    switch (role) {
      case admin:
        return 'Administrator';
      case principal:
        return 'Principal';
      case teacher:
        return 'Teacher';
      case accountant:
        return 'Accountant';
      default:
        return role;
    }
  }
}

/// Student status constants
class StudentStatus {
  StudentStatus._();

  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String graduated = 'graduated';
  static const String withdrawn = 'withdrawn';
  static const String transferred = 'transferred';

  static const List<String> all = [
    active,
    inactive,
    graduated,
    withdrawn,
    transferred,
  ];

  static String getDisplayName(String status) {
    switch (status) {
      case active:
        return 'Active';
      case inactive:
        return 'Inactive';
      case graduated:
        return 'Graduated';
      case withdrawn:
        return 'Withdrawn';
      case transferred:
        return 'Transferred';
      default:
        return status;
    }
  }
}

/// Staff status constants
class StaffStatus {
  StaffStatus._();

  static const String active = 'active';
  static const String onLeave = 'on_leave';
  static const String resigned = 'resigned';
  static const String terminated = 'terminated';

  static const List<String> all = [active, onLeave, resigned, terminated];
}

/// Attendance status constants
class AttendanceStatus {
  AttendanceStatus._();

  static const String present = 'present';
  static const String absent = 'absent';
  static const String late = 'late';
  static const String leave = 'leave';
  static const String halfDay = 'half_day';

  static const List<String> studentStatuses = [present, absent, late, leave];
  static const List<String> staffStatuses = [
    present,
    absent,
    late,
    leave,
    halfDay,
  ];

  static String getDisplayName(String status) {
    switch (status) {
      case present:
        return 'Present';
      case absent:
        return 'Absent';
      case late:
        return 'Late';
      case leave:
        return 'Leave';
      case halfDay:
        return 'Half Day';
      default:
        return status;
    }
  }

  static String getShortCode(String status) {
    switch (status) {
      case present:
        return 'P';
      case absent:
        return 'A';
      case late:
        return 'L';
      case leave:
        return 'LV';
      case halfDay:
        return 'HD';
      default:
        return status[0].toUpperCase();
    }
  }
}

/// Gender constants
class Gender {
  Gender._();

  static const String male = 'male';
  static const String female = 'female';

  static const List<String> all = [male, female];

  static String getDisplayName(String gender) {
    switch (gender) {
      case male:
        return 'Male';
      case female:
        return 'Female';
      default:
        return gender;
    }
  }
}

/// Class level constants
class ClassLevel {
  ClassLevel._();

  static const String prePrimary = 'pre_primary';
  static const String primary = 'primary';
  static const String middle = 'middle';
  static const String secondary = 'secondary';

  static const List<String> all = [prePrimary, primary, middle, secondary];

  static String getDisplayName(String level) {
    switch (level) {
      case prePrimary:
        return 'Pre-Primary';
      case primary:
        return 'Primary';
      case middle:
        return 'Middle';
      case secondary:
        return 'Secondary';
      default:
        return level;
    }
  }
}

/// Fee-related constants
class FeeConstants {
  FeeConstants._();

  /// Payment modes
  static const String paymentModeCash = 'cash';
  static const String paymentModeBank = 'bank_transfer';
  static const String paymentModeCheque = 'cheque';
  static const String paymentModeOnline = 'online';

  static const List<String> paymentModes = [
    paymentModeCash,
    paymentModeBank,
    paymentModeCheque,
    paymentModeOnline,
  ];

  /// Invoice statuses
  static const String invoiceStatusPending = 'pending';
  static const String invoiceStatusPartial = 'partial';
  static const String invoiceStatusPaid = 'paid';
  static const String invoiceStatusOverdue = 'overdue';
  static const String invoiceStatusCancelled = 'cancelled';

  static const List<String> invoiceStatuses = [
    invoiceStatusPending,
    invoiceStatusPartial,
    invoiceStatusPaid,
    invoiceStatusOverdue,
    invoiceStatusCancelled,
  ];

  static String getPaymentModeDisplayName(String mode) {
    switch (mode) {
      case paymentModeCash:
        return 'Cash';
      case paymentModeBank:
        return 'Bank Transfer';
      case paymentModeCheque:
        return 'Cheque';
      case paymentModeOnline:
        return 'Online Payment';
      default:
        return mode;
    }
  }

  /// Get icon data for payment mode (for Flutter)
  static IconData getPaymentModeIconData(String mode) {
    switch (mode) {
      case paymentModeCash:
        return Icons.money;
      case paymentModeBank:
        return Icons.account_balance;
      case paymentModeCheque:
        return Icons.article;
      case paymentModeOnline:
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  /// Get color for payment mode
  static Color getPaymentModeColor(String mode) {
    switch (mode) {
      case paymentModeCash:
        return Colors.green;
      case paymentModeBank:
        return Colors.blue;
      case paymentModeCheque:
        return Colors.orange;
      case paymentModeOnline:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get icon name for payment mode (string for PDF generation)
  static String getPaymentModeIcon(String mode) {
    switch (mode) {
      case paymentModeCash:
        return 'money';
      case paymentModeBank:
        return 'account_balance';
      case paymentModeCheque:
        return 'article';
      case paymentModeOnline:
        return 'phone_android';
      default:
        return 'payment';
    }
  }

  /// Get color for payment mode (as hex string for PDF generation)
  static String getPaymentModeColorHex(String mode) {
    switch (mode) {
      case paymentModeCash:
        return '#4CAF50'; // Green
      case paymentModeBank:
        return '#2196F3'; // Blue
      case paymentModeCheque:
        return '#FF9800'; // Orange
      case paymentModeOnline:
        return '#9C27B0'; // Purple
      default:
        return '#9E9E9E'; // Grey
    }
  }
}

/// Exam-related constants
class ExamConstants {
  ExamConstants._();

  /// Exam types
  static const String typeUnitTest = 'unit_test';
  static const String typeMonthlyTest = 'monthly_test';
  static const String typeTermExam = 'term_exam';
  static const String typeAnnualExam = 'annual_exam';
  static const String typePractice = 'practice';

  static const List<String> types = [
    typeUnitTest,
    typeMonthlyTest,
    typeTermExam,
    typeAnnualExam,
    typePractice,
  ];

  /// Exam statuses
  static const String statusDraft = 'draft';
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';

  static const List<String> statuses = [
    statusDraft,
    statusActive,
    statusCompleted,
  ];

  static String getTypeDisplayName(String type) {
    switch (type) {
      case typeUnitTest:
        return 'Unit Test';
      case typeMonthlyTest:
        return 'Monthly Test';
      case typeTermExam:
        return 'Term Exam';
      case typeAnnualExam:
        return 'Annual Exam';
      case typePractice:
        return 'Practice Test';
      default:
        return type;
    }
  }

  /// Type labels for display
  static const Map<String, String> typeLabels = {
    typeUnitTest: 'Unit Test',
    typeMonthlyTest: 'Monthly Test',
    typeTermExam: 'Term Exam',
    typeAnnualExam: 'Annual Exam',
    typePractice: 'Practice Test',
  };
}

/// Leave-related constants
class LeaveConstants {
  LeaveConstants._();

  /// Leave types
  static const String typeSick = 'sick';
  static const String typeCasual = 'casual';
  static const String typeAnnual = 'annual';
  static const String typeMaternity = 'maternity';
  static const String typeUnpaid = 'unpaid';

  static const List<String> types = [
    typeSick,
    typeCasual,
    typeAnnual,
    typeMaternity,
    typeUnpaid,
  ];

  /// Leave request statuses
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  static const List<String> statuses = [
    statusPending,
    statusApproved,
    statusRejected,
  ];
}

/// Guardian relation constants
class GuardianRelation {
  GuardianRelation._();

  static const String father = 'father';
  static const String mother = 'mother';
  static const String guardian = 'guardian';
  static const String grandparent = 'grandparent';
  static const String sibling = 'sibling';
  static const String other = 'other';

  static const List<String> all = [
    father,
    mother,
    guardian,
    grandparent,
    sibling,
    other,
  ];

  static String getDisplayName(String relation) {
    switch (relation) {
      case father:
        return 'Father';
      case mother:
        return 'Mother';
      case guardian:
        return 'Guardian';
      case grandparent:
        return 'Grandparent';
      case sibling:
        return 'Sibling';
      case other:
        return 'Other';
      default:
        return relation;
    }
  }
}
