/// NovaByte Hub — School Data Model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a school registered in the EduX system
class School {
  final String schoolId;
  final String schoolName;
  final String? city;
  final String? phone;
  final String? email;
  final String deviceId;
  final DateTime installedAt;
  final DateTime createdAt;

  const School({
    required this.schoolId,
    required this.schoolName,
    this.city,
    this.phone,
    this.email,
    required this.deviceId,
    required this.installedAt,
    required this.createdAt,
  });

  /// Create from Firestore document snapshot
  factory School.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return School(
      schoolId: data['schoolId'] as String? ?? doc.id,
      schoolName: data['schoolName'] as String? ?? 'Unknown School',
      city: data['city'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      deviceId:
          data['deviceId'] as String? ??
          data['deviceFingerprint'] as String? ??
          '',
      installedAt: _parseTimestamp(data['installedAt'] ?? data['registeredAt']),
      createdAt: _parseTimestamp(data['createdAt'] ?? data['registeredAt']),
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'schoolName': schoolName,
      'city': city,
      'phone': phone,
      'email': email,
      'deviceId': deviceId,
      'installedAt': Timestamp.fromDate(installedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  School copyWith({
    String? schoolId,
    String? schoolName,
    String? city,
    String? phone,
    String? email,
    String? deviceId,
    DateTime? installedAt,
    DateTime? createdAt,
  }) {
    return School(
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      deviceId: deviceId ?? this.deviceId,
      installedAt: installedAt ?? this.installedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Parse a Firestore timestamp field safely
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  String toString() => 'School($schoolId, $schoolName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is School &&
          runtimeType == other.runtimeType &&
          schoolId == other.schoolId;

  @override
  int get hashCode => schoolId.hashCode;
}
