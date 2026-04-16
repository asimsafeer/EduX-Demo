/// EduX School Management System
/// Authentication Provider - Manages authentication state
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../services/services.dart';
import '../services/rbac_service.dart';

/// Auth service provider (singleton)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance();
});

/// Activity log service provider (singleton)
final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService.instance();
});

/// Current user state notifier
class CurrentUserNotifier extends StateNotifier<User?> {
  final AuthService _authService;
  final ActivityLogService _activityLogService;

  CurrentUserNotifier(this._authService, this._activityLogService)
    : super(null);

  /// Initialize by checking for saved session
  Future<void> initialize() async {
    final user = await _authService.restoreSession();
    if (user != null) {
      state = user;
      await _activityLogService.logSessionRestore(user.id, user.username);
    }
  }

  /// Login with credentials
  Future<LoginResult> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      final user = await _authService.login(username, password);
      if (user == null) {
        return LoginResult.failure('Invalid username or password');
      }

      state = user;

      // Save session if remember me is enabled
      if (rememberMe) {
        await _authService.saveSession(user.id);
      }

      // Log the login
      await _activityLogService.logLogin(user.id, user.username);

      return LoginResult.success(user);
    } catch (e) {
      return LoginResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    final currentUser = state;
    if (currentUser != null) {
      await _activityLogService.logLogout(currentUser.id, currentUser.username);
    }

    await _authService.clearSession();
    state = null;
  }

  /// Check if user is logged in
  bool get isLoggedIn => state != null;

  /// Get current user ID
  int? get currentUserId => state?.id;
}

/// Current user provider
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  final activityLogService = ref.watch(activityLogServiceProvider);
  return CurrentUserNotifier(authService, activityLogService);
});

/// Login result class
class LoginResult {
  final bool success;
  final User? user;
  final String? error;

  LoginResult._({required this.success, this.user, this.error});

  factory LoginResult.success(User user) =>
      LoginResult._(success: true, user: user);
  factory LoginResult.failure(String error) =>
      LoginResult._(success: false, error: error);
}

/// Permission provider for role-based access
/// Permission provider for role-based access
final permissionsProvider = Provider<Permissions>((ref) {
  final user = ref.watch(currentUserProvider);
  final authService = ref.watch(authServiceProvider);
  final rbacService = ref.watch(rbacServiceProvider);
  return Permissions(user, authService, rbacService);
});

/// Permission helper class
class Permissions {
  final User? _user;
  final AuthService _authService;
  final RbacService _rbacService;

  Permissions(this._user, this._authService, this._rbacService);

  bool get isLoggedIn => _user != null;

  // Role checks (keep using AuthService for now or move to RbacService if needed)
  bool get isAdmin => _user != null && _authService.isAdmin(_user);
  bool get isPrincipal => _user != null && _authService.isPrincipal(_user);
  bool get isTeacher => _user != null && _authService.isTeacher(_user);
  bool get isAccountant => _user != null && _authService.isAccountant(_user);

  // Permission checks using RbacService
  bool get canAccessSettings =>
      _rbacService.hasPermission(_user, RbacService.viewSettings);

  bool get canManageUsers =>
      _rbacService.hasPermission(_user, RbacService.manageUsers);

  bool get canAccessStudents =>
      _rbacService.hasPermission(_user, RbacService.viewStudents);

  bool get canEditStudents =>
      _rbacService.hasPermission(_user, RbacService.manageStudents);

  bool get canAccessFees =>
      _rbacService.hasPermission(_user, RbacService.viewFees);

  bool get canMarkAttendance =>
      _rbacService.hasPermission(_user, RbacService.manageAttendance);

  bool get canEnterMarks =>
      _rbacService.hasPermission(_user, RbacService.manageExams);

  bool get canManageStaff =>
      _rbacService.hasPermission(_user, RbacService.manageStaff);

  bool get canViewReports =>
      _rbacService.hasPermission(_user, RbacService.viewReports);

  bool get canManageBackups => _rbacService.hasPermission(
    _user,
    RbacService.manageSettings,
  ); // Assuming backups is part of settings management

  /// Get user role display name
  String get roleDisplayName {
    if (_user == null) return 'Guest';
    return UserService.getRoleDisplayName(_user.role);
  }
}
