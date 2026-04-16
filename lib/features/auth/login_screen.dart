/// EduX School Management System
/// Login Screen - User authentication with Riverpod
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';

/// Login screen for user authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  /// Check for existing session on startup
  Future<void> _checkExistingSession() async {
    final notifier = ref.read(currentUserProvider.notifier);
    await notifier.initialize();

    if (ref.read(currentUserProvider) != null && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate and perform login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(currentUserProvider.notifier)
          .login(
            _usernameController.text.trim(),
            _passwordController.text,
            rememberMe: _rememberMe,
          );

      if (!mounted) return;

      if (result.success) {
        context.go(AppRoutes.dashboard);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Login failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom title bar
          GestureDetector(
            onPanStart: (_) => windowManager.startDragging(),
            child: Container(
              height: 40,
              color: AppColors.sidebarBackground,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/icon.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildWindowButton(
                    icon: LucideIcons.minus,
                    onPressed: () => windowManager.minimize(),
                  ),
                  _buildWindowButton(
                    icon: LucideIcons.square,
                    onPressed: () async {
                      if (await windowManager.isMaximized()) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    },
                  ),
                  _buildWindowButton(
                    icon: LucideIcons.x,
                    onPressed: () => windowManager.close(),
                    isClose: true,
                  ),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(
            child: Row(
              children: [
                // Left side - branding
                Expanded(
                  flex: 5,
                  child: Container(
                    color: AppColors.primary,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.textOnPrimary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Welcome text
                            Text(
                              'Welcome to ${AppConstants.appName}',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textOnPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Complete School Management Solution',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textOnPrimary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),

                            // Feature bullets
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _buildFeatures(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Right side - login form
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                'Sign In',
                                style: AppTextStyles.headlineLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your credentials to continue',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Error message
                              if (_errorMessage != null) ...[
                                AppErrorMessage(
                                  message: _errorMessage!,
                                  onDismiss: () =>
                                      setState(() => _errorMessage = null),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Username field
                              AppTextField(
                                controller: _usernameController,
                                label: 'Username',
                                hint: 'Enter your username',
                                prefixIcon: Icons.person_outline,
                                enabled: !_isLoading,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password field
                              AppTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                enabled: !_isLoading,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleLogin(),
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixTap: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Remember me checkbox
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: _isLoading
                                            ? null
                                            : (value) {
                                                setState(
                                                  () => _rememberMe =
                                                      value ?? false,
                                                );
                                              },
                                      ),
                                      GestureDetector(
                                        onTap: _isLoading
                                            ? null
                                            : () => setState(
                                                () =>
                                                    _rememberMe = !_rememberMe,
                                              ),
                                        child: Text(
                                          'Remember me',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => context.go(
                                            AppRoutes.accountRecovery,
                                          ),
                                    child: Text(
                                      'Need Help?',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Login button
                              AppButton.primary(
                                text: 'Sign In',
                                isLoading: _isLoading,
                                isExpanded: true,
                                size: AppButtonSize.large,
                                onPressed: _handleLogin,
                              ),
                              const SizedBox(height: 24),

                              // Demo credentials hint
                              if (DemoConfig.isDemo) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.info.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.info,
                                        size: 16,
                                        color: AppColors.info,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Demo Credentials:  ${DemoConfig.demoUsername} / ${DemoConfig.demoPassword}',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.info,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Version info
                              Center(
                                child: Text(
                                  'Version ${AppConstants.appVersion}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isClose = false,
  }) {
    return _WindowButton(icon: icon, onPressed: onPressed, isClose: isClose);
  }

  List<Widget> _buildFeatures() {
    final features = [
      'Student & Staff Management',
      'Attendance Tracking',
      'Fee Collection & Invoicing',
      'Examination & Results',
      'Reports & Analytics',
    ];

    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              feature,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 40,
          color: _isHovered
              ? (widget.isClose
                    ? Colors.red
                    : Colors.white.withValues(alpha: 0.1))
              : Colors.transparent,
          child: Icon(widget.icon, size: 16, color: AppColors.textOnDark),
        ),
      ),
    );
  }
}
