/// NovaByte Hub — Security Service
/// Centralized validation, sanitization, and state machine enforcement.
library;

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/module_constants.dart';

/// Result of a validation check
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult.success()
      : isValid = true,
        error = null;

  const ValidationResult.failure(this.error) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $error';
}

/// Centralized security validation for all admin operations
class SecurityService {
  const SecurityService();

  // ============================================================
  // INPUT SANITIZATION
  // ============================================================

  /// Sanitize a string input: trim whitespace, remove control characters
  String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove control chars
        .replaceAll(RegExp(r'\s+'), ' '); // Collapse multiple spaces
  }

  /// Sanitize a school ID (alphanumeric + hyphens only)
  String sanitizeSchoolId(String id) {
    return id.trim().replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '');
  }

  // ============================================================
  // MODULE VALIDATION
  // ============================================================

  /// Validate that all module IDs exist in the known module list
  /// NOTE: This validation is now lenient - it allows unknown module IDs
  /// but filters them out. This prevents errors when new modules are added
  /// to the desktop app before the hub is updated.
  ValidationResult validateModules(List<String> modules) {
    if (modules.isEmpty) {
      return const ValidationResult.failure(
        'At least one module must be selected',
      );
    }

    final validIds = EduXModules.allIds.toSet();

    // Filter out any unknown modules (instead of failing)
    // This allows forward compatibility when desktop adds new modules
    final validModules = modules.where((id) => validIds.contains(id)).toList();

    final unknownModules =
        modules.where((id) => !validIds.contains(id)).toList();

    if (unknownModules.isNotEmpty) {
      debugPrint(
          'WARNING: Unknown module IDs ignored: ${unknownModules.join(", ")}');
    }

    if (validModules.isEmpty) {
      return ValidationResult.failure(
        'No valid modules selected. Valid IDs are: ${EduXModules.allIds.join(", ")}',
      );
    }

    if (validModules.length > EduXModules.allIds.length) {
      return ValidationResult.failure(
        'Too many modules: max ${EduXModules.allIds.length}',
      );
    }

    // Check for duplicates
    if (validModules.toSet().length != validModules.length) {
      return const ValidationResult.failure('Duplicate module IDs detected');
    }

    return const ValidationResult.success();
  }

  // ============================================================
  // EXPIRY DATE VALIDATION
  // ============================================================

  /// Validate that an expiry date is in the future
  ValidationResult validateExpiryDate(DateTime expiryDate) {
    final now = DateTime.now();

    if (expiryDate.isBefore(now)) {
      return const ValidationResult.failure(
        'Expiry date must be in the future',
      );
    }

    // Max 10 years from now
    final maxDate = now.add(const Duration(days: 3650));
    if (expiryDate.isAfter(maxDate)) {
      return const ValidationResult.failure(
        'Expiry date cannot be more than 10 years from now',
      );
    }

    return const ValidationResult.success();
  }

  // ============================================================
  // STATUS TRANSITION VALIDATION (State Machine)
  // ============================================================

  /// Valid status transitions:
  /// - pending → approved
  /// - pending → rejected
  /// No other transitions are allowed.
  ValidationResult validateRequestTransition(
    String currentStatus,
    String targetStatus,
  ) {
    if (currentStatus == targetStatus) {
      return ValidationResult.failure('Request is already "$currentStatus"');
    }

    const allowedTransitions = {
      RequestStatus.pending: [RequestStatus.approved, RequestStatus.rejected],
    };

    final allowed = allowedTransitions[currentStatus];
    if (allowed == null) {
      return ValidationResult.failure(
        'Cannot transition from "$currentStatus" — request is finalized',
      );
    }

    if (!allowed.contains(targetStatus)) {
      return ValidationResult.failure(
        'Cannot transition from "$currentStatus" to "$targetStatus"',
      );
    }

    return const ValidationResult.success();
  }

  // ============================================================
  // COMPOUND VALIDATIONS
  // ============================================================

  /// Validate all parameters for granting/approving a license
  ValidationResult validateLicenseGrant({
    required String schoolId,
    required List<String> modules,
    required DateTime expiryDate,
    required String adminUid,
  }) {
    if (schoolId.trim().isEmpty) {
      return const ValidationResult.failure('School ID is required');
    }

    if (adminUid.trim().isEmpty) {
      return const ValidationResult.failure('Admin UID is required');
    }

    final moduleResult = validateModules(modules);
    if (!moduleResult.isValid) return moduleResult;

    final expiryResult = validateExpiryDate(expiryDate);
    if (!expiryResult.isValid) return expiryResult;

    return const ValidationResult.success();
  }

  /// Validate parameters for rejecting a request
  ValidationResult validateRejection({
    required String requestId,
    required String adminUid,
    String? rejectionReason,
  }) {
    if (requestId.trim().isEmpty) {
      return const ValidationResult.failure('Request ID is required');
    }

    if (adminUid.trim().isEmpty) {
      return const ValidationResult.failure('Admin UID is required');
    }

    // Rejection reason is optional but if provided, must be meaningful
    if (rejectionReason != null &&
        rejectionReason.trim().isNotEmpty &&
        rejectionReason.trim().length < 3) {
      return const ValidationResult.failure(
        'Rejection reason must be at least 3 characters',
      );
    }

    return const ValidationResult.success();
  }

  /// Validate license extension parameters
  ValidationResult validateLicenseExtension({
    required String schoolId,
    required DateTime newExpiryDate,
    required DateTime currentExpiryDate,
  }) {
    if (schoolId.trim().isEmpty) {
      return const ValidationResult.failure('School ID is required');
    }

    final expiryResult = validateExpiryDate(newExpiryDate);
    if (!expiryResult.isValid) return expiryResult;

    if (newExpiryDate.isBefore(currentExpiryDate)) {
      return const ValidationResult.failure(
        'New expiry date must be after the current expiry date',
      );
    }

    return const ValidationResult.success();
  }
}
