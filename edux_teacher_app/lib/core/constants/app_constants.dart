/// EduX Teacher App - Core Application Constants
library;

import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'EduX Teacher';
  static const String appVersion = '1.0.0';

  // Sync server
  static const int syncServerPort = 8181;
  static const String mdnsServiceName = '_edux-sync._tcp';
  static const Duration discoveryTimeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 30);

  // Database
  static const String dbFileName = 'teacher_cache.db';
  static const int dbVersion = 1;

  // Sync
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 2);
  static const Duration tokenRefreshThreshold = Duration(minutes: 30);

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;

  // Cache
  static const Duration cacheValidity = Duration(hours: 24);

  // Attendance
  static const Duration autoLockDuration = Duration(minutes: 5);
}

/// Attendance status values (must match main system)
class AttendanceStatus {
  AttendanceStatus._();

  static const String present = 'present';
  static const String absent = 'absent';
  static const String late = 'late';
  static const String leave = 'leave';
  static const String halfDay = 'half_day';

  static const List<String> all = [present, absent, late, leave, halfDay];

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

  static Color getColor(String status) {
    switch (status) {
      case present:
        return const Color(0xFF4CAF50);
      case absent:
        return const Color(0xFFE53935);
      case late:
        return const Color(0xFFFF9800);
      case leave:
        return const Color(0xFF2196F3);
      case halfDay:
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  static Color getBackgroundColor(String status) {
    switch (status) {
      case present:
        return const Color(0xFFE8F5E9);
      case absent:
        return const Color(0xFFFFEBEE);
      case late:
        return const Color(0xFFFFF3E0);
      case leave:
        return const Color(0xFFE3F2FD);
      case halfDay:
        return const Color(0xFFF3E5F5);
      default:
        return Colors.grey.shade100;
    }
  }

  static IconData getIcon(String status) {
    switch (status) {
      case present:
        return Icons.check_circle;
      case absent:
        return Icons.cancel;
      case late:
        return Icons.schedule;
      case leave:
        return Icons.event_busy;
      case halfDay:
        return Icons.timelapse;
      default:
        return Icons.help;
    }
  }
}

/// Config keys for local storage
class ConfigKeys {
  ConfigKeys._();

  static const String deviceId = 'device_id';
  static const String serverIp = 'server_ip';
  static const String serverPort = 'server_port';
  static const String authToken = 'auth_token';
  static const String teacherId = 'teacher_id';
  static const String teacherName = 'teacher_name';
  static const String teacherEmail = 'teacher_email';
  static const String teacherPhoto = 'teacher_photo';
  static const String lastSync = 'last_sync';
  static const String cacheVersion = 'cache_version';
  static const String biometricEnabled = 'biometric_enabled';
}

/// Sync status values
class SyncStatusValues {
  SyncStatusValues._();

  static const String success = 'success';
  static const String partial = 'partial';
  static const String failed = 'failed';
  static const String pending = 'pending';
}

/// Gender values
class Gender {
  Gender._();

  static const String male = 'male';
  static const String female = 'female';

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
