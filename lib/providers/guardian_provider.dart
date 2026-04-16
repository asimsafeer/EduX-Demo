/// EduX School Management System
/// Guardian Provider - State management for guardian module
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../core/demo/demo_config.dart';
import '../database/app_database.dart';
import '../repositories/guardian_repository.dart';
import 'student_provider.dart';

// =============================================================================
// Repository Providers
// =============================================================================

/// Provides the guardian repository instance
final guardianRepositoryProvider = Provider<GuardianRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return GuardianRepositoryImpl(db);
});

// =============================================================================
// Guardian Data Providers
// =============================================================================

/// Fetches all guardians
final allGuardiansProvider = FutureProvider<List<Guardian>>((ref) async {
  final repo = ref.watch(guardianRepositoryProvider);
  return repo.getAll();
});

/// Fetches guardians for a specific student
final guardiansByStudentProvider =
    FutureProvider.family<List<StudentGuardianLink>, int>((
      ref,
      studentId,
    ) async {
      final repo = ref.watch(guardianRepositoryProvider);
      return repo.getByStudentId(studentId);
    });

/// Fetches a single guardian by ID
final guardianByIdProvider = FutureProvider.family<Guardian?, int>((
  ref,
  guardianId,
) async {
  final repo = ref.watch(guardianRepositoryProvider);
  return repo.getById(guardianId);
});

/// Fetches the primary guardian for a student
final primaryGuardianProvider = FutureProvider.family<Guardian?, int>((
  ref,
  studentId,
) async {
  final repo = ref.watch(guardianRepositoryProvider);
  return repo.getPrimaryGuardian(studentId);
});

/// Search guardians by query
final guardianSearchProvider = FutureProvider.family<List<Guardian>, String>((
  ref,
  query,
) async {
  final repo = ref.watch(guardianRepositoryProvider);
  return repo.search(query);
});

// =============================================================================
// Guardian Form Data
// =============================================================================

/// Data class for guardian form submission
class GuardianFormData {
  final String firstName;
  final String lastName;
  final String relation;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? cnic;
  final String? occupation;
  final String? workplace;
  final String? address;
  final String? city;

  const GuardianFormData({
    required this.firstName,
    required this.lastName,
    required this.relation,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.cnic,
    this.occupation,
    this.workplace,
    this.address,
    this.city,
  });

  /// Convert to Drift companion for insert/update
  GuardiansCompanion toCompanion() {
    return GuardiansCompanion(
      firstName: Value(firstName),
      lastName: Value(lastName),
      relation: Value(relation),
      phone: Value(phone),
      alternatePhone: Value(alternatePhone),
      email: Value(email),
      cnic: Value(cnic),
      occupation: Value(occupation),
      workplace: Value(workplace),
      address: Value(address),
      city: Value(city),
    );
  }
}

/// Link settings for a guardian-student relationship
class GuardianLinkSettings {
  final bool isPrimary;
  final bool canPickup;
  final bool isEmergencyContact;

  const GuardianLinkSettings({
    this.isPrimary = false,
    this.canPickup = true,
    this.isEmergencyContact = false,
  });
}

// =============================================================================
// Guardian Operation State and Notifier
// =============================================================================

/// State for guardian CRUD operations
class GuardianOperationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const GuardianOperationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  GuardianOperationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return GuardianOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Notifier for guardian operations
class GuardianOperationNotifier extends StateNotifier<GuardianOperationState> {
  final GuardianRepository _repository;
  final Ref _ref;

  GuardianOperationNotifier(this._repository, this._ref)
    : super(const GuardianOperationState());

  /// Create a new guardian
  Future<int?> createGuardian(GuardianFormData data) async {
    if (DemoConfig.isDemo) {
      state = state.copyWith(isLoading: false, error: DemoConfig.restrictionMessage);
      return null;
    }
    state = state.copyWith(isLoading: true);
    try {
      final companion = GuardiansCompanion.insert(
        uuid: DateTime.now().millisecondsSinceEpoch.toString(),
        firstName: data.firstName,
        lastName: data.lastName,
        relation: data.relation,
        phone: data.phone,
        alternatePhone: Value(data.alternatePhone),
        email: Value(data.email),
        cnic: Value(data.cnic),
        occupation: Value(data.occupation),
        workplace: Value(data.workplace),
        address: Value(data.address),
        city: Value(data.city),
      );

      final id = await _repository.create(companion);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Guardian created successfully',
      );
      _ref.invalidate(allGuardiansProvider);
      return id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create guardian: ${e.toString()}',
      );
      return null;
    }
  }

  /// Update an existing guardian
  Future<bool> updateGuardian(int id, GuardianFormData data) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _repository.update(id, data.toCompanion());
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Guardian updated successfully',
        );
        _ref.invalidate(allGuardiansProvider);
        _ref.invalidate(guardianByIdProvider(id));
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Guardian not found');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update guardian: ${e.toString()}',
      );
      return false;
    }
  }

  /// Delete a guardian
  Future<bool> deleteGuardian(int id) async {
    if (DemoConfig.isDemo) {
      state = state.copyWith(isLoading: false, error: DemoConfig.restrictionMessage);
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      final success = await _repository.delete(id);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Guardian deleted successfully',
        );
        _ref.invalidate(allGuardiansProvider);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Guardian not found');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete guardian: ${e.toString()}',
      );
      return false;
    }
  }

  /// Link a guardian to a student
  Future<bool> linkToStudent(
    int studentId,
    int guardianId,
    GuardianLinkSettings settings,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.linkToStudent(
        studentId,
        guardianId,
        isPrimary: settings.isPrimary,
        canPickup: settings.canPickup,
        isEmergencyContact: settings.isEmergencyContact,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Guardian linked successfully',
      );
      _ref.invalidate(guardiansByStudentProvider(studentId));
      _ref.invalidate(primaryGuardianProvider(studentId));
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to link guardian: ${e.toString()}',
      );
      return false;
    }
  }

  /// Unlink a guardian from a student
  Future<bool> unlinkFromStudent(int studentId, int guardianId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.unlinkFromStudent(studentId, guardianId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Guardian unlinked successfully',
      );
      _ref.invalidate(guardiansByStudentProvider(studentId));
      _ref.invalidate(primaryGuardianProvider(studentId));
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unlink guardian: ${e.toString()}',
      );
      return false;
    }
  }

  /// Set a guardian as primary for a student
  Future<bool> setPrimaryGuardian(int studentId, int guardianId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.setPrimaryGuardian(studentId, guardianId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Primary guardian updated',
      );
      _ref.invalidate(guardiansByStudentProvider(studentId));
      _ref.invalidate(primaryGuardianProvider(studentId));
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set primary guardian: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update link settings
  Future<bool> updateLinkSettings(
    int studentId,
    int guardianId,
    GuardianLinkSettings settings,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateLink(
        studentId,
        guardianId,
        isPrimary: settings.isPrimary,
        canPickup: settings.canPickup,
        isEmergencyContact: settings.isEmergencyContact,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Guardian settings updated',
      );
      _ref.invalidate(guardiansByStudentProvider(studentId));
      _ref.invalidate(primaryGuardianProvider(studentId));
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update guardian settings: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Provider for guardian operations
final guardianOperationProvider =
    StateNotifierProvider<GuardianOperationNotifier, GuardianOperationState>((
      ref,
    ) {
      final repository = ref.watch(guardianRepositoryProvider);
      return GuardianOperationNotifier(repository, ref);
    });
