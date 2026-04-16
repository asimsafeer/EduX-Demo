/// NovaByte Hub — License Request Data Model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a license request from a school
class LicenseRequest {
  final String id;
  final String schoolId;
  final String schoolName;
  final List<String> requestedModules;
  final String packageType;
  final String status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;

  const LicenseRequest({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.requestedModules,
    required this.packageType,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
  });

  /// Whether this request is still pending review
  bool get isPending => status == 'pending';

  /// Whether this request has been approved
  bool get isApproved => status == 'approved';

  /// Whether this request has been rejected
  bool get isRejected => status == 'rejected';

  /// Create from Firestore document snapshot
  factory LicenseRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return LicenseRequest(
      id: doc.id,
      schoolId: data['schoolId'] as String? ?? '',
      schoolName: data['schoolName'] as String? ?? 'Unknown School',
      requestedModules: List<String>.from(
        data['requestedModules'] as List<dynamic>? ?? [],
      ),
      packageType: data['packageType'] as String? ?? 'custom',
      status: data['status'] as String? ?? 'pending',
      requestedAt: _parseTimestamp(data['requestedAt']),
      reviewedAt: data['reviewedAt'] != null
          ? _parseTimestamp(data['reviewedAt'])
          : null,
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      notes: data['notes'] as String?,
    );
  }

  /// Convert to Firestore-compatible map (for creating a new request)
  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'schoolName': schoolName,
      'requestedModules': requestedModules,
      'packageType': packageType,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (notes != null) 'notes': notes,
    };
  }

  /// Create a copy with updated fields
  LicenseRequest copyWith({
    String? id,
    String? schoolId,
    String? schoolName,
    List<String>? requestedModules,
    String? packageType,
    String? status,
    DateTime? requestedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? notes,
  }) {
    return LicenseRequest(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      requestedModules: requestedModules ?? this.requestedModules,
      packageType: packageType ?? this.packageType,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
    );
  }

  /// Parse a Firestore timestamp field safely
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  String toString() => 'LicenseRequest($id, school=$schoolId, status=$status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LicenseRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
