/// EduX School Management System
/// Main Application Entry Point
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/core.dart';
import 'core/demo/demo_seed.dart';
import 'core/demo/demo_watermark.dart';
import 'database/database.dart';
import 'router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/settings/services/print_settings_service.dart';

/// Application entry point
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = AppDatabase.instance;

  // Seed demo data if needed (idempotent)
  await DemoSeed.seedIfNeeded(database);

  // Setup global error handling
  final errorLogger = ErrorLogger(database);
  ErrorLogger.setupFlutterErrorHandling(errorLogger);

  // Initialize desktop window settings
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await _initializeDesktopWindow();
  }

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Run the application
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const EduXApp(),
    ),
  );
}

/// Initialize desktop window settings
Future<void> _initializeDesktopWindow() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(
      AppConstants.windowDefaultWidth,
      AppConstants.windowDefaultHeight,
    ),
    minimumSize: Size(
      AppConstants.windowMinWidth,
      AppConstants.windowMinHeight,
    ),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: DemoConfig.isDemo
        ? '${AppConstants.appFullName} - DEMO'
        : AppConstants.appFullName,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Main application widget
class EduXApp extends ConsumerWidget {
  const EduXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: DemoConfig.isDemo
          ? '${AppConstants.appFullName} - DEMO'
          : AppConstants.appFullName,
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,

      // Router configuration
      routerConfig: AppRouter.router,

      // Builder for global overlays
      builder: (context, child) {
        return MediaQuery(
          // Prevent system text scaling from affecting app layout
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: DemoWatermark(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
