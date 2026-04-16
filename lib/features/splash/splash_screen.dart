/// EduX School Management System
/// Splash Screen - Initial loading screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/core.dart';
import '../../database/database.dart';
import '../../router/app_router.dart';
import '../../services/license_service.dart';

/// Splash screen shown on app startup
/// Initializes database and determines navigation destination
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize the app and navigate to appropriate screen
  Future<void> _initializeApp() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });

      // Wait for animation to play
      await Future.delayed(const Duration(milliseconds: 2000));

      // Demo mode: skip setup wizard and license checks
      if (DemoConfig.isDemo) {
        if (mounted) context.go(AppRoutes.login);
        return;
      }

      // Check if school is set up FIRST (before license checks)
      final db = AppDatabase.instance;
      final isSetup = await db.isSchoolSetup();

      if (!isSetup) {
        // Fresh install - School not set up, go to setup wizard
        if (mounted) {
          context.go(AppRoutes.setup);
        }
        return;
      }

      // School is set up - Now check license status
      final licenseService = LicenseService.instance;

      final appStatus = await licenseService.getAppStatus();

      if (!mounted) return;

      // Route based on license status
      switch (appStatus) {
        case AppLicenseStatus.expired:
          // Expired — go to license request screen
          context.go(AppRoutes.requestLicense);
          return;
        case AppLicenseStatus.pendingRequest:
          // Pending — still allow access to dashboard while waiting for approval
          break;
        case AppLicenseStatus.licensed:
          // Licensed — check for admin user
          break;
      }

      // Verify we have an admin user
      final adminUser = await db.getAdminUser();

      if (!mounted) return;

      if (adminUser == null) {
        // Inconsistent state: Setup marked complete but no admin user found
        debugPrint(
          'Inconsistent state: Setup complete but no admin user. Resetting...',
        );
        await db.resetSchoolSettings();
        if (mounted) {
          context.go(AppRoutes.setup);
        }
      } else {
        // School is set up, has admin, and has valid license - go to login
        context.go(AppRoutes.login);
      }
    } catch (e, stackTrace) {
      debugPrint('=== INITIALIZATION ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace:\n$stackTrace');
      debugPrint('=== END ERROR ===');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Main Content (Centered)
          Center(
            child: _hasError
                ? _buildErrorView()
                : AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App logo/icon
                        Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.textOnPrimary,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(
                              duration: 2.seconds,
                              color: Colors.white24,
                            ),

                        const SizedBox(height: 24),

                        // App name
                        Text(
                          AppConstants.appName,
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tagline
                        Text(
                          'School Management System',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textOnPrimary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Loading indicator
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textOnPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Nova Byte Branding (Bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: size.height * 0.05, // 5% of screen height
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Powered by',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo with subtle shadow and rounded corners
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/novabyte_logo.jpg',
                          height: 36,
                          width: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text with high visibility and professional styling
                    Text(
                      'NOVA BYTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textOnPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Initialization Failed',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'An error occurred while starting the application.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _initializeApp,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textOnPrimary,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
