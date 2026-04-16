/// EduX School Management System
/// Users Provider - Manages user list state
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../services/services.dart';

/// User service provider (singleton)
final userServiceProvider = Provider<UserService>((ref) {
  return UserService.instance();
});

/// User list filter state
class UserListFilter {
  final String? role;
  final bool? isActive;
  final String searchQuery;

  const UserListFilter({this.role, this.isActive, this.searchQuery = ''});

  UserListFilter copyWith({String? role, bool? isActive, String? searchQuery}) {
    return UserListFilter(
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Clear all filters
  UserListFilter clear() => const UserListFilter();
}

/// User list filter provider
final userListFilterProvider = StateProvider<UserListFilter>((ref) {
  return const UserListFilter();
});

/// User list provider with filtering
final userListProvider = FutureProvider<List<User>>((ref) async {
  final filter = ref.watch(userListFilterProvider);
  final userService = ref.watch(userServiceProvider);

  return await userService.getUsers(
    role: filter.role,
    isActive: filter.isActive,
    searchQuery: filter.searchQuery.isNotEmpty ? filter.searchQuery : null,
  );
});

/// Single user provider by ID
final userByIdProvider = FutureProvider.family<User?, int>((ref, id) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getUserById(id);
});

/// User count by role providers
final adminCountProvider = FutureProvider<int>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getUserCountByRole('admin');
});

final principalCountProvider = FutureProvider<int>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getUserCountByRole('principal');
});

final teacherCountProvider = FutureProvider<int>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getUserCountByRole('teacher');
});

final accountantCountProvider = FutureProvider<int>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getUserCountByRole('accountant');
});

final totalUserCountProvider = FutureProvider<int>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getActiveUserCount();
});
