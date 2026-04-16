/// EduX School Management System
/// User Service - Handles user CRUD operations
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/demo/demo_config.dart';
import '../database/database.dart';
import 'auth_service.dart';

/// User management service for CRUD operations
class UserService {
  final AppDatabase _db;
  final AuthService _authService;
  static const _uuid = Uuid();

  UserService(this._db, this._authService);

  /// Factory constructor using singleton instances
  factory UserService.instance() =>
      UserService(AppDatabase.instance, AuthService.instance());

  // ============================================
  // USER QUERIES
  // ============================================

  /// Get all users with optional filters
  Future<List<User>> getUsers({
    String? role,
    bool? isActive,
    String? searchQuery,
  }) async {
    var query = _db.select(_db.users);

    // Apply filters
    if (role != null && role.isNotEmpty) {
      query = query..where((u) => u.role.lower().equals(role.toLowerCase()));
    }

    if (isActive != null) {
      query = query..where((u) => u.isActive.equals(isActive));
    }

    // Get all results first, then filter by search if needed
    var users = await query.get();

    // Apply search filter (case-insensitive on fullName and username)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final search = searchQuery.toLowerCase();
      users = users.where((u) {
        final matchName = u.fullName.toLowerCase().contains(search);
        final matchUsername = u.username.toLowerCase().contains(search);
        final matchEmail = u.email?.toLowerCase().contains(search) ?? false;
        return matchName || matchUsername || matchEmail;
      }).toList();
    }

    // Sort by full name
    users.sort((a, b) => a.fullName.compareTo(b.fullName));

    return users;
  }

  /// Get user by ID
  Future<User?> getUserById(int id) async {
    return await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  /// Get user by username
  Future<User?> getUserByUsername(String username) async {
    return await (_db.select(_db.users)
          ..where((u) => u.username.lower().equals(username.toLowerCase())))
        .getSingleOrNull();
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(
    String username, {
    int? excludeUserId,
  }) async {
    final existing = await getUserByUsername(username);
    if (existing == null) return true;
    if (excludeUserId != null && existing.id == excludeUserId) return true;
    return false;
  }

  /// Get user count by role
  Future<int> getUserCountByRole(String role) async {
    final count =
        await (_db.select(_db.users)
              ..where((u) => u.role.lower().equals(role.toLowerCase()))
              ..where((u) => u.isActive.equals(true)))
            .get();
    return count.length;
  }

  /// Get total active user count
  Future<int> getActiveUserCount() async {
    final count = await (_db.select(
      _db.users,
    )..where((u) => u.isActive.equals(true))).get();
    return count.length;
  }

  // ============================================
  // USER CRUD
  // ============================================

  /// Create a new user
  /// Returns the created user on success
  Future<User> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
    String? email,
    String? phone,
    String? permissions,
    int? staffId,
  }) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    // Validate username uniqueness
    if (!await isUsernameAvailable(username)) {
      throw Exception('Username "$username" is already taken');
    }

    // Validate password
    final passwordError = _authService.validatePassword(password);
    if (passwordError != null) {
      throw Exception(passwordError);
    }

    // Validate role
    if (!_isValidRole(role)) {
      throw Exception('Invalid role: $role');
    }

    // Generate password hash
    final salt = _authService.generateSalt();
    final passwordHash = _authService.hashPassword(password, salt);

    // Create user within a transaction if possible, or just sequentially
    final userId = await _db
        .into(_db.users)
        .insert(
          UsersCompanion.insert(
            uuid: _uuid.v4(),
            username: username.trim(),
            passwordHash: passwordHash,
            passwordSalt: salt,
            fullName: fullName.trim(),
            role: role,
            email: Value(email?.trim()),
            phone: Value(phone?.trim()),
            isActive: const Value(true),
            isSystemAdmin: const Value(false),
            permissions: Value(permissions),
          ),
        );

    // Link staff if provided
    if (staffId != null) {
      await (_db.update(_db.staff)..where((s) => s.id.equals(staffId))).write(
        StaffCompanion(userId: Value(userId)),
      );
    }

    return (await getUserById(userId))!;
  }

  /// Update user details (not password)
  Future<User> updateUser({
    required int id,
    required String fullName,
    required String role,
    String? email,
    String? phone,
    bool? isActive,
    String? permissions,
  }) async {
    // Verify user exists
    final existing = await getUserById(id);
    if (existing == null) {
      throw Exception('User not found');
    }

    // Prevent modifying system admin role
    if (existing.isSystemAdmin && role.toLowerCase() != 'admin') {
      throw Exception('Cannot change system administrator role');
    }

    // Validate role
    if (!_isValidRole(role)) {
      throw Exception('Invalid role: $role');
    }

    // Update user
    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        fullName: Value(fullName.trim()),
        role: Value(role),
        email: Value(email?.trim()),
        phone: Value(phone?.trim()),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
        permissions: Value(permissions),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return (await getUserById(id))!;
  }

  /// Update user's username
  Future<User> updateUsername({
    required int id,
    required String newUsername,
  }) async {
    // Verify user exists
    final existing = await getUserById(id);
    if (existing == null) {
      throw Exception('User not found');
    }

    // Validate username uniqueness
    if (!await isUsernameAvailable(newUsername, excludeUserId: id)) {
      throw Exception('Username "$newUsername" is already taken');
    }

    // Update username
    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        username: Value(newUsername.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return (await getUserById(id))!;
  }

  /// Reset user password
  Future<void> resetPassword({
    required int id,
    required String newPassword,
  }) async {
    // Verify user exists
    final existing = await getUserById(id);
    if (existing == null) {
      throw Exception('User not found');
    }

    // Validate password
    final passwordError = _authService.validatePassword(newPassword);
    if (passwordError != null) {
      throw Exception(passwordError);
    }

    // Generate new password hash
    final salt = _authService.generateSalt();
    final passwordHash = _authService.hashPassword(newPassword, salt);

    // Update password
    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        passwordHash: Value(passwordHash),
        passwordSalt: Value(salt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Toggle user active status
  Future<User> toggleUserActive(int id) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final existing = await getUserById(id);
    if (existing == null) {
      throw Exception('User not found');
    }

    // Prevent deactivating system admin
    if (existing.isSystemAdmin && existing.isActive) {
      throw Exception('Cannot deactivate system administrator');
    }

    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        isActive: Value(!existing.isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return (await getUserById(id))!;
  }

  /// Delete user (with validation)
  Future<void> deleteUser(int id) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final existing = await getUserById(id);
    if (existing == null) {
      throw Exception('User not found');
    }

    // Prevent deleting system admin
    if (existing.isSystemAdmin) {
      throw Exception('Cannot delete system administrator');
    }

    await (_db.delete(_db.users)..where((u) => u.id.equals(id))).go();
  }

  // ============================================
  // VALIDATION HELPERS
  // ============================================

  /// Valid user roles
  static const validRoles = ['admin', 'principal', 'teacher', 'accountant'];

  bool _isValidRole(String role) {
    return validRoles.contains(role.toLowerCase());
  }

  /// Get display name for role
  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'principal':
        return 'Principal';
      case 'teacher':
        return 'Teacher';
      case 'accountant':
        return 'Accountant';
      default:
        return role;
    }
  }
}
