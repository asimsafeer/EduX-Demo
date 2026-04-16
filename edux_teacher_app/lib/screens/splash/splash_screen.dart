/// EduX Teacher App - Splash Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Splash screen shown while app initializes
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black .withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school,
                size: 64,
                color: AppTheme.primary,
              ),
            )
                .animate()
                .scale(
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(),

            const SizedBox(height: 32),

            // App name
            Text(
              'EduX Teacher',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Attendance Made Simple',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white .withValues(alpha: 0.8),
                  ),
            )
                .animate()
                .fadeIn(delay: 500.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 48),

            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white .withValues(alpha: 0.8),
              ),
              strokeWidth: 3,
            )
                .animate()
                .fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}
