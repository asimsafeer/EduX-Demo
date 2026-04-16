/// NovaByte Hub — Application Router
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/requests/requests_screen.dart';
import '../screens/requests/request_detail_screen.dart';
import '../screens/schools/schools_screen.dart';
import '../screens/schools/school_detail_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Route path constants
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String requests = '/requests';
  static const String requestDetail = '/requests/:id';
  static const String schools = '/schools';
  static const String schoolDetail = '/schools/:id';
  static const String settings = '/settings';
}

/// Global navigator key
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );

      final isLoginRoute = state.uri.path == AppRoutes.login;

      // If not authenticated and not on login page → redirect to login
      if (!isAuthenticated && !isLoginRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on login page → redirect to dashboard
      if (isAuthenticated && isLoginRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // Login screen (no shell)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Dashboard tab
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),

          // Requests tab
          GoRoute(
            path: AppRoutes.requests,
            name: 'requests',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RequestsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'request-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return RequestDetailScreen(requestId: id);
                },
              ),
            ],
          ),

          // Schools tab
          GoRoute(
            path: AppRoutes.schools,
            name: 'schools',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SchoolsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'school-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return SchoolDetailScreen(schoolId: id);
                },
              ),
            ],
          ),

          // Settings tab
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
