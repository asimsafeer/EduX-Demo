/// EduX School Management System
/// Authentication Service - Handles user authentication and session management
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../core/constants/app_constants.dart';

/// Authentication service for user login, logout, and session management
class AuthService {
  final AppDatabase _db;
  static const String _sessionUserIdKey = 'session_user_id';
  static const String _sessionExpiryKey = 'session_expiry';
  static const int _sessionDurationDays = 30; // Remember me duration

  AuthService(this._db);

  /// Factory constructor using singleton database
  factory AuthService.instance() => AuthService(AppDatabase.instance);

  // ============================================
  // AUTHENTICATION METHODS
  // ============================================

  /// Attempt to login with username and password
  /// Returns the authenticated user on success, null on failure
  Future<User?> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return null;
    }

    // Find user by username (case-insensitive)
    final user =
        await (_db.select(_db.users)
              ..where((u) => u.username.lower().equals(username.toLowerCase()))
              ..where((u) => u.isActive.equals(true)))
            .getSingleOrNull();

    if (user == null) {
      return null;
    }

    // Verify password
    final hashedPassword = hashPassword(password, user.passwordSalt);
    if (hashedPassword != user.passwordHash) {
      return null;
    }

    // Update last login timestamp
    await (_db.update(_db.users)..where((u) => u.id.equals(user.id))).write(
      UsersCompanion(
        lastLogin: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return user;
  }

  /// Save session for "Remember Me" functionality
  Future<void> saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(Duration(days: _sessionDurationDays));

    await prefs.setInt(_sessionUserIdKey, userId);
    await prefs.setString(_sessionExpiryKey, expiry.toIso8601String());
  }

  /// Clear saved session (logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
    await prefs.remove(_sessionExpiryKey);
  }

  /// Restore session if valid
  /// Returns the user if session is valid and not expired
  Future<User?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt(_sessionUserIdKey);
    final expiryString = prefs.getString(_sessionExpiryKey);

    if (userId == null || expiryString == null) {
      return null;
    }

    // Check if session is expired
    final expiry = DateTime.tryParse(expiryString);
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      await clearSession();
      return null;
    }

    // Fetch user and verify still active
    final user =
        await (_db.select(_db.users)
              ..where((u) => u.id.equals(userId))
              ..where((u) => u.isActive.equals(true)))
            .getSingleOrNull();

    if (user == null) {
      await clearSession();
      return null;
    }

    return user;
  }

  /// Check if there's a valid saved session
  Future<bool> hasValidSession() async {
    final user = await restoreSession();
    return user != null;
  }

  // ============================================
  // PASSWORD UTILITIES
  // ============================================

  /// Generate a cryptographically secure salt
  String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  /// Hash a password with the given salt using SHA-256
  String hashPassword(String password, String salt) {
    final saltedPassword = password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate password strength
  /// Returns null if valid, error message if invalid
  String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (password.length > 100) {
      return 'Password must not exceed 100 characters';
    }
    // At least one letter and one number
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).+$').hasMatch(password)) {
      return 'Password must contain at least one letter and one number';
    }
    return null;
  }

  /// Validate password strength (for optional strong validation)
  String? validateStrongPassword(String password) {
    final basicError = validatePassword(password);
    if (basicError != null) return basicError;

    if (password.length < 8) {
      return 'Strong password must be at least 8 characters';
    }
    // At least one uppercase, one lowercase, one number
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(password)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    return null;
  }

  // ============================================
  // USER LOOKUP
  // ============================================

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

  // ============================================
  // PERMISSION CHECKS
  // ============================================

  /// Check if user has admin role
  bool isAdmin(User user) => user.role.toLowerCase() == UserRoles.admin;

  /// Check if user has principal role
  bool isPrincipal(User user) => user.role.toLowerCase() == UserRoles.principal;

  /// Check if user has teacher role
  bool isTeacher(User user) => user.role.toLowerCase() == UserRoles.teacher;

  /// Check if user has accountant role
  bool isAccountant(User user) =>
      user.role.toLowerCase() == UserRoles.accountant;

  /// Check if user can access settings (admin only)
  @Deprecated('Use RbacService.hasPermission(user, RbacService.viewSettings)')
  bool canAccessSettings(User user) => isAdmin(user);

  /// Check if user can manage users (admin only)
  @Deprecated('Use RbacService.hasPermission(user, RbacService.manageUsers)')
  bool canManageUsers(User user) => isAdmin(user);

  /// Check if user can access students
  @Deprecated('Use RbacService.hasPermission(user, RbacService.viewStudents)')
  bool canAccessStudents(User user) =>
      isAdmin(user) || isPrincipal(user) || isTeacher(user);

  /// Check if user can edit students
  @Deprecated('Use RbacService.hasPermission(user, RbacService.manageStudents)')
  bool canEditStudents(User user) => isAdmin(user) || isPrincipal(user);

  /// Check if user can access fees
  @Deprecated('Use RbacService.hasPermission(user, RbacService.viewFees)')
  bool canAccessFees(User user) =>
      isAdmin(user) || isPrincipal(user) || isAccountant(user);

  /// Check if user can mark attendance
  @Deprecated(
    'Use RbacService.hasPermission(user, RbacService.manageAttendance)',
  )
  bool canMarkAttendance(User user) =>
      isAdmin(user) || isPrincipal(user) || isTeacher(user);

  /// Check if user can enter marks
  @Deprecated('Use RbacService.hasPermission(user, RbacService.manageExams)')
  bool canEnterMarks(User user) =>
      isAdmin(user) || isPrincipal(user) || isTeacher(user);

  /// Check if user can manage staff
  @Deprecated('Use RbacService.hasPermission(user, RbacService.manageStaff)')
  bool canManageStaff(User user) => isAdmin(user) || isPrincipal(user);

  /// Check if user can view reports
  @Deprecated('Use RbacService.hasPermission(user, RbacService.viewReports)')
  bool canViewReports(User user) =>
      isAdmin(user) || isPrincipal(user) || isAccountant(user);

  /// Check if user can manage backups
  @Deprecated('Use RbacService.hasPermission(user, RbacService.manageSettings)')
  bool canManageBackups(User user) => isAdmin(user);
}
