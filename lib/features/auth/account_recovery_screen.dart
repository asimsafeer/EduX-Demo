/// EduX School Management System
/// Account Recovery Screen
/// Combined Forgot Password + Forgot Username with SegmentedButton toggle
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/core.dart';
import '../../router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../providers/providers.dart';
import '../../services/user_service.dart';

enum _RecoveryMode { password, username }

class AccountRecoveryScreen extends ConsumerStatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  ConsumerState<AccountRecoveryScreen> createState() =>
      _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends ConsumerState<AccountRecoveryScreen> {
  _RecoveryMode _mode = _RecoveryMode.password;

  // Shared
  final _formKey = GlobalKey<FormState>();
  final _masterKeyController = TextEditingController();
  bool _isLoading = false;
  bool _obscureMasterKey = true;
  String? _errorMessage;

  // Password reset
  final _resetFormKey = GlobalKey<FormState>();
  final _identityController = TextEditingController(); // username or email
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isVerified = false;
  bool _isPasswordResetSuccess = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int? _verifiedUserId;

  // Username recovery
  final _recoveryEmailController = TextEditingController();
  bool _isUsernameRecovered = false;
  String? _recoveredUsername;

  static const String _masterKey = 'R13x19zn6gj2264388';

  @override
  void dispose() {
    _masterKeyController.dispose();
    _identityController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _recoveryEmailController.dispose();
    super.dispose();
  }

  void _switchMode(_RecoveryMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _isLoading = false;
      // Reset password flow
      _isVerified = false;
      _isPasswordResetSuccess = false;
      _verifiedUserId = null;
      _identityController.clear();
      _masterKeyController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      // Reset username flow
      _isUsernameRecovered = false;
      _recoveredUsername = null;
      _recoveryEmailController.clear();
    });
  }

  // ============================================
  // PASSWORD RESET FLOW
  // ============================================

  Future<void> _handlePasswordVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_masterKeyController.text.trim() != _masterKey) {
        throw Exception('Invalid Master Key');
      }

      final identity = _identityController.text.trim();
      final userService = UserService.instance();
      final users = await userService.getUsers(searchQuery: identity);

      User? user = users.cast<User?>().firstWhere(
        (u) =>
            u?.email?.toLowerCase() == identity.toLowerCase() ||
            u?.username.toLowerCase() == identity.toLowerCase(),
        orElse: () => null,
      );

      // Fallback for Admin: Check if identity matches the School Settings email
      if (user == null && identity.contains('@')) {
        final settingsService = ref.read(schoolSettingsServiceProvider);
        final settings = await settingsService.getSettings();
        if (settings?.email?.toLowerCase() == identity.toLowerCase()) {
          // If it matches school email, assume they meant the primary admin
          final allUsers = await userService.getUsers(role: 'admin');
          if (allUsers.isNotEmpty) {
            user = allUsers.first; // Pick the first admin
          }
        }
      }

      if (user == null) {
        throw Exception('User not found');
      }

      setState(() {
        _verifiedUserId = user!.id;
        _isVerified = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    if (!_resetFormKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_verifiedUserId == null) throw Exception('User verification lost');

      final userService = UserService.instance();
      await userService.resetPassword(
        id: _verifiedUserId!,
        newPassword: _newPasswordController.text,
      );

      setState(() {
        _isLoading = false;
        _isPasswordResetSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ============================================
  // USERNAME RECOVERY FLOW
  // ============================================

  Future<void> _handleUsernameRecovery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_masterKeyController.text.trim() != _masterKey) {
        throw Exception('Invalid Master Key');
      }

      final email = _recoveryEmailController.text.trim();
      final userService = UserService.instance();
      final users = await userService.getUsers(searchQuery: email);

      User? user = users.cast<User?>().firstWhere(
        (u) => u?.email?.toLowerCase() == email.toLowerCase(),
        orElse: () => null,
      );

      // Fallback for Admin: Check if email matches the School Settings email
      if (user == null) {
        final settingsService = ref.read(schoolSettingsServiceProvider);
        final settings = await settingsService.getSettings();
        if (settings?.email?.toLowerCase() == email.toLowerCase()) {
          // If it matches school email, get the primary admin
          final allUsers = await userService.getUsers(role: 'admin');
          if (allUsers.isNotEmpty) {
            user = allUsers.first; // Pick the first admin
          }
        }
      }

      if (user == null) {
        throw Exception('No user found with that email');
      }

      setState(() {
        _recoveredUsername = user!.username;
        _isUsernameRecovered = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final isSuccess =
        (_mode == _RecoveryMode.password && _isPasswordResetSuccess) ||
        (_mode == _RecoveryMode.username && _isUsernameRecovered);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.go(AppRoutes.login),
                        icon: Icon(LucideIcons.arrowLeft),
                        tooltip: 'Back to Login',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              (isSuccess
                                      ? AppColors.success
                                      : AppColors.primary)
                                  .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSuccess
                              ? LucideIcons.checkCheck
                              : _mode == _RecoveryMode.password
                              ? LucideIcons.shieldAlert
                              : LucideIcons.searchCheck,
                          size: 48,
                          color: isSuccess
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      _buildTitle(),
                      style: AppTextStyles.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _buildDescription(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Mode toggle — only show when not in a success/verified state
                    if (!isSuccess && !_isVerified) ...[
                      SegmentedButton<_RecoveryMode>(
                        segments: const [
                          ButtonSegment(
                            value: _RecoveryMode.password,
                            label: Text('Reset Password'),
                            icon: Icon(LucideIcons.keyRound, size: 16),
                          ),
                          ButtonSegment(
                            value: _RecoveryMode.username,
                            label: Text('Find Username'),
                            icon: Icon(LucideIcons.user, size: 16),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selected) =>
                            _switchMode(selected.first),
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStatePropertyAll(
                            AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              size: 20,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Content
                    if (_mode == _RecoveryMode.password)
                      _buildPasswordContent()
                    else
                      _buildUsernameContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildTitle() {
    if (_mode == _RecoveryMode.password) {
      if (_isPasswordResetSuccess) return 'Password Reset Successful';
      if (_isVerified) return 'Set New Password';
      return 'Reset Password';
    } else {
      if (_isUsernameRecovered) return 'Username Found';
      return 'Recover Username';
    }
  }

  String _buildDescription() {
    if (_mode == _RecoveryMode.password) {
      if (_isPasswordResetSuccess) {
        return 'You can now login with your new password.';
      }
      if (_isVerified) return 'Please enter your new password below.';
      return 'Enter your credentials and master key to reset your password.';
    } else {
      if (_isUsernameRecovered) {
        return 'Your username has been recovered successfully.';
      }
      return 'Enter your email and master key to recover your username.';
    }
  }

  // ============================================
  // PASSWORD CONTENT
  // ============================================

  Widget _buildPasswordContent() {
    if (_isPasswordResetSuccess) {
      return AppButton.primary(
        text: 'Back to Login',
        onPressed: () => context.go(AppRoutes.login),
        isExpanded: true,
      );
    }

    if (_isVerified) {
      return Form(
        key: _resetFormKey,
        child: Column(
          children: [
            AppTextField(
              controller: _newPasswordController,
              label: 'New Password',
              obscureText: _obscureNewPassword,
              prefixIcon: LucideIcons.lock,
              suffixIcon: _obscureNewPassword
                  ? LucideIcons.eye
                  : LucideIcons.eyeOff,
              onSuffixTap: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
              validator: (v) {
                if (v == null || v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscureText: _obscureConfirmPassword,
              prefixIcon: LucideIcons.lock,
              suffixIcon: _obscureConfirmPassword
                  ? LucideIcons.eye
                  : LucideIcons.eyeOff,
              onSuffixTap: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              validator: (v) {
                if (v != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              text: 'Reset Password',
              onPressed: _handlePasswordReset,
              isLoading: _isLoading,
              isExpanded: true,
            ),
          ],
        ),
      );
    }

    // Verification form
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _identityController,
            label: 'Username or Email',
            prefixIcon: LucideIcons.user,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _masterKeyController,
            label: 'Master Key',
            prefixIcon: LucideIcons.shield,
            obscureText: _obscureMasterKey,
            suffixIcon: _obscureMasterKey
                ? LucideIcons.eye
                : LucideIcons.eyeOff,
            onSuffixTap: () =>
                setState(() => _obscureMasterKey = !_obscureMasterKey),
            onSubmitted: (_) => _handlePasswordVerification(),
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            text: 'Verify Identity',
            onPressed: _handlePasswordVerification,
            isLoading: _isLoading,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  // ============================================
  // USERNAME CONTENT
  // ============================================

  Widget _buildUsernameContent() {
    if (_isUsernameRecovered) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Your Username',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: SelectableText(
                        _recoveredUsername!,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        LucideIcons.copy,
                        size: 18,
                        color: AppColors.success,
                      ),
                      tooltip: 'Copy username',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _recoveredUsername!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Username copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            text: 'Back to Login',
            onPressed: () => context.go(AppRoutes.login),
            isExpanded: true,
          ),
        ],
      );
    }

    // Recovery form
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _recoveryEmailController,
            label: 'Email',
            prefixIcon: LucideIcons.mail,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _masterKeyController,
            label: 'Master Key',
            prefixIcon: LucideIcons.shield,
            obscureText: _obscureMasterKey,
            suffixIcon: _obscureMasterKey
                ? LucideIcons.eye
                : LucideIcons.eyeOff,
            onSuffixTap: () =>
                setState(() => _obscureMasterKey = !_obscureMasterKey),
            onSubmitted: (_) => _handleUsernameRecovery(),
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            text: 'Recover Username',
            onPressed: _handleUsernameRecovery,
            isLoading: _isLoading,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}
