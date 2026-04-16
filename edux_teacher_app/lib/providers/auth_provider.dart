/// EduX Teacher App - Auth Provider
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../database/app_database.dart';
import '../models/teacher.dart';
import '../services/device_service.dart';
import '../services/sync_service.dart';
import 'database_provider.dart';

part 'auth_provider.g.dart';

/// Auth state
class AuthState {
  final Teacher? teacher;
  final bool isLoading;
  final String? error;
  final bool isInitializing;

  const AuthState({
    this.teacher,
    this.isLoading = false,
    this.error,
    this.isInitializing = true,
  });

  AuthState copyWith({
    Teacher? teacher,
    bool? isLoading,
    String? error,
    bool? isInitializing,
  }) {
    return AuthState(
      teacher: teacher ?? this.teacher,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }

  bool get isAuthenticated => teacher != null;
}

/// Auth provider
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  late AppDatabase _db;
  late DeviceService _deviceService;

  @override
  AuthState build() {
    _db = ref.read(databaseProvider);
    _deviceService = ref.read(deviceServiceProvider);

    // Check auth status on init
    _checkAuthStatus();

    return const AuthState(isInitializing: true);
  }

  /// Check stored auth status
  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await _deviceService.isAuthenticated();

      if (isAuth) {
        final teacherId =
            int.tryParse(await _db.getConfig(ConfigKeys.teacherId) ?? '0') ?? 0;
        final teacherName = await _db.getConfig(ConfigKeys.teacherName) ?? '';
        final teacherEmail = await _db.getConfig(ConfigKeys.teacherEmail) ?? '';
        final teacherPhoto = await _db.getConfig(ConfigKeys.teacherPhoto);

        state = AuthState(
          teacher: Teacher(
            id: teacherId,
            name: teacherName,
            email: teacherEmail,
            photoUrl: teacherPhoto,
          ),
          isInitializing: false,
        );
      } else {
        state = const AuthState(isInitializing: false);
      }
    } catch (e) {
      state = AuthState(
        error: e.toString(),
        isInitializing: false,
      );
    }
  }

  /// Login
  Future<bool> login(
    String serverIp,
    int port,
    String username,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.initialize(serverIp, port);

      final deviceId = await _deviceService.getDeviceId();
      final deviceName = await _deviceService.getDeviceName();

      final teacher = await syncService.login(
        username,
        password,
        deviceId,
        deviceName,
      );

      if (teacher != null) {
        // Save server config
        await _db.setConfig(ConfigKeys.serverIp, serverIp);
        await _db.setConfig(ConfigKeys.serverPort, port.toString());

        state = AuthState(
          teacher: teacher,
          isLoading: false,
          isInitializing: false,
        );
        return true;
      } else {
        state = AuthState(
          isLoading: false,
          error: 'Invalid username or password',
          isInitializing: false,
        );
        return false;
      }
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: e.toString(),
        isInitializing: false,
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _deviceService.logout();
      state = const AuthState(isLoading: false, isInitializing: false);
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: e.toString(),
        isInitializing: false,
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Device service provider
@Riverpod(keepAlive: true)
DeviceService deviceService(Ref ref) {
  final db = ref.watch(databaseProvider);
  return DeviceService(db);
}

/// Sync service provider
@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db);
}

/// Current teacher provider (convenience)
@Riverpod(keepAlive: true)
Teacher? currentTeacher(Ref ref) {
  return ref.watch(authProvider).teacher;
}

/// Is authenticated provider (convenience)
@Riverpod(keepAlive: true)
bool isAuthenticated(Ref ref) {
  return ref.watch(authProvider).isAuthenticated;
}
