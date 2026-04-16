/// EduX School Management System
/// School Setup Wizard - Initial school configuration
library;

import 'dart:convert';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/core.dart';
import '../../database/database.dart';
import '../../router/app_router.dart';
import '../../services/license_service.dart';

/// School setup wizard for initial configuration
class SchoolSetupScreen extends StatefulWidget {
  const SchoolSetupScreen({super.key});

  @override
  State<SchoolSetupScreen> createState() => _SchoolSetupScreenState();
}

class _SchoolSetupScreenState extends State<SchoolSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Institution Type
  String _institutionType = 'School';
  final _institutionTypes = ['School', 'College', 'Institute', 'Academy'];

  // School info controllers
  final _schoolNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _principalController = TextEditingController();

  // Bank details controllers
  final _bankNameController = TextEditingController();
  final _accountTitleController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _onlinePaymentInfoController = TextEditingController();

  // Admin user controllers
  final _adminNameController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _principalController.dispose();
    _bankNameController.dispose();
    _accountTitleController.dispose();
    _accountNumberController.dispose();
    _onlinePaymentInfoController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
    super.dispose();
  }

  /// Move to next step
  void _nextStep() {
    if (_currentStep == 0) {
      // Validate school info
      if (_schoolNameController.text.trim().isEmpty) {
        context.showErrorSnackBar('Please enter the $_institutionType name');
        return;
      }
    }

    if (_currentStep < 1) {
      setState(() => _currentStep++);
    } else {
      _completeSetup();
    }
  }

  /// Move to previous step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  /// Complete setup and save data
  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate passwords match
    if (_adminPasswordController.text != _adminConfirmPasswordController.text) {
      context.showErrorSnackBar('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = AppDatabase.instance;
      final licenseService = LicenseService.instance;

      // Generate School ID and start trial
      final schoolId = await licenseService.generateSchoolId();
      await licenseService.recordInstallDate();
      await licenseService.saveSchoolName(_schoolNameController.text.trim());

      await db.transaction(() async {
        // Create school settings
        await db
            .into(db.schoolSettings)
            .insert(
              SchoolSettingsCompanion.insert(
                schoolName: _schoolNameController.text.trim(),
                institutionType: Value(_institutionType),
                address: Value(_addressController.text.trim().orNullIfEmpty()),
                city: Value(_cityController.text.trim().orNullIfEmpty()),
                phone: Value(_phoneController.text.trim().orNullIfEmpty()),
                email: Value(_emailController.text.trim().orNullIfEmpty()),
                principalName: Value(
                  _principalController.text.trim().orNullIfEmpty(),
                ),
                isSetupComplete: const Value(true),
                bankName: Value(
                  _bankNameController.text.trim().orNullIfEmpty(),
                ),
                accountTitle: Value(
                  _accountTitleController.text.trim().orNullIfEmpty(),
                ),
                accountNumber: Value(
                  _accountNumberController.text.trim().orNullIfEmpty(),
                ),
                onlinePaymentInfo: Value(
                  _onlinePaymentInfoController.text.trim().orNullIfEmpty(),
                ),
              ),
            );

        // Create academic year
        final now = DateTime.now();
        final academicYearStart = now.month >= 4
            ? DateTime(now.year, 4, 1)
            : DateTime(now.year - 1, 4, 1);
        final academicYearEnd = DateTime(academicYearStart.year + 1, 3, 31);
        final academicYearName =
            '${academicYearStart.year}-${academicYearEnd.year}';

        await db
            .into(db.academicYears)
            .insert(
              AcademicYearsCompanion.insert(
                name: academicYearName,
                startDate: academicYearStart,
                endDate: academicYearEnd,
                isCurrent: const Value(true),
              ),
            );

        // Create admin user
        const uuid = Uuid();
        final salt = uuid.v4();
        final passwordHash = sha256
            .convert(utf8.encode(_adminPasswordController.text + salt))
            .toString();

        await db
            .into(db.users)
            .insert(
              UsersCompanion.insert(
                uuid: uuid.v4(),
                username: _adminUsernameController.text.trim(),
                passwordHash: passwordHash,
                passwordSalt: salt,
                fullName: _adminNameController.text.trim(),
                email: Value(_adminEmailController.text.trim()),
                role: UserRoles.admin,
                isActive: const Value(true),
                isSystemAdmin: const Value(true),
              ),
            );
      });

      // Register school in Firestore (non-blocking — failure is OK)
      try {
        await licenseService.registerSchoolInFirestore(
          schoolId: schoolId,
          schoolName: _schoolNameController.text.trim(),
          city: _cityController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
        );
      } catch (_) {
        // Firestore registration failed — this is fine for offline setup
      }

      if (mounted) {
        setState(() => _isLoading = false);

        // Show success dialog with School ID, then go to license request
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Setup Complete! 🎉'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_institutionType has been set up successfully.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your School ID',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        schoolId,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Save this ID — you\'ll need it to request a license.\n'
                  'Next, request your license to activate the application modules.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text('Request License'),
              ),
            ],
          ),
        );

        // Navigate to license request after dialog is dismissed
        if (mounted) {
          context.go(AppRoutes.requestLicense);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        context.showErrorSnackBar(
          'Failed to complete setup. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left side - branding
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.primary,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      Text(
                        'Welcome to ${AppConstants.appName}',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Let's get your school set up",
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Step indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepIndicator(0, 'School Info'),
                          Container(
                            width: 40,
                            height: 2,
                            color: AppColors.textOnPrimary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          _buildStepIndicator(1, 'Admin Account'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right side - form
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentStep == 0
                          ? _buildSchoolInfoStep()
                          : _buildAdminAccountStep(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.textOnPrimary : Colors.transparent,
            border: Border.all(color: AppColors.textOnPrimary, width: 2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolInfoStep() {
    return Column(
      key: const ValueKey('school-info'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$_institutionType Information',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your ${_institutionType.toLowerCase()} details to get started',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),

        DropdownButtonFormField<String>(
          initialValue: _institutionType,
          decoration: const InputDecoration(
            labelText: 'Institution Type',
            prefixIcon: Icon(Icons.business),
          ),
          items: _institutionTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _institutionType = value);
            }
          },
        ),
        const SizedBox(height: 20),

        AppTextField(
          controller: _schoolNameController,
          label: '$_institutionType Name *',
          hint: 'Enter ${_institutionType.toLowerCase()} name',
          prefixIcon: Icons.school_outlined,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$_institutionType name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        AppTextField(
          controller: _principalController,
          label: 'Principal Name',
          hint: 'Enter principal name',
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),

        AppTextField(
          controller: _addressController,
          label: 'Address',
          hint: 'Enter school address',
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _cityController,
                label: 'City',
                hint: 'Enter city',
                prefixIcon: Icons.location_city_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField.phone(
                controller: _phoneController,
                label: 'Phone',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const SizedBox(height: 20),

        // Bank Details Section
        ExpansionTile(
          title: Text(
            'Bank Details (Optional)',
            style: AppTextStyles.titleMedium,
          ),
          subtitle: const Text('For fee deposits and online payments'),
          childrenPadding: const EdgeInsets.all(16),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.divider),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.divider),
          ),
          children: [
            AppTextField(
              controller: _bankNameController,
              label: 'Bank Name',
              hint: 'e.g. Meezan Bank',
              prefixIcon: LucideIcons.landmark,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _accountTitleController,
                    label: 'Account Title',
                    prefixIcon: LucideIcons.user,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _accountNumberController,
                    label: 'Account Number / IBAN',
                    prefixIcon: LucideIcons.creditCard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _onlinePaymentInfoController,
              label: 'Online Payment Instructions',
              hint: 'e.g. JazzCash/EasyPaisa number or UPI ID',
              prefixIcon: LucideIcons.smartphone,
              maxLines: 2,
            ),
          ],
        ),

        const SizedBox(height: 32),

        AppButton.primary(
          text: 'Continue',
          isExpanded: true,
          size: AppButtonSize.large,
          trailingIcon: Icons.arrow_forward,
          onPressed: _nextStep,
        ),
      ],
    );
  }

  Widget _buildAdminAccountStep() {
    return Column(
      key: const ValueKey('admin-account'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create Admin Account', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Set up the administrator account for your school',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),

        AppTextField(
          controller: _adminNameController,
          label: 'Full Name *',
          hint: 'Enter admin full name',
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Full name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        AppTextField(
          controller: _adminEmailController,
          label: 'Email *',
          hint: 'Enter admin email address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        AppTextField(
          controller: _adminUsernameController,
          label: 'Username *',
          hint: 'Enter username for login',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Username is required';
            }
            if (value.length < 3) {
              return 'Username must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        AppTextField(
          controller: _adminPasswordController,
          label: 'Password *',
          hint: 'Enter password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixTap: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        AppTextField(
          controller: _adminConfirmPasswordController,
          label: 'Confirm Password *',
          hint: 'Re-enter password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: _obscureConfirmPassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixTap: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _adminPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                text: 'Back',
                icon: Icons.arrow_back,
                size: AppButtonSize.large,
                onPressed: _previousStep,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: AppButton.primary(
                text: 'Complete Setup',
                isLoading: _isLoading,
                size: AppButtonSize.large,
                onPressed: _completeSetup,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
