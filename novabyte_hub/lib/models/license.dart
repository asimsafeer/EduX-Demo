/// NovaByte Hub — License Data Model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a granted license for a school
class License {
  final String schoolId;
  final List<String> approvedModules;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final bool isActive;
  final String grantedBy;
  final DateTime? lastCheckedAt;

  const License({
    required this.schoolId,
    required this.approvedModules,
    required this.grantedAt,
    required this.expiresAt,
    required this.isActive,
    required this.grantedBy,
    this.lastCheckedAt,
  });

  /// Whether the license is currently expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the license is valid (active and not expired)
  bool get isValid => isActive && !isExpired;

  /// Days remaining until expiry
  int get daysRemaining {
    final diff = expiresAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Whether the license is expiring soon (within 30 days)
  bool get isExpiringSoon => isValid && daysRemaining <= 30;

  /// Progress ratio for expiry (0.0 = just granted, 1.0 = expired)
  double get expiryProgress {
    final totalDuration = expiresAt.difference(grantedAt).inDays;
    if (totalDuration <= 0) return 1.0;
    final elapsed = DateTime.now().difference(grantedAt).inDays;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  /// Create from Firestore document snapshot
  factory License.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return License(
      schoolId: data['schoolId'] as String? ?? doc.id,
      approvedModules: List<String>.from(
        data['approvedModules'] as List<dynamic>? ?? [],
      ),
      grantedAt: _parseTimestamp(data['grantedAt']),
      expiresAt: _parseTimestamp(data['expiresAt']),
      isActive: data['isActive'] as bool? ?? false,
      grantedBy: data['grantedBy'] as String? ?? '',
      lastCheckedAt: data['lastCheckedAt'] != null
          ? _parseTimestamp(data['lastCheckedAt'])
          : null,
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'approvedModules': approvedModules,
      'grantedAt': Timestamp.fromDate(grantedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'grantedBy': grantedBy,
      if (lastCheckedAt != null)
        'lastCheckedAt': Timestamp.fromDate(lastCheckedAt!),
    };
  }

  /// Create a copy with updated fields
  License copyWith({
    String? schoolId,
    List<String>? approvedModules,
    DateTime? grantedAt,
    DateTime? expiresAt,
    bool? isActive,
    String? grantedBy,
    DateTime? lastCheckedAt,
  }) {
    return License(
      schoolId: schoolId ?? this.schoolId,
      approvedModules: approvedModules ?? this.approvedModules,
      grantedAt: grantedAt ?? this.grantedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      grantedBy: grantedBy ?? this.grantedBy,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  /// Parse a Firestore timestamp field safely
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  String toString() =>
      'License(school=$schoolId, modules=${approvedModules.length}, '
      'active=$isActive, expires=$expiresAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is License &&
          runtimeType == other.runtimeType &&
          schoolId == other.schoolId;

  @override
  int get hashCode => schoolId.hashCode;
}
